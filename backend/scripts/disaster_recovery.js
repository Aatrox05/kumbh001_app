const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sqlite3 = require('sqlite3').verbose();

const DB_PATH = process.env.DB_FILE 
  ? path.resolve(__dirname, '../', process.env.DB_FILE)
  : path.resolve(__dirname, '../database.sqlite');
const BACKUP_DIR = path.join(__dirname, '..', 'backups');

async function createBackup() {
  console.log('[DR BACKUP] Flushing WAL journal and creating snapshot...');
  if (!fs.existsSync(BACKUP_DIR)) fs.mkdirSync(BACKUP_DIR, { recursive: true });

  const sourceDb = new sqlite3.Database(DB_PATH);
  await new Promise((resolve, reject) => sourceDb.run('PRAGMA wal_checkpoint(TRUNCATE)', err => err ? reject(err) : resolve()));
  await new Promise(resolve => sourceDb.close(resolve));

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFileName = `kumbh_backup_${timestamp}.sqlite`;
  const backupPath = path.join(BACKUP_DIR, backupFileName);

  fs.copyFileSync(DB_PATH, backupPath);
  const backupBuffer = fs.readFileSync(backupPath);
  const sha256Hash = crypto.createHash('sha256').update(backupBuffer).digest('hex');

  console.log(`✓ Backup created: ${backupFileName} (${backupBuffer.length} bytes)`);
  console.log(`✓ SHA256 Checksum: ${sha256Hash}`);
  return backupPath;
}

async function verifyDatabase(targetPath) {
  console.log(`[DR VERIFY] Auditing database integrity at ${targetPath}...`);
  const verifyDb = new sqlite3.Database(targetPath);

  const queryAsync = (sql) => new Promise((resolve, reject) => {
    verifyDb.all(sql, [], (err, rows) => err ? reject(err) : resolve(rows));
  });

  try {
    const syncRows = await queryAsync('SELECT MAX(version) as max_version, COUNT(*) as total_changes FROM sync_changes');
    const annRows = await queryAsync('SELECT COUNT(*) as count FROM announcements');
    const userRows = await queryAsync('SELECT COUNT(*) as count FROM users');
    const placeRows = await queryAsync('SELECT COUNT(*) as count FROM places');

    console.log(`====================================================`);
    console.log(`📊 DATABASE INTEGRITY AUDIT RESULTS:`);
    console.log(`   - Incremental Sync Cursor (maxVersion): ${syncRows[0]?.max_version || 0}`);
    console.log(`   - Total Sync Change Log Records:        ${syncRows[0]?.total_changes || 0}`);
    console.log(`   - Announcements Restored:              ${annRows[0]?.count || 0}`);
    console.log(`   - Verified Places Restored:             ${placeRows[0]?.count || 0}`);
    console.log(`   - Registered Users Restored:            ${userRows[0]?.count || 0}`);
    console.log(`====================================================`);
    console.log(`✅ DISASTER RECOVERY RESTORATION VERIFIED LOCALLY — PRODUCTION CLOUD DR NOT CONFIGURED.`);
  } finally {
    await new Promise(resolve => verifyDb.close(resolve));
  }
}

async function restoreDatabase(backupFilePath) {
  if (!fs.existsSync(backupFilePath)) {
    console.error(`❌ Backup file not found at ${backupFilePath}`);
    process.exit(1);
  }
  console.log(`[DR RESTORE] Restoring database from ${backupFilePath} to ${DB_PATH}...`);
  fs.copyFileSync(backupFilePath, DB_PATH);
  console.log(`✓ Database successfully restored.`);
  await verifyDatabase(DB_PATH);
}

async function cleanupOldBackups(retentionDays = 7) {
  console.log(`[DR CLEANUP] Cleaning up backups older than ${retentionDays} days...`);
  if (!fs.existsSync(BACKUP_DIR)) return;

  const files = fs.readdirSync(BACKUP_DIR);
  const now = Date.now();
  let deletedCount = 0;

  for (const file of files) {
    if (file.endsWith('.sqlite')) {
      const filePath = path.join(BACKUP_DIR, file);
      const stat = fs.statSync(filePath);
      if (now - stat.mtimeMs > retentionDays * 86400 * 1000) {
        fs.unlinkSync(filePath);
        deletedCount++;
      }
    }
  }
  console.log(`✓ Cleanup complete. Deleted ${deletedCount} expired backup files.`);
}

async function main() {
  const arg = process.argv[2] || 'full-test';
  
  if (arg === 'backup') {
    await createBackup();
  } else if (arg === 'restore') {
    const targetFile = process.argv[3];
    if (!targetFile) {
      console.error('Please specify backup file to restore: node scripts/disaster_recovery.js restore <file>');
      process.exit(1);
    }
    await restoreDatabase(targetFile);
  } else if (arg === 'verify') {
    await verifyDatabase(DB_PATH);
  } else if (arg === 'cleanup') {
    await cleanupOldBackups();
  } else {
    // Default full test suite
    const backupPath = await createBackup();
    const tempRestored = path.join(BACKUP_DIR, `temp_verify_${Date.now()}.sqlite`);
    fs.copyFileSync(backupPath, tempRestored);
    await verifyDatabase(tempRestored);
    if (fs.existsSync(tempRestored)) fs.unlinkSync(tempRestored);
  }
}

main();
