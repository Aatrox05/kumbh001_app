const db = require('../config/database');
const Logger = require('../utils/logger');

const SECURITY_STATES = {
  NORMAL: 'NORMAL',
  SUSPICIOUS: 'SUSPICIOUS',
  HIGH_RISK: 'HIGH_RISK',
  LOCKDOWN: 'LOCKDOWN'
};

class SecurityLockService {
  /**
   * Get current security state from database or default to NORMAL
   */
  static async getSecurityState() {
    try {
      const record = await db.get("SELECT * FROM security_state WHERE id = 1");
      if (!record) {
        await db.run(
          "INSERT OR IGNORE INTO security_state (id, current_state, updated_by, lock_reason) VALUES (1, 'NORMAL', 'SYSTEM', 'Initial state')",
          []
        );
        return {
          current_state: SECURITY_STATES.NORMAL,
          updated_by: 'SYSTEM',
          lock_reason: 'Initial state',
          last_known_good_commit: 'HEAD'
        };
      }
      return record;
    } catch (err) {
      Logger.error('Failed to read security state from DB:', { error: err.message });
      return { current_state: SECURITY_STATES.NORMAL };
    }
  }

  /**
   * Create an immutable incident record and evaluate state escalation.
   * ABSOLUTE RULE: NEVER DELETES OR WIPES DATA. LOCKS AND PRESERVES ONLY.
   */
  static async logSecurityIncident({
    severity = 'SUSPICIOUS',
    source = 'API',
    eventType,
    actor = 'UNKNOWN',
    resource = null,
    commitSha = 'HEAD',
    workflowId = null,
    actionTaken = 'LOGGED',
    metadata = {}
  }) {
    const timestampYear = new Date().getFullYear();
    const randomSeq = String(Math.floor(100000 + Math.random() * 900000));
    const incidentId = `INC-${timestampYear}-${randomSeq}`;

    const metadataStr = typeof metadata === 'string' ? metadata : JSON.stringify(metadata);

    // Determine target security state based on severity
    let targetState = SECURITY_STATES.NORMAL;
    if (severity === 'SUSPICIOUS') targetState = SECURITY_STATES.SUSPICIOUS;
    if (severity === 'HIGH_RISK') targetState = SECURITY_STATES.HIGH_RISK;
    if (severity === 'CRITICAL' || severity === 'LOCKDOWN') targetState = SECURITY_STATES.LOCKDOWN;

    const currentStateRecord = await this.getSecurityState();
    const currentState = currentStateRecord.current_state;

    // Escalate state if target state is higher severity than current state
    const statePriority = { NORMAL: 0, SUSPICIOUS: 1, HIGH_RISK: 2, LOCKDOWN: 3 };
    let newState = currentState;
    if (statePriority[targetState] > statePriority[currentState]) {
      newState = targetState;
      await this.setSecurityState(newState, `Escalated by ${incidentId}: ${eventType}`, `INCIDENT_${severity}`);
    }

    // Persist Incident Record
    await db.run(
      `INSERT INTO security_incidents 
       (incident_id, severity, source, event_type, actor, resource, commit_sha, workflow_id, security_state, status, action_taken, metadata)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'OPEN', ?, ?)`,
      [incidentId, severity, source, eventType, actor, resource, commitSha, workflowId, newState, actionTaken, metadataStr]
    );

    Logger.warn(`🚨 SECURITY INCIDENT GENERATED [${incidentId}] - State: ${newState}`, {
      incidentId,
      severity,
      eventType,
      actor,
      actionTaken
    });

    return {
      incidentId,
      newState,
      severity,
      eventType,
      actionTaken
    };
  }

  /**
   * Transition centralized security state
   */
  static async setSecurityState(newState, reason, updatedBy = 'SYSTEM') {
    if (!Object.values(SECURITY_STATES).includes(newState)) {
      throw new Error(`Invalid security state: ${newState}`);
    }

    await db.run(
      `INSERT INTO security_state (id, current_state, last_updated_at, updated_by, lock_reason)
       VALUES (1, ?, CURRENT_TIMESTAMP, ?, ?)
       ON CONFLICT(id) DO UPDATE SET
       current_state = excluded.current_state,
       last_updated_at = CURRENT_TIMESTAMP,
       updated_by = excluded.updated_by,
       lock_reason = excluded.lock_reason`,
      [newState, updatedBy, reason]
    );

    Logger.warn(`🔒 SECURITY STATE CHANGED -> ${newState}`, { newState, reason, updatedBy });
  }

  /**
   * Explicit Administrator Unlock Workflow
   * Requires human admin verification, reason, and incident resolution.
   */
  static async adminUnlockSystem({ adminUser, unlockReason, incidentId = null }) {
    if (!adminUser || !['DISASTER_ADMIN'].includes(adminUser.role)) {
      throw new Error('Unauthorized: Only DISASTER_ADMIN can perform system security unlock');
    }

    if (!unlockReason || unlockReason.trim().length < 10) {
      throw new Error('Unlock reason must be provided (minimum 10 characters)');
    }

    const previousStateRecord = await this.getSecurityState();
    await this.setSecurityState(SECURITY_STATES.NORMAL, `Admin Unlock: ${unlockReason}`, adminUser.username);

    if (incidentId) {
      await db.run(
        `UPDATE security_incidents 
         SET status = 'RESOLVED', resolved_at = CURRENT_TIMESTAMP, resolved_by = ?
         WHERE incident_id = ?`,
        [adminUser.username, incidentId]
      );
    }

    await db.run(
      "INSERT INTO audit_logs (user_id, action, resource, details, ip_address) VALUES (?, ?, ?, ?, ?)",
      [adminUser.id, 'SECURITY_UNLOCK', 'security_state', `System unlocked from ${previousStateRecord.current_state} to NORMAL. Reason: ${unlockReason}`, 'ADMIN']
    );

    Logger.info(`🔓 SYSTEM UNLOCKED BY ADMINISTRATOR: ${adminUser.username}`, {
      unlockedBy: adminUser.username,
      previousState: previousStateRecord.current_state,
      reason: unlockReason
    });

    return {
      success: true,
      previousState: previousStateRecord.current_state,
      currentState: SECURITY_STATES.NORMAL,
      unlockedBy: adminUser.username
    };
  }

  /**
   * Get open active incidents
   */
  static async getActiveIncidents() {
    return await db.query("SELECT * FROM security_incidents WHERE status = 'OPEN' ORDER BY created_at DESC");
  }
}

module.exports = {
  SecurityLockService,
  SECURITY_STATES
};
