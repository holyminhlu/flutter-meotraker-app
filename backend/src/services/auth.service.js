const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const config = require('../config');
const AppError = require('../utils/AppError');

const SALT_ROUNDS = 10;

function normalizePhone(phone) {
  if (!phone) return null;
  const digits = String(phone).replace(/[^\d+]/g, '').trim();
  return digits || null;
}

async function getOnboardingFlag(userId) {
  const result = await db.query(
    `SELECT onboarding_completed FROM user_profiles WHERE user_id = $1`,
    [userId],
  );
  if (result.rowCount === 0) {
    return { onboardingCompleted: false, onboardingStep: 'body_stats' };
  }
  return {
    onboardingCompleted: result.rows[0].onboarding_completed,
    onboardingStep: result.rows[0].onboarding_completed
      ? 'done'
      : 'dietary', // profile exists → next is dietary or done handled elsewhere
  };
}

async function toPublicUser(row) {
  if (row.role === 'admin') {
    return {
      id: row.id,
      email: row.email,
      phone: row.phone,
      displayName: row.display_name,
      authProvider: row.auth_provider || 'email',
      role: 'admin',
      onboardingCompleted: true,
      onboardingStep: 'done',
      createdAt: row.created_at,
    };
  }

  const onboarding = await getOnboardingFlag(row.id);
  // Refine step if profile missing vs dietary missing
  let step = 'body_stats';
  if (onboarding.onboardingCompleted) {
    step = 'done';
  } else {
    const diet = await db.query(
      `SELECT 1 FROM user_dietary_preferences WHERE user_id = $1`,
      [row.id],
    );
    const profile = await db.query(
      `SELECT 1 FROM user_profiles WHERE user_id = $1`,
      [row.id],
    );
    if (profile.rowCount === 0) step = 'body_stats';
    else if (diet.rowCount === 0) step = 'dietary';
    else step = 'done';
  }

  return {
    id: row.id,
    email: row.email,
    phone: row.phone,
    displayName: row.display_name,
    authProvider: row.auth_provider || 'email',
    role: row.role || 'user',
    onboardingCompleted: step === 'done',
    onboardingStep: step,
    createdAt: row.created_at,
  };
}

function signToken(userId) {
  return jwt.sign({ sub: userId }, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
}

async function register({ email, phone, password, displayName }) {
  const normalizedEmail = email
    ? String(email).trim().toLowerCase()
    : null;
  const normalizedPhone = normalizePhone(phone);
  const name = String(displayName || '').trim();
  const plainPassword = String(password || '');

  if (!normalizedEmail && !normalizedPhone) {
    throw new AppError('Cần email hoặc số điện thoại', 400);
  }
  if (normalizedEmail && !normalizedEmail.includes('@')) {
    throw new AppError('Email không hợp lệ', 400);
  }
  if (name.length < 2) {
    throw new AppError('Họ tên tối thiểu 2 ký tự', 400);
  }
  if (plainPassword.length < 6) {
    throw new AppError('Mật khẩu tối thiểu 6 ký tự', 400);
  }

  if (normalizedEmail) {
    const existingEmail = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [normalizedEmail],
    );
    if (existingEmail.rowCount > 0) {
      throw new AppError('Email đã được sử dụng', 409);
    }
  }
  if (normalizedPhone) {
    const existingPhone = await db.query(
      'SELECT id FROM users WHERE phone = $1',
      [normalizedPhone],
    );
    if (existingPhone.rowCount > 0) {
      throw new AppError('Số điện thoại đã được sử dụng', 409);
    }
  }

  const passwordHash = await bcrypt.hash(plainPassword, SALT_ROUNDS);
  const result = await db.query(
    `INSERT INTO users (email, phone, password_hash, display_name, auth_provider)
     VALUES ($1, $2, $3, $4, 'email')
     RETURNING id, email, phone, display_name, auth_provider, role, created_at`,
    [normalizedEmail, normalizedPhone, passwordHash, name],
  );

  const user = await toPublicUser(result.rows[0]);
  const token = signToken(user.id);
  return { user, token };
}

