const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireRole } = require('../middleware/auth');
const rateLimiter = require('../middleware/rateLimiter');

// Rate limit SOS creation: max 5 requests per 2 minutes per IP
const sosRateLimiter = rateLimiter({ windowMs: 2 * 60 * 1000, max: 5 });

// POST /api/v1/sos (Create SOS Emergency Alert)
router.post('/', sosRateLimiter, async (req, res, next) => {
  try {
    const { device_id, contact_name, contact_phone, latitude, longitude, location_address, emergency_type = 'GENERAL', remarks, idempotency_key } = req.body;
    const headerKey = req.headers['x-idempotency-key'];
    const activeKey = idempotency_key || headerKey;

    if (!device_id || !contact_phone) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'device_id and contact_phone are required' }
      });
    }

    // Idempotency Deduplication Check
    if (activeKey) {
      const existingSos = await db.get("SELECT * FROM sos_requests WHERE idempotency_key = ?", [activeKey]);
      if (existingSos) {
        return res.status(200).json({
          success: true,
          deduplicated: true,
          data: {
            sos: existingSos,
            message: 'Duplicate SOS request intercepted safely. Emergency incident already registered.'
          }
        });
      }
    }

    const userId = req.user ? req.user.id : null;
    const initialStatus = 'RECEIVED';

    const result = await db.run(
      `INSERT INTO sos_requests (idempotency_key, user_id, device_id, contact_name, contact_phone, latitude, longitude, location_address, status, emergency_type, remarks)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [activeKey || null, userId, device_id, contact_name || 'Anonymous User', contact_phone, latitude || null, longitude || null, location_address || null, initialStatus, emergency_type, remarks || '']
    );

    const sos = await db.get("SELECT * FROM sos_requests WHERE id = ?", [result.id]);

    await db.run(
      "INSERT INTO audit_logs (user_id, action, resource, details, ip_address) VALUES (?, ?, ?, ?, ?)",
      [userId, 'CREATE_SOS', `sos_requests:${result.id}`, `Emergency SOS triggered (${emergency_type})`, req.ip]
    );

    res.status(201).json({
      success: true,
      data: {
        sos,
        message: 'SOS received by Nashik Central Command. Response team notified.'
      }
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/sos/:id (Get SOS status)
router.get('/:id', async (req, res, next) => {
  try {
    const sos = await db.get("SELECT * FROM sos_requests WHERE id = ?", [req.params.id]);
    if (!sos) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'SOS request not found' }
      });
    }

    res.json({
      success: true,
      data: sos
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/sos (Authority list active SOS alerts)
router.get('/', authenticateToken, requireRole(['POLICE', 'MEDICAL', 'FIRE', 'DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const { status, emergency_type, limit = 50, offset = 0 } = req.query;
    let sql = "SELECT s.*, u.name as responder_name FROM sos_requests s LEFT JOIN users u ON s.assigned_to_user_id = u.id WHERE 1=1";
    const params = [];

    if (status) {
      sql += " AND s.status = ?";
      params.push(status);
    }
    if (emergency_type) {
      sql += " AND s.emergency_type = ?";
      params.push(emergency_type);
    }

    sql += " ORDER BY s.created_at DESC LIMIT ? OFFSET ?";
    params.push(parseInt(limit), parseInt(offset));

    const sosList = await db.query(sql, params);
    res.json({
      success: true,
      data: sosList
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/sos/:id/status (Authority updates status: ACKNOWLEDGED, DISPATCHED, RESOLVED)
router.patch('/:id/status', authenticateToken, requireRole(['POLICE', 'MEDICAL', 'FIRE', 'DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const { status, remarks } = req.body;
    const validStatuses = ['ACKNOWLEDGED', 'DISPATCHED', 'RESOLVED'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: `Invalid status. Must be one of: ${validStatuses.join(', ')}` }
      });
    }

    const existing = await db.get("SELECT * FROM sos_requests WHERE id = ?", [req.params.id]);
    if (!existing) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'SOS request not found' }
      });
    }

    await db.run(
      `UPDATE sos_requests 
       SET status = ?, remarks = ?, assigned_to_user_id = ?, updated_at = CURRENT_TIMESTAMP 
       WHERE id = ?`,
      [status, remarks || existing.remarks, req.user.id, req.params.id]
    );

    const updated = await db.get("SELECT * FROM sos_requests WHERE id = ?", [req.params.id]);

    // Audit log
    await db.run(
      "INSERT INTO audit_logs (user_id, action, resource, details, ip_address) VALUES (?, ?, ?, ?, ?)",
      [req.user.id, 'UPDATE_SOS_STATUS', `sos_requests:${req.params.id}`, `Updated status from ${existing.status} to ${status}`, req.ip]
    );

    res.json({
      success: true,
      data: updated
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
