const rates = new Map();

/**
 * Sliding window rate limiter for security critical endpoints (Auth, SOS).
 * Limits requests per IP window.
 */
function createRateLimiter(maxRequests = 100, windowMs = 15 * 60 * 1000) {
  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
    const now = Date.now();
    
    if (!rates.has(ip)) {
      rates.set(ip, []);
    }
    
    const timestamps = rates.get(ip).filter(ts => now - ts < windowMs);
    timestamps.push(now);
    rates.set(ip, timestamps);
    
    if (timestamps.length > maxRequests) {
      return res.status(429).json({
        success: false,
        error: {
          code: 'TOO_MANY_REQUESTS',
          message: `Too many requests from this IP. Rate limit exceeded (${maxRequests} requests per ${windowMs / 60000} mins). Please try again later.`
        }
      });
    }
    next();
  };
}

module.exports = {
  authLimiter: createRateLimiter(30, 15 * 60 * 1000), // 30 logins/registrations per 15 mins
  sosLimiter: createRateLimiter(10, 1 * 60 * 1000),   // 10 SOS requests per min
  generalLimiter: createRateLimiter(500, 15 * 60 * 1000) // 500 requests per 15 mins
};
