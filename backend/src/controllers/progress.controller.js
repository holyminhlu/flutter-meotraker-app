const mealStore = require('../services/meal_store.service');
const AppError = require('../utils/AppError');

async function sync(req, res, next) {
  try {
    const payload = req.body || {};
    if (!payload.dateKey) {
      throw new AppError('dateKey là bắt buộc', 400);
    }
    const progress = await mealStore.upsertDailyProgress(req.user.id, payload);
    res.json({ ok: true, progress });
  } catch (err) {
    next(err);
  }
}

module.exports = { sync };
