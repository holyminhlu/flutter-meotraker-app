const db = require('../config/db');

async function check(_req, res, next) {
  try {
    const result = await db.query('SELECT NOW() AS now');
    res.json({
      status: 'healthy',
      database: 'connected',
      serverTime: result.rows[0].now,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { check };
