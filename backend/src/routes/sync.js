const express = require('express');
const router = express.Router();
const db = require('../config/database');

const MAX_BATCH_SIZE = 100;

// GET /api/v1/sync?since=<version>
router.get('/', async (req, res, next) => {
  try {
    const sinceVersion = parseInt(req.query.since || '0', 10);
    const maxVersion = await db.getCurrentVersion();

    // ETag HTTP revalidation
    const etag = `W/"sync-v${maxVersion}"`;
    res.setHeader('ETag', etag);

    const clientEtag = req.headers['if-none-match'];
    if (clientEtag === etag && sinceVersion >= maxVersion) {
      return res.status(304).end(); // 304 Not Modified
    }

    if (sinceVersion >= maxVersion && maxVersion > 0) {
      return res.json({
        success: true,
        current_version: maxVersion,
        since_version: sinceVersion,
        has_changes: false,
        has_more: false,
        changes: []
      });
    }

    // Fetch incremental changes since version (paginated in batches of 100)
    const changeRows = await db.query(
      `SELECT version, entity_type as entity, entity_id as id, action, payload, timestamp 
       FROM sync_changes 
       WHERE version > ? 
       ORDER BY version ASC LIMIT ?`,
      [sinceVersion, MAX_BATCH_SIZE]
    );

    const formattedChanges = changeRows.map(row => {
      let parsedPayload = {};
      try {
        parsedPayload = row.payload ? JSON.parse(row.payload) : {};
      } catch (e) {
        parsedPayload = {};
      }

      // Security Sanitization: Remove password hashes or internal secrets if any
      if (parsedPayload.password_hash) delete parsedPayload.password_hash;
      if (parsedPayload.ip_address) delete parsedPayload.ip_address;

      return {
        version: row.version,
        entity: row.entity,
        id: row.id,
        action: row.action, // CREATED, UPDATED, DELETED
        timestamp: row.timestamp,
        data: parsedPayload
      };
    });

    // The cursor returned to client MUST match the last change item's version in this batch!
    const batchMaxVersion = formattedChanges.length > 0
      ? formattedChanges[formattedChanges.length - 1].version
      : maxVersion;

    const hasMore = batchMaxVersion < maxVersion;

    res.json({
      success: true,
      current_version: batchMaxVersion,
      max_server_version: maxVersion,
      since_version: sinceVersion,
      has_changes: formattedChanges.length > 0,
      has_more: hasMore,
      changes: formattedChanges
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
