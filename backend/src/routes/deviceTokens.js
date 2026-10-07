const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// POST /api/v1/device-tokens (Register / Refresh device FCM token)
router.post('/', async (req, res, next) => {
  try {
    const { token, platform = 'ANDROID', user_id } = req.body;
    if (!token) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Device token is required' }
      });
    }

    const existing = await db.get("SELECT id FROM device_tokens WHERE token = ?", [token]);
    if (existing) {
      await db.run(
        "UPDATE device_tokens SET user_id = ?, platform = ?, updated_at = CURRENT_TIMESTAMP WHERE token = ?",
        [user_id || null, platform, token]
      );
      return res.json({ success: true, message: 'Device token updated', tokenId: existing.id });
    }

    const result = await db.run(
      "INSERT INTO device_tokens (token, platform, user_id) VALUES (?, ?, ?)",
      [token, platform, user_id || null]
    );

    res.status(201).json({
      success: true,
      message: 'Device token registered successfully',
      tokenId: result.id
    });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/device-tokens/:token (Unregister on logout / uninstall)
router.delete('/:token', async (req, res, next) => {
  try {
    const token = req.params.token;
    await db.run("DELETE FROM device_tokens WHERE token = ?", [token]);
    res.json({ success: true, message: 'Device token removed successfully' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
