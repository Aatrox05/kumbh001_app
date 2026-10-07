const express = require('express');
const router = express.Router();
const db = require('../config/database');

// GET /api/v1/emergency/facilities
router.get('/facilities', async (req, res, next) => {
  try {
    const { type } = req.query;
    let sql = "SELECT * FROM emergency_facilities WHERE is_verified = 1";
    const params = [];

    if (type) {
      sql += " AND UPPER(type) = UPPER(?)";
      params.push(type);
    }

    sql += " ORDER BY name ASC";
    const facilities = await db.query(sql, params);

    res.json({
      success: true,
      data: facilities
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
