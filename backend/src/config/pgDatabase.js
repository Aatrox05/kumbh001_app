/**
 * PostgreSQL Production Migration Ready Database Layer
 * Allows smooth transition from SQLite (local single-node) to PostgreSQL (multi-node cloud cluster).
 */
const sqliteDb = require('./database');

const isPostgres = Boolean(process.env.POSTGRES_HOST || process.env.DATABASE_URL);

let pgPool = null;
if (isPostgres) {
  try {
    const { Pool } = require('pg');
    pgPool = new Pool({
      connectionString: process.env.DATABASE_URL,
      host: process.env.POSTGRES_HOST,
      port: process.env.POSTGRES_PORT || 5432,
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DB || 'kumbh_db',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
    console.log('[pgDatabase] Configured for PostgreSQL cluster mode');
  } catch (err) {
    console.warn('[pgDatabase] pg package not loaded, falling back to SQLite:', err.message);
  }
}

const query = async (sql, params = []) => {
  if (isPostgres && pgPool) {
    // Convert SQLite ? parameters to PostgreSQL $1, $2, ...
    let paramIndex = 1;
    const pgSql = sql.replace(/\?/g, () => `$${paramIndex++}`);
    const res = await pgPool.query(pgSql, params);
    return res.rows;
  }
  return sqliteDb.query(sql, params);
};

const get = async (sql, params = []) => {
  const rows = await query(sql, params);
  return rows.length > 0 ? rows[0] : null;
};

const run = async (sql, params = []) => {
  if (isPostgres && pgPool) {
    let paramIndex = 1;
    const pgSql = sql.replace(/\?/g, () => `$${paramIndex++}`);
    const res = await pgPool.query(pgSql, params);
    return { id: res.rows[0]?.id || null, changes: res.rowCount };
  }
  return sqliteDb.run(sql, params);
};

module.exports = {
  isPostgres,
  query,
  get,
  run,
  logChange: sqliteDb.logChange
};
