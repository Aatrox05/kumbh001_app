const rateLimitMap = new Map();

const rateLimiter = (options = { windowMs: 60 * 1000, max: 60 }) => {
  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress || 'unknown';
    const now = Date.now();

    if (!rateLimitMap.has(ip)) {
      rateLimitMap.set(ip, []);
    }

    const timestamps = rateLimitMap.get(ip).filter(t => now - t < options.windowMs);
    timestamps.push(now);
    rateLimitMap.set(ip, timestamps);

    if (timestamps.length > options.max) {
      return res.status(429).json({
        success: false,
        error: {
          code: 'TOO_MANY_REQUESTS',
          message: 'Rate limit exceeded. Please try again later.'
        }
      });
    }

    next();
  };
};

module.exports = rateLimiter;
