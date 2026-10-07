const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');

// GET /api/v1/parking (List parking facilities with static capacity vs live status)
router.get('/', async (req, res, next) => {
  try {
    const facilities = await db.query("SELECT * FROM parking_facilities ORDER BY name ASC");
    res.json({
      success: true,
      data: facilities.map(f => ({
        ...f,
        // Crucial Production Safeguard: Never fabricate live numbers.
        // If live availability sensor data is absent, status is explicitly LIVE_UNAVAILABLE.
        live_available_spaces: f.availability_status === 'LIVE_UNAVAILABLE' ? null : f.live_available_spaces,
        availability_status_text: f.availability_status === 'LIVE_UNAVAILABLE' 
          ? 'Live availability unavailable' 
          : `${f.live_available_spaces} spaces available`
      }))
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/parking/:id
router.get('/:id', async (req, res, next) => {
  try {
    const facility = await db.get("SELECT * FROM parking_facilities WHERE id = ?", [req.params.id]);
    if (!facility) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Parking facility not found' }
      });
    }
    res.json({
      success: true,
      data: {
        ...facility,
        live_available_spaces: facility.availability_status === 'LIVE_UNAVAILABLE' ? null : facility.live_available_spaces,
        availability_status_text: facility.availability_status === 'LIVE_UNAVAILABLE' 
          ? 'Live availability unavailable' 
          : `${facility.live_available_spaces} spaces available`
      }
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/parking (Authority add parking location)
router.post('/', authenticateToken, requireRole(['DISASTER_ADMIN', 'POLICE']), async (req, res, next) => {
  try {
    const { name, location_name, latitude, longitude, total_capacity, vehicle_type, operating_hours, source_name } = req.body;
    if (!name || !latitude || !longitude || !total_capacity) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Name, latitude, longitude, and total_capacity are required' }
      });
    }

    const result = await db.run(
      `INSERT INTO parking_facilities (name, location_name, latitude, longitude, total_capacity, availability_status, vehicle_type, operating_hours, source_name)
       VALUES (?, ?, ?, ?, ?, 'LIVE_UNAVAILABLE', ?, ?, ?)`,
      [name, location_name || name, latitude, longitude, total_capacity, vehicle_type || 'ALL', operating_hours || '24/7', source_name || 'Nashik Municipal Corporation']
    );

    const created = await db.get("SELECT * FROM parking_facilities WHERE id = ?", [result.id]);
    await db.logChange('parking', created.id, 'CREATED', created);

    res.status(201).json({ success: true, data: created });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
