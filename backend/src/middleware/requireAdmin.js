const db = require('../config/db');
const AppError = require('../utils/AppError');

async function requireAdmin(req, _res, next) {
  try {
    if (!req.user?.id) {
      return next(new AppError('Thiếu xác thực', 401));
    }
    const result = await db.query(
      `SELECT id, role FROM users WHERE id = $1`,
      [req.user.id],
    );
    if (result.rowCount === 0 || result.rows[0].role !== 'admin') {
      return next(new AppError('Chỉ dành cho admin', 403));
    }
    req.user.role = 'admin';
    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = requireAdmin;
