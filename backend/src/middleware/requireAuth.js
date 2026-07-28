const jwt = require('jsonwebtoken');
const config = require('../config');
const AppError = require('../utils/AppError');

function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(new AppError('Thiếu token xác thực', 401));
  }

  try {
    const payload = jwt.verify(token, config.jwt.secret);
    req.user = { id: payload.sub };
    return next();
  } catch (_err) {
    return next(new AppError('Token không hợp lệ hoặc đã hết hạn', 401));
  }
}

module.exports = requireAuth;
