const express = require('express');
const router = express.Router();
const { SecurityLockService } = require('../services/securityLockService');
const { authenticateToken, requireRole } = require('../middleware/auth');

// GET /api/v1/security/status (Lock status UI endpoint)
router.get('/status', async (req, res, next) => {
  try {
    const stateRecord = await SecurityLockService.getSecurityState();
    const activeIncidents = await SecurityLockService.getActiveIncidents();

    res.json({
      success: true,
      data: {
        securityState: stateRecord.current_state,
        lastUpdatedAt: stateRecord.last_updated_at,
        updatedBy: stateRecord.updated_by,
        lockReason: stateRecord.lock_reason,
        lastKnownGoodCommit: stateRecord.last_known_good_commit || 'HEAD',
        deploymentsLocked: stateRecord.current_state === 'LOCKDOWN',
        administrativeChangesLocked: ['LOCKDOWN', 'HIGH_RISK'].includes(stateRecord.current_state),
        publicSafetyInformationAvailable: true,
        activeIncidentsCount: activeIncidents.length,
        activeIncidents: activeIncidents.map(inc => ({
          incidentId: inc.incident_id,
          severity: inc.severity,
          source: inc.source,
          eventType: inc.event_type,
          actor: inc.actor,
          createdAt: inc.created_at,
          status: inc.status
        }))
      }
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/security/unlock (Explicit Administrator Unlock Workflow)
router.post('/unlock', authenticateToken, requireRole(['DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const { unlock_reason, incident_id } = req.body;
    
    if (!unlock_reason) {
      return res.status(400).json({
        success: false,
        error: { code: 'BAD_REQUEST', message: 'unlock_reason is required (minimum 10 characters)' }
      });
    }

    const result = await SecurityLockService.adminUnlockSystem({
      adminUser: req.user,
      unlockReason: unlock_reason,
      incidentId: incident_id || null
    });

    res.json({
      success: true,
      message: 'System security state successfully unlocked to NORMAL.',
      data: result
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/security/simulate-incident (Dev/Staging Test Trigger)
router.post('/simulate-incident', authenticateToken, requireRole(['DISASTER_ADMIN']), async (req, res, next) => {
  try {
    const { severity = 'CRITICAL', event_type = 'SIMULATED_TEST_TAMPERING', details = {} } = req.body;
    
    const incident = await SecurityLockService.logSecurityIncident({
      severity,
      source: 'MANUAL_TEST_TRIGGER',
      eventType: event_type,
      actor: req.user.username,
      resource: 'security_test',
      actionTaken: severity === 'CRITICAL' ? 'SYSTEM_LOCKED_DOWN' : 'INCIDENT_LOGGED',
      metadata: details
    });

    res.status(201).json({
      success: true,
      message: `Simulated security incident generated. System state is now ${incident.newState}.`,
      data: incident
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
