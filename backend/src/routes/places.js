const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

// GET /api/v1/places
router.get('/', async (req, res, next) => {
  try {
    const { category, query: searchQuery, limit = 50, offset = 0 } = req.query;

    let sql = "SELECT * FROM places WHERE is_verified = 1";
    const params = [];

    if (category && category !== 'All') {
      sql += " AND UPPER(category) = UPPER(?)";
      params.push(category);
    }

    if (searchQuery) {
      sql += " AND (name LIKE ? OR description LIKE ? OR address LIKE ?)";
      const term = `%${searchQuery}%`;
      params.push(term, term, term);
    }

    sql += " ORDER BY name ASC LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const places = await db.query(sql, params);

    res.json({
      success: true,
      data: places,
      meta: {
        count: places.length,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/places/:id
router.get('/:id', async (req, res, next) => {
  try {
    const place = await db.get("SELECT * FROM places WHERE id = ?", [req.params.id]);
    if (!place) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Place not found' }
      });
    }
    res.json({ success: true, data: place });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/places (Admin / Volunteer only)
router.post('/', authenticateToken, requireRole(['DISASTER_ADMIN', 'VOLUNTEER']), async (req, res, next) => {
  try {
    const { name, category, description, latitude, longitude, address, opening_hours, image_url, crowd_level } = req.body;
    if (!name || !category || latitude == null || longitude == null) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Name, category, latitude, and longitude are required' }
      });
    }

    const result = await db.run(
      `INSERT INTO places (name, category, description, latitude, longitude, address, opening_hours, image_url, crowd_level, is_verified, version)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 1)`,
      [name, category, description || '', latitude, longitude, address || '', opening_hours || '24 Hours', image_url || '', crowd_level || 'LOW']
    );

    const created = await db.get("SELECT * FROM places WHERE id = ?", [result.id]);

    // Log change for delta sync
    await db.logChange('place', created.id, 'CREATED', created);

    res.status(201).json({ success: true, data: created });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/places/:id (Update crowd_level, details)
router.patch('/:id', authenticateToken, requireRole(['DISASTER_ADMIN', 'VOLUNTEER', 'POLICE']), async (req, res, next) => {
  try {
    const existing = await db.get("SELECT * FROM places WHERE id = ?", [req.params.id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Place not found' }
      });
    }

    const { crowd_level, description, opening_hours } = req.body;
    const newVersion = (existing.version || 1) + 1;

    await db.run(
      `UPDATE places 
       SET crowd_level = ?, description = ?, opening_hours = ?, version = ?, updated_at = CURRENT_TIMESTAMP 
       WHERE id = ?`,
      [
        crowd_level || existing.crowd_level,
        description || existing.description,
        opening_hours || existing.opening_hours,
        newVersion,
        req.params.id
      ]
    );

    const updated = await db.get("SELECT * FROM places WHERE id = ?", [req.params.id]);

    // Log change for delta sync
    await db.logChange('place', updated.id, 'UPDATED', updated);

    res.json({ success: true, data: updated });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/places/:id (Soft-delete & Delta Log)
router.delete('/:id', authenticateToken, requireRole(['DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const existing = await db.get("SELECT * FROM places WHERE id = ?", [req.params.id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Place not found' }
      });
    }

    await db.run("UPDATE places SET is_verified = 0, version = version + 1 WHERE id = ?", [req.params.id]);

    // Log deletion event
    await db.logChange('place', parseInt(req.params.id), 'DELETED', { id: parseInt(req.params.id) });

    res.json({
      success: true,
      message: `Place #${req.params.id} marked inactive.`
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
