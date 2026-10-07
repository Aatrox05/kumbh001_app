const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// GET /api/v1/lost-found
router.get('/', async (req, res, next) => {
  try {
    const { type, query: searchQuery, limit = 50, offset = 0 } = req.query;
    let sql = "SELECT * FROM lost_found_reports WHERE 1=1";
    const params = [];

    if (type) {
      sql += " AND UPPER(report_type) = UPPER(?)";
      params.push(type);
    }

    if (searchQuery) {
      sql += " AND (person_or_item_name LIKE ? OR description LIKE ? OR last_seen_location LIKE ?)";
      const term = `%${searchQuery}%`;
      params.push(term, term, term);
    }

    sql += " ORDER BY created_at DESC LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const reports = await db.query(sql, params);

    res.json({
      success: true,
      data: reports,
      meta: {
        count: reports.length,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/lost-found
router.post('/', async (req, res, next) => {
  try {
    const { report_type, person_or_item_name, description, age, gender, last_seen_location, contact_phone, image_url } = req.body;

    if (!report_type || !person_or_item_name || !contact_phone) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'report_type, person_or_item_name, and contact_phone are required' }
      });
    }

    const userId = req.user ? req.user.id : null;

    const result = await db.run(
      `INSERT INTO lost_found_reports (user_id, report_type, person_or_item_name, description, age, gender, last_seen_location, contact_phone, image_url, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'REPORTED')`,
      [userId, report_type, person_or_item_name, description || '', age || null, gender || null, last_seen_location || '', contact_phone, image_url || '']
    );

    const created = await db.get("SELECT * FROM lost_found_reports WHERE id = ?", [result.id]);

    res.status(201).json({
      success: true,
      data: created
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
