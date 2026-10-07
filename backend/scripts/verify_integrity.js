const IntegrityCheckerService = require('../src/services/integrityChecker');

async function runIntegrityAudit() {
  console.log('====================================================');
  console.log('🛡️ NASHIK KUMBH MELA — SOURCE CODE INTEGRITY AUDIT');
  console.log('====================================================');

  const arg = process.argv[2];
  if (arg === '--generate-manifest') {
    IntegrityCheckerService.generateBaselineManifest();
    console.log('✓ Baseline integrity checksums updated.');
    process.exit(0);
  }

  const result = await IntegrityCheckerService.verifySourceIntegrity();
  if (result.status === 'INTACT') {
    console.log('✅ ALL CRITICAL SOURCE FILES INTACT. SHA-256 Checksums Verified.');
    process.exit(0);
  } else if (result.status === 'BASELINE_GENERATED') {
    console.log('ℹ️ Integrity manifest baseline generated for current codebase.');
    process.exit(0);
  } else {
    console.error('💥 TAMPERING DETECTED!');
    console.error(`Incident ID: ${result.incidentId}`);
    console.error(`Security State: ${result.securityState}`);
    console.error('Tampered Files:', result.tamperedFiles);
    console.error('🔒 SYSTEM ENTERED LOCKDOWN. PRESERVING ALL SOURCE CODE & EVIDENCE.');
    process.exit(1);
  }
}

runIntegrityAudit();
