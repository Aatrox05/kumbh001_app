const { SecurityLockService, SECURITY_STATES } = require('../services/securityLockService');

/**
 * Security Guard Middleware:
 * Inspects system security state.
 * In LOCKDOWN / HIGH_RISK:
 *  - Public safety GET requests are ALWAYS ALLOWED.
 *  - Authentication & Unlock endpoints are ALLOWED for admin re-auth.
 *  - Administrative mutation operations (POST/PATCH/DELETE) are LOCKED with HTTP 423.
 *  - ABSOLUTE RULE: NEVER WIPES OR DELETES DATA. LOCKS & PRESERVES INTENSITY ONLY.
 */
async function enforceSecurityGuard(req, res, next) {
  try {
    const stateRecord = await SecurityLockService.getSecurityState();
    const currentState = stateRecord.current_state;

    // Attach security state to request object
    req.securityState = currentState;

    // 1. Always allow read-only GET requests (public safety, announcements, sync, health)
    if (req.method === 'GET') {
      return next();
    }

    // 2. Always allow Auth login/register & Security Unlock endpoints for admin incident resolution
    const path = req.path || req.originalUrl;
    if (path.includes('/auth/login') || path.includes('/auth/register') || path.includes('/security/unlock')) {
      return next();
    }

    // 3. Enforce lockdown for mutation endpoints if state is LOCKDOWN or HIGH_RISK
    if (currentState === SECURITY_STATES.LOCKDOWN || currentState === SECURITY_STATES.HIGH_RISK) {
      // Log mutation attempt during lockdown
      await SecurityLockService.logSecurityIncident({
        severity: 'HIGH_RISK',
        source: 'API_GUARD',
        eventType: 'MUTATION_BLOCKED_DURING_LOCKDOWN',
        actor: req.user ? req.user.username : 'UNAUTHENTICATED',
        resource: `${req.method} ${req.path}`,
        actionTaken: 'REQUEST_BLOCKED_HTTP_423',
        metadata: { path: req.path, method: req.method, ip: req.ip }
      });

      return res.status(423).json({
        success: false,
        error: {
          code: 'DEPLOYMENT_OR_ADMIN_LOCKED',
          message: `System is currently in ${currentState} mode due to a security incident. Administrative mutation operations are locked.`,
          securityState: currentState,
          lockReason: stateRecord.lock_reason,
          publicSafetyInfoAvailable: true,
          actionRequired: 'Authorized administrator review and explicit unlock required.'
        }
      });
    }

    next();
  } catch (err) {
    // Fail safe: on guard error, allow request to proceed to downstream middleware or log error
    next(err);
  }
}

module.exports = {
  enforceSecurityGuard
};
