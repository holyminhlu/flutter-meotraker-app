const authService = require('../services/auth.service');

async function register(req, res, next) {
  try {
    const { email, phone, password, displayName } = req.body || {};
    const data = await authService.register({
      email,
      phone,
      password,
      displayName,
    });
    res.status(201).json(data);
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { email, phone, password } = req.body || {};
    const data = await authService.login({ email, phone, password });
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = await authService.getUserById(req.user.id);
    res.json({ user });
  } catch (err) {
    next(err);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const data = await authService.forgotPassword(req.body || {});
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const data = await authService.resetPassword(req.body || {});
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function oauthGoogle(_req, res, next) {
  try {
    authService.oauthNotReady('Google');
    res.json({});
  } catch (err) {
    next(err);
  }
}

async function oauthApple(_req, res, next) {
  try {
    authService.oauthNotReady('Apple');
    res.json({});
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  login,
  me,
  forgotPassword,
  resetPassword,
  oauthGoogle,
  oauthApple,
};
