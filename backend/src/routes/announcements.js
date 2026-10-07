const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');
const PushNotificationService = require('../services/pushNotificationService');

// GET /api/v1/announcements (Public active announcements feed)
router.get('/', async (req, res, next) => {
  try {
    const announcements = await db.query(
      `SELECT * FROM announcements 
       WHERE status = 'PUBLISHED' 
       AND (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP) 
       ORDER BY CASE priority WHEN 'CRITICAL' THEN 1 WHEN 'IMPORTANT' THEN 2 ELSE 3 END, published_at DESC`
    );

    res.json({
      success: true,
      data: announcements
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/announcements/:id
router.get('/:id', async (req, res, next) => {
  try {
    const announcement = await db.get("SELECT * FROM announcements WHERE id = ? AND status != 'DELETED'", [req.params.id]);
    if (!announcement) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Announcement not found' }
      });
    }
    res.json({ success: true, data: announcement });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/announcements (Authority / Admin Publish)
router.post('/', authenticateToken, requireRole(['DISASTER_ADMIN', 'POLICE', 'MEDICAL']), async (req, res, next) => {
  try {
    const { title, content, priority = 'NORMAL', category = 'GENERAL', target_group = 'ALL', expires_at, source_name } = req.body;
    if (!title || !content) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Title and content are required' }
      });
    }

    const result = await db.run(
      `INSERT INTO announcements (title, content, priority, category, target_group, expires_at, created_by, source_name, status, version)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PUBLISHED', 1)`,
      [title, content, priority, category, target_group, expires_at || null, req.user.id, source_name || 'Kumbh Disaster Control Command']
    );

    const created = await db.get("SELECT * FROM announcements WHERE id = ?", [result.id]);

    // 1. Log change for client delta sync
    await db.logChange('announcement', created.id, 'CREATED', created);

    // 2. Dispatch Push Notification for Critical/Important Alerts AFTER DB persistence
    if (priority === 'CRITICAL' || priority === 'IMPORTANT') {
      await PushNotificationService.sendCriticalAlert(created);
    }

    res.status(201).json({ success: true, data: created });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/announcements/:id (Optimistic concurrency versioning)
router.patch('/:id', authenticateToken, requireRole(['DISASTER_ADMIN', 'POLICE', 'MEDICAL']), async (req, res, next) => {
  try {
    const existing = await db.get("SELECT * FROM announcements WHERE id = ?", [req.params.id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Announcement not found' }
      });
    }

    // Optimistic Concurrency Control Check
    const expectedVersion = req.body.version;
    if (expectedVersion != null && expectedVersion !== existing.version) {
      return res.status(409).json({
        success: false,
        error: {
          code: 'CONFLICT',
          message: `Record has been updated by another admin (Current Version: ${existing.version}, Provided: ${expectedVersion}). Please refresh.`
        }
      });
    }

    const { title, content, priority, category, status } = req.body;
    const newVersion = (existing.version || 1) + 1;

    await db.run(
      `UPDATE announcements 
       SET title = ?, content = ?, priority = ?, category = ?, status = ?, version = ? 
       WHERE id = ?`,
      [
        title || existing.title,
        content || existing.content,
        priority || existing.priority,
        category || existing.category,
        status || existing.status,
        newVersion,
        req.params.id
      ]
    );

    const updated = await db.get("SELECT * FROM announcements WHERE id = ?", [req.params.id]);

    // Log change for delta sync
    await db.logChange('announcement', updated.id, 'UPDATED', updated);

    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/announcements/:id (Soft-delete & Delta Log)
router.delete('/:id', authenticateToken, requireRole(['DISASTER_ADMIN', 'POLICE', 'MEDICAL']), async (req, res, next) => {
  try {
    const existing = await db.get("SELECT * FROM announcements WHERE id = ?", [req.params.id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Announcement not found' }
      });
    }

    // Soft delete to preserve administrative audit history
    await db.run("UPDATE announcements SET status = 'DELETED', version = version + 1 WHERE id = ?", [req.params.id]);

    // Log deletion event for clients
    await db.logChange('announcement', parseInt(req.params.id), 'DELETED', { id: parseInt(req.params.id) });

    res.json({
      success: true,
      message: `Announcement #${req.params.id} soft deleted.`
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