async function login({ email, phone, password }) {
  const normalizedEmail = email
    ? String(email).trim().toLowerCase()
    : null;
  const normalizedPhone = normalizePhone(phone);
  const plainPassword = String(password || '');

  if ((!normalizedEmail && !normalizedPhone) || !plainPassword) {
    throw new AppError('Cần email/SĐT và mật khẩu', 400);
  }

  let result;
  if (normalizedEmail) {
    result = await db.query(
      `SELECT id, email, phone, password_hash, display_name, auth_provider, role, created_at
       FROM users WHERE email = $1`,
      [normalizedEmail],
    );
  } else {
    result = await db.query(
      `SELECT id, email, phone, password_hash, display_name, auth_provider, role, created_at
       FROM users WHERE phone = $1`,
      [normalizedPhone],
    );
  }

  if (result.rowCount === 0) {
    throw new AppError('Tài khoản hoặc mật khẩu không đúng', 401);
  }

  const row = result.rows[0];
  const matched = await bcrypt.compare(plainPassword, row.password_hash);
  if (!matched) {
    throw new AppError('Tài khoản hoặc mật khẩu không đúng', 401);
  }

  const user = await toPublicUser(row);
  const token = signToken(user.id);
  return { user, token };
}

async function getUserById(userId) {
  const result = await db.query(
    `SELECT id, email, phone, display_name, auth_provider, role, created_at
     FROM users WHERE id = $1`,
    [userId],
  );
  if (result.rowCount === 0) {
    throw new AppError('Không tìm thấy người dùng', 404);
  }
  return toPublicUser(result.rows[0]);
}

async function forgotPassword({ email }) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  if (!normalizedEmail || !normalizedEmail.includes('@')) {
    throw new AppError('Email không hợp lệ', 400);
  }

  const userResult = await db.query(
    `SELECT id FROM users WHERE email = $1`,
    [normalizedEmail],
  );

  // Always return generic message to avoid account enumeration
  const generic = {
    message:
      'Nếu email tồn tại, mã đặt lại mật khẩu đã được tạo. Kiểm tra hộp thư hoặc dùng mã (dev).',
  };

  if (userResult.rowCount === 0) {
    return generic;
  }

  const userId = userResult.rows[0].id;
  const rawToken = crypto.randomBytes(24).toString('hex');
  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

  await db.query(
    `UPDATE password_reset_tokens SET used_at = NOW()
     WHERE user_id = $1 AND used_at IS NULL`,
    [userId],
  );
  await db.query(
    `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [userId, tokenHash, expiresAt],
  );

  return {
    ...generic,
    // Dev helper — remove when real email is wired
    resetToken: rawToken,
    expiresInMinutes: 60,
  };
}

async function resetPassword({ token, password }) {
  const rawToken = String(token || '').trim();
  const plainPassword = String(password || '');
  if (!rawToken) throw new AppError('Thiếu mã đặt lại mật khẩu', 400);
  if (plainPassword.length < 6) {
    throw new AppError('Mật khẩu tối thiểu 6 ký tự', 400);
  }

  const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
  const result = await db.query(
    `SELECT id, user_id, expires_at, used_at
     FROM password_reset_tokens WHERE token_hash = $1`,
    [tokenHash],
  );

  if (result.rowCount === 0) {
    throw new AppError('Mã đặt lại không hợp lệ', 400);
  }
  const row = result.rows[0];
  if (row.used_at) throw new AppError('Mã đã được sử dụng', 400);
  if (new Date(row.expires_at) < new Date()) {
    throw new AppError('Mã đã hết hạn', 400);
  }

  const passwordHash = await bcrypt.hash(plainPassword, SALT_ROUNDS);
  await db.query(`UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`, [
    passwordHash,
    row.user_id,
  ]);
  await db.query(
    `UPDATE password_reset_tokens SET used_at = NOW() WHERE id = $1`,
    [row.id],
  );

  return { message: 'Đặt lại mật khẩu thành công' };
}

function oauthNotReady(provider) {
  throw new AppError(
    `Đăng nhập ${provider} sẽ sớm được hỗ trợ. Hiện dùng email/SĐT.`,
    501,
  );
}

module.exports = {
  register,
  login,
  getUserById,
  signToken,
  forgotPassword,
  resetPassword,
  oauthNotReady,
  toPublicUser,
};
