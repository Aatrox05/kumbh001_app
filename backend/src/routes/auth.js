const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { authenticateToken, JWT_SECRET } = require('../middleware/auth');

// POST /api/v1/auth/register
router.post('/register', async (req, res, next) => {
  try {
    const { username, password, name, phone, role } = req.body;
    if (!username || !password || !name) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Username, password, and name are required' }
      });
    }

    const existing = await db.get("SELECT id FROM users WHERE username = ?", [username]);
    if (existing) {
      return res.status(409).json({
        success: false,
        error: { code: 'CONFLICT', message: 'Username already exists' }
      });
    }

    const assignedRole = (role && ['DISASTER_ADMIN', 'POLICE', 'MEDICAL', 'FIRE', 'VOLUNTEER'].includes(role)) ? role : 'PUBLIC';
    const passwordHash = await bcrypt.hash(password, 10);

    const result = await db.run(
      "INSERT INTO users (username, password_hash, role, name, phone) VALUES (?, ?, ?, ?, ?)",
      [username, passwordHash, assignedRole, name, phone || null]
    );

    const user = { id: result.id, username, role: assignedRole, name };
    const token = jwt.sign(user, JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      success: true,
      data: {
        token,
        user
      }
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Username and password required' }
      });
    }

    const user = await db.get("SELECT * FROM users WHERE username = ?", [username]);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Invalid username or password' }
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Invalid username or password' }
      });
    }

    const userData = { id: user.id, username: user.username, role: user.role, name: user.name, phone: user.phone };
    const token = jwt.sign(userData, JWT_SECRET, { expiresIn: '7d' });

    res.json({
      success: true,
      data: {
        token,
        user: userData
      }
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/auth/me
router.get('/me', authenticateToken, (req, res) => {
  res.json({
    success: true,
    data: { user: req.user }
  });
});

module.exports = router;
