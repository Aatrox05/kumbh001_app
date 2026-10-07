const express = require('express');
const router = express.Router();
const aiService = require('../services/aiService');
const rateLimit = require('express-rate-limit');
const { authenticateToken } = require('../middleware/auth');

// Rate limiting for AI endpoints to prevent abuse
const aiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // limit each IP to 20 AI requests per windowMs
  message: {
    success: false,
    error: { code: 'RATE_LIMIT_EXCEEDED', message: 'Too many AI requests from this IP, please try again later.' }
  }
});

// Apply rate limiter to all AI routes
router.use(aiRateLimiter);

// POST /api/v1/ai/query
// General assistant endpoint
router.post('/query', async (req, res, next) => {
  try {
    const { prompt } = req.body;
    if (!prompt || typeof prompt !== 'string') {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Prompt string is required' }
      });
    }

    const aiResponse = await aiService.ask(prompt);
    res.json(aiResponse);
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/ai/plan
// Plan My Visit endpoint
router.post('/plan', async (req, res, next) => {
  try {
    const details = req.body;
    if (!details || typeof details !== 'object') {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Trip details object is required' }
      });
    }

    const aiResponse = await aiService.planTrip(details);
    res.json(aiResponse);
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/ai/sos
// Emergency SOS Assistant endpoint
router.post('/sos', async (req, res, next) => {
  try {
    const { prompt } = req.body;
    if (!prompt || typeof prompt !== 'string') {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'Prompt string is required' }
      });
    }

    const aiResponse = await aiService.answerEmergencyQuestion(prompt);
    res.json(aiResponse);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
