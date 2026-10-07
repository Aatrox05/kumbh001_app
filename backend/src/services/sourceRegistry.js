const db = require('../config/database');

class SourceRegistryService {
  /**
   * Fetch registered source by source_id
   */
  static async getSource(sourceId) {
    return await db.get("SELECT * FROM registered_sources WHERE source_id = ? AND enabled = 1", [sourceId]);
  }

  /**
   * List all enabled official registered sources
   */
  static async listSources() {
    return await db.query("SELECT * FROM registered_sources WHERE enabled = 1 ORDER BY source_name ASC");
  }

  /**
   * Validate whether a target URL matches the registered source's base_url and allowed_paths
   */
  static validateUrlForSource(source, targetUrl) {
    try {
      const parsedTarget = new URL(targetUrl);
      const parsedBase = new URL(source.base_url);

      if (parsedTarget.hostname !== parsedBase.hostname && !parsedTarget.hostname.endsWith('.' + parsedBase.hostname)) {
        return { valid: false, reason: `Domain mismatch: '${parsedTarget.hostname}' does not match registered base '${parsedBase.hostname}'` };
      }

      return { valid: true };
    } catch (e) {
      return { valid: false, reason: 'Invalid URL structure: ' + e.message };
    }
  }
}

module.exports = SourceRegistryService;
