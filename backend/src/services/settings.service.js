const db = require('../config/db');

async function upsertSettings(userId, settings) {
  const payload =
    settings && typeof settings === 'object' && !Array.isArray(settings)
      ? settings
      : {};
  const result = await db.query(
    `INSERT INTO user_app_settings (user_id, settings, updated_at)
     VALUES ($1, $2::jsonb, NOW())
     ON CONFLICT (user_id) DO UPDATE SET
       settings = EXCLUDED.settings,
       updated_at = NOW()
     RETURNING settings, updated_at`,
    [userId, JSON.stringify(payload)],
  );
  return mapRow(result.rows[0]);
}

async function getSettings(userId) {
  const result = await db.query(
    `SELECT settings, updated_at FROM user_app_settings WHERE user_id = $1`,
    [userId],
  );
  if (result.rowCount === 0) return null;
  return mapRow(result.rows[0]);
}

function mapRow(row) {
  if (!row) return null;
  return {
    settings: row.settings || {},
    updatedAt: row.updated_at,
  };
}

module.exports = {
  upsertSettings,
  getSettings,
};
