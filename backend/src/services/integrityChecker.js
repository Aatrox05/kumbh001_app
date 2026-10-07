const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { SecurityLockService } = require('./securityLockService');
const Logger = require('../utils/logger');

const CRITICAL_FILES = [
  'src/app.js',
  'src/middleware/auth.js',
  'src/middleware/securityGuard.js',
  'src/routes/sos.js',
  'src/routes/announcements.js',
  'src/routes/sync.js',
  'src/routes/security.js',
  'src/config/database.js',
  'src/services/securityLockService.js',
  'src/services/webIngester.js'
];

const MANIFEST_PATH = path.join(__dirname, '../config/integrity_manifest.json');

class IntegrityCheckerService {
  /**
   * Compute SHA-256 hash of a file
   */
  static getFileHash(relativePath) {
    const fullPath = path.join(__dirname, '../../', relativePath);
    if (!fs.existsSync(fullPath)) return null;
    const content = fs.readFileSync(fullPath);
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  /**
   * Generate initial integrity baseline manifest
   */
  static generateBaselineManifest() {
    const manifest = {
      generatedAt: new Date().toISOString(),
      files: {}
    };

    for (const relPath of CRITICAL_FILES) {
      const hash = this.getFileHash(relPath);
      if (hash) {
        manifest.files[relPath] = hash;
      }
    }

    const dir = path.dirname(MANIFEST_PATH);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2));
    Logger.info(`✓ Integrity baseline manifest generated (${Object.keys(manifest.files).length} files hashed).`);
    return manifest;
  }

  /**
   * Audit current critical source files against baseline manifest.
   * ABSOLUTE RULE: NEVER WIPES OR OVERWRITES SOURCE CODE. PRESERVES ALL EVIDENCE.
   */
  static async verifySourceIntegrity() {
    if (!fs.existsSync(MANIFEST_PATH)) {
      this.generateBaselineManifest();
      return { status: 'BASELINE_GENERATED', tamperedFiles: [] };
    }

    const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf-8'));
    const tamperedFiles = [];
    const missingFiles = [];

    for (const [relPath, expectedHash] of Object.entries(manifest.files)) {
      const currentHash = this.getFileHash(relPath);
      if (!currentHash) {
        missingFiles.push(relPath);
      } else if (currentHash !== expectedHash) {
        tamperedFiles.push({ file: relPath, expected: expectedHash, current: currentHash });
      }
    }

    if (tamperedFiles.length > 0 || missingFiles.length > 0) {
      Logger.error(`💥 CRITICAL TAMPER DETECTED: Source code integrity violation!`, {
        tamperedFiles,
        missingFiles
      });

      // Escalate system security state to LOCKDOWN safely without wiping files
      const incident = await SecurityLockService.logSecurityIncident({
        severity: 'CRITICAL',
        source: 'INTEGRITY_CHECKER',
        eventType: 'SOURCE_CODE_TAMPERING_DETECTED',
        actor: 'INTEGRITY_MONITOR',
        resource: tamperedFiles.map(t => t.file).join(', '),
        actionTaken: 'SYSTEM_LOCKED_DOWN_SOURCE_PRESERVED',
        metadata: { tamperedFiles, missingFiles }
      });

      return {
        status: 'TAMPER_DETECTED',
        incidentId: incident.incidentId,
        securityState: incident.newState,
        tamperedFiles,
        missingFiles
      };
    }

    return { status: 'INTACT', tamperedFiles: [] };
  }
}

module.exports = IntegrityCheckerService;
