const settingsService = require('../services/settings.service');
const AppError = require('../utils/AppError');

async function sync(req, res, next) {
  try {
    const body = req.body || {};
    const settings = body.settings;
    if (!settings || typeof settings !== 'object' || Array.isArray(settings)) {
      throw new AppError('settings phải là object', 400);
    }
    const saved = await settingsService.upsertSettings(req.user.id, settings);
    res.json({ ok: true, ...saved });
  } catch (err) {
    next(err);
  }
}

async function getMine(req, res, next) {
  try {
    const saved = await settingsService.getSettings(req.user.id);
    res.json({ ok: true, settings: saved?.settings || null, updatedAt: saved?.updatedAt || null });
  } catch (err) {
    next(err);
  }
}

module.exports = { sync, getMine };
