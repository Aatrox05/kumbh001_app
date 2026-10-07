const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

// GET /api/v1/events
router.get('/', async (req, res, next) => {
  try {
    const { category, limit = 50, offset = 0 } = req.query;

    let sql = "SELECT * FROM events WHERE is_verified = 1";
    const params = [];

    if (category && category !== 'All') {
      sql += " AND UPPER(category) = UPPER(?)";
      params.push(category);
    }

    sql += " ORDER BY start_time ASC LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const events = await db.query(sql, params);

    res.json({
      success: true,
      data: events,
      meta: {
        count: events.length,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/events/:id
router.get('/:id', async (req, res, next) => {
  try {
    const event = await db.get("SELECT * FROM events WHERE id = ?", [req.params.id]);
    if (!event) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Event not found' }
      });
    }
    res.json({ success: true, data: event });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/events (Admin only)
router.post('/', authenticateToken, requireRole(['DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const { title, category, description, start_time, end_time, location_name, latitude, longitude, organizer } = req.body;
    if (!title || !category || !start_time || !end_time || !location_name) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Title, category, start_time, end_time, and location_name required' }
      });
    }

    const result = await db.run(
      `INSERT INTO events (title, category, description, start_time, end_time, location_name, latitude, longitude, organizer, is_verified, version)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1)`,
      [title, category, description || '', start_time, end_time, location_name, latitude || null, longitude || null, organizer || 'Kumbh Mela Authority']
    );

    const created = await db.get("SELECT * FROM events WHERE id = ?", [result.id]);

    // Log change for delta sync
    await db.logChange('event', created.id, 'CREATED', created);

    res.status(201).json({ success: true, data: created });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/events/:id (Soft-delete & Delta Log)
router.delete('/:id', authenticateToken, requireRole(['DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const existing = await db.get("SELECT * FROM events WHERE id = ?", [req.params.id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Event not found' }
      });
    }

    await db.run("UPDATE events SET is_verified = 0, version = version + 1 WHERE id = ?", [req.params.id]);

    // Log deletion change event
    await db.logChange('event', parseInt(req.params.id), 'DELETED', { id: parseInt(req.params.id) });

    res.json({
      success: true,
      message: `Event #${req.params.id} marked inactive.`
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
