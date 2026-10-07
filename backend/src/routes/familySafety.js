const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// GET /api/v1/family-safety
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const records = await db.query(
      "SELECT * FROM family_safety_records WHERE primary_user_id = ? ORDER BY member_name ASC",
      [req.user.id]
    );

    res.json({
      success: true,
      data: records
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/family-safety
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const { member_name, member_phone, last_known_lat, last_known_lng } = req.body;

    if (!member_name || !member_phone) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'member_name and member_phone required' }
      });
    }

    const result = await db.run(
      `INSERT INTO family_safety_records (primary_user_id, member_name, member_phone, last_known_lat, last_known_lng)
       VALUES (?, ?, ?, ?, ?)`,
      [req.user.id, member_name, member_phone, last_known_lat || null, last_known_lng || null]
    );

    const created = await db.get("SELECT * FROM family_safety_records WHERE id = ?", [result.id]);

    res.status(201).json({
      success: true,
      data: created
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
