/**
 * Structured Production JSON Logger & Security Sanitizer
 * Captures operational trace logs without logging passwords, tokens, or PII.
 */
class Logger {
  static sanitize(obj) {
    if (!obj || typeof obj !== 'object') return obj;
    const clean = { ...obj };
    const sensitiveKeys = ['password', 'password_hash', 'token', 'jwt', 'secret', 'authorization', 'ip_address'];
    for (const key of Object.keys(clean)) {
      if (sensitiveKeys.includes(key.toLowerCase())) {
        clean[key] = '[REDACTED_FOR_SECURITY]';
      } else if (typeof clean[key] === 'object') {
        clean[key] = this.sanitize(clean[key]);
      }
    }
    return clean;
  }

  static info(message, meta = {}) {
    const payload = {
      timestamp: new Date().toISOString(),
      level: 'INFO',
      message,
      meta: this.sanitize(meta)
    };
    console.log(JSON.stringify(payload));
  }

  static warn(message, meta = {}) {
    const payload = {
      timestamp: new Date().toISOString(),
      level: 'WARN',
      message,
      meta: this.sanitize(meta)
    };
    console.warn(JSON.stringify(payload));
  }

  static error(message, meta = {}) {
    const payload = {
      timestamp: new Date().toISOString(),
      level: 'ERROR',
      message,
      meta: this.sanitize(meta)
    };
    console.error(JSON.stringify(payload));
  }
}

module.exports = Logger;
