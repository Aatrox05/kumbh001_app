const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const dbPath = process.env.DB_FILE 
  ? path.resolve(__dirname, '../../', process.env.DB_FILE)
  : path.resolve(__dirname, '../../database.sqlite');

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Failed to connect to SQLite database:', err.message);
  } else {
    console.log(`Connected to SQLite database at ${dbPath}`);
  }
});

// Enable PRAGMA foreign keys and WAL mode for reliability
db.serialize(() => {
  db.run('PRAGMA foreign_keys = ON');
  db.run('PRAGMA journal_mode = WAL');
});

// Helper functions returning Promises for async/await usage
const query = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

const get = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const run = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
};

const logChange = async (entityType, entityId, action, payload = {}) => {
  try {
    const payloadStr = typeof payload === 'string' ? payload : JSON.stringify(payload);
    const result = await run(
      `INSERT INTO sync_changes (entity_type, entity_id, action, payload) VALUES (?, ?, ?, ?)`,
      [entityType, entityId, action, payloadStr]
    );
    return result.id; // Returns incremental version number
  } catch (err) {
    console.error(`Failed to log sync change for ${entityType}:${entityId}:`, err);
    return null;
  }
};

const getCurrentVersion = async () => {
  try {
    const row = await get(`SELECT MAX(version) as max_version FROM sync_changes`);
    return row && row.max_version ? row.max_version : 0;
  } catch (err) {
    return 0;
  }
};

const initSchema = async () => {
  const schemaSql = `
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'PUBLIC',
      name TEXT NOT NULL,
      phone TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS places (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      address TEXT,
      opening_hours TEXT,
      image_url TEXT,
      crowd_level TEXT DEFAULT 'LOW',
      is_verified INTEGER DEFAULT 1,
      version INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      description TEXT,
      start_time DATETIME NOT NULL,
      end_time DATETIME NOT NULL,
      location_name TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      organizer TEXT,
      is_verified INTEGER DEFAULT 1,
      version INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS announcements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      priority TEXT DEFAULT 'NORMAL',
      category TEXT DEFAULT 'GENERAL',
      target_group TEXT DEFAULT 'ALL',
      published_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      expires_at DATETIME,
      created_by INTEGER,
      source_name TEXT DEFAULT 'Kumbh Disaster Control Command',
      version INTEGER DEFAULT 1,
      status TEXT DEFAULT 'PUBLISHED',
      FOREIGN KEY (created_by) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS emergency_facilities (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      phone TEXT NOT NULL,
      secondary_phone TEXT,
      address TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      capacity INTEGER DEFAULT 100,
      current_status TEXT DEFAULT 'OPERATIONAL',
      is_verified INTEGER DEFAULT 1,
      version INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sync_changes (
      version INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT NOT NULL,
      entity_id INTEGER NOT NULL,
      action TEXT NOT NULL,
      payload TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS external_sources (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source_url TEXT NOT NULL,
      source_name TEXT NOT NULL,
      trust_category TEXT NOT NULL,
      fetched_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      published_at DATETIME,
      provenance_metadata TEXT,
      verification_status TEXT DEFAULT 'VERIFIED'
    );

    CREATE TABLE IF NOT EXISTS registered_sources (
      source_id TEXT PRIMARY KEY,
      source_name TEXT NOT NULL,
      base_url TEXT NOT NULL,
      allowed_paths TEXT DEFAULT '/*',
      authority TEXT NOT NULL,
      trust_level TEXT DEFAULT 'AUTHORITATIVE',
      enabled INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sos_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      idempotency_key TEXT UNIQUE,
      user_id INTEGER,
      device_id TEXT NOT NULL,
      contact_name TEXT,
      contact_phone TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      location_address TEXT,
      status TEXT DEFAULT 'RECEIVED',
      emergency_type TEXT NOT NULL DEFAULT 'GENERAL',
      remarks TEXT,
      assigned_to_user_id INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (assigned_to_user_id) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS lost_found_reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      report_type TEXT NOT NULL,
      person_or_item_name TEXT NOT NULL,
      description TEXT,
      age INTEGER,
      gender TEXT,
      last_seen_location TEXT,
      contact_phone TEXT NOT NULL,
      status TEXT DEFAULT 'REPORTED',
      image_url TEXT,
      is_synced INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS family_safety_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      primary_user_id INTEGER NOT NULL,
      member_name TEXT NOT NULL,
      member_phone TEXT NOT NULL,
      tracking_enabled INTEGER DEFAULT 1,
      last_known_lat REAL,
      last_known_lng REAL,
      last_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (primary_user_id) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS device_tokens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      token TEXT NOT NULL UNIQUE,
      platform TEXT DEFAULT 'ANDROID',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS parking_facilities (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      location_name TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      total_capacity INTEGER NOT NULL,
      live_available_spaces INTEGER,
      availability_status TEXT DEFAULT 'LIVE_UNAVAILABLE',
      vehicle_type TEXT DEFAULT 'ALL',
      operating_hours TEXT DEFAULT '24/7',
      is_accessible INTEGER DEFAULT 1,
      source_name TEXT DEFAULT 'Nashik Municipal Transport',
      is_verified INTEGER DEFAULT 1,
      version INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      action TEXT NOT NULL,
      resource TEXT NOT NULL,
      details TEXT,
      ip_address TEXT,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS security_state (
      id INTEGER PRIMARY KEY DEFAULT 1,
      current_state TEXT NOT NULL DEFAULT 'NORMAL',
      last_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_by TEXT DEFAULT 'SYSTEM',
      lock_reason TEXT,
      last_known_good_commit TEXT DEFAULT 'HEAD'
    );

    CREATE TABLE IF NOT EXISTS security_incidents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      incident_id TEXT UNIQUE NOT NULL,
      severity TEXT NOT NULL DEFAULT 'SUSPICIOUS',
      source TEXT NOT NULL DEFAULT 'API',
      event_type TEXT NOT NULL,
      actor TEXT DEFAULT 'UNKNOWN',
      resource TEXT,
      commit_sha TEXT,
      workflow_id TEXT,
      security_state TEXT NOT NULL DEFAULT 'NORMAL',
      status TEXT NOT NULL DEFAULT 'OPEN',
      action_taken TEXT NOT NULL DEFAULT 'LOGGED',
      metadata TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      resolved_at DATETIME,
      resolved_by TEXT
    );
  `;

  await new Promise((resolve, reject) => {
    db.exec(schemaSql, (err) => {
      if (err) reject(err);
      else resolve();
    });
  });

  // Safely add missing columns to existing database tables if they were created earlier
  const migrations = [
    `ALTER TABLE announcements ADD COLUMN category TEXT DEFAULT 'GENERAL'`,
    `ALTER TABLE announcements ADD COLUMN source_name TEXT DEFAULT 'Kumbh Disaster Control Command'`,
    `ALTER TABLE announcements ADD COLUMN version INTEGER DEFAULT 1`,
    `ALTER TABLE announcements ADD COLUMN status TEXT DEFAULT 'PUBLISHED'`,
    `ALTER TABLE places ADD COLUMN version INTEGER DEFAULT 1`,
    `ALTER TABLE events ADD COLUMN version INTEGER DEFAULT 1`,
    `ALTER TABLE emergency_facilities ADD COLUMN version INTEGER DEFAULT 1`
  ];

  for (const m of migrations) {
    try {
      await run(m);
    } catch (e) {
      // Column already exists, ignore duplicate column error
    }
  }

  console.log('Database schema & column migrations completed successfully.');
};

module.exports = {
  db,
  query,
  get,
  run,
  logChange,
  getCurrentVersion,
  initSchema
};
