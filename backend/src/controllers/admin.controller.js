const adminService = require('../services/admin.service');
const mealStore = require('../services/meal_store.service');
const fs = require('fs');
const AppError = require('../utils/AppError');

async function listUsers(req, res, next) {
  try {
    const users = await adminService.listUsers();
    res.json({ ok: true, users });
  } catch (err) {
    next(err);
  }
}

async function getUser(req, res, next) {
  try {
    const detail = await adminService.getUserDetail(req.params.userId);
    const date = req.query.date || new Date().toISOString().slice(0, 10);
    const meals = await mealStore.listMealsForUser(req.params.userId, { date });
    const progress = await mealStore.getProgress(req.params.userId, date);
    res.json({ ok: true, user: detail, date, meals, progress });
  } catch (err) {
    next(err);
  }
}

async function getUserMeals(req, res, next) {
  try {
    const meals = await mealStore.listMealsForUser(req.params.userId, {
      date: req.query.date,
      from: req.query.from,
      to: req.query.to,
    });
    res.json({ ok: true, meals });
  } catch (err) {
    next(err);
  }
}

async function getUserAnalysis(req, res, next) {
  try {
    const range = req.query.range || 'today';
    const data = await adminService.analyzeUserMeals(req.params.userId, range);
    res.json({ ok: true, ...data });
  } catch (err) {
    next(err);
  }
}

async function getMealImage(req, res, next) {
  try {
    const meal = await mealStore.getMealById(req.params.mealId);
    if (!meal || !meal.imagePath) {
      throw new AppError('Không có ảnh bữa này', 404);
    }
    if (meal.userId !== req.params.userId) {
      throw new AppError('Ảnh không thuộc user này', 404);
    }
    const abs = mealStore.absoluteMealImagePath(meal.imagePath);
    if (!abs || !fs.existsSync(abs)) {
      throw new AppError('File ảnh không tồn tại', 404);
    }
    // Chuyển AVIF → JPEG để app/Flutter xem ổn định; file gốc vẫn là AVIF.
    const sharp = require('sharp');
    const jpeg = await sharp(abs).jpeg({ quality: 72 }).toBuffer();
    res.setHeader('Content-Type', 'image/jpeg');
    res.setHeader('Cache-Control', 'private, max-age=3600');
    res.send(jpeg);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listUsers,
  getUser,
  getUserMeals,
  getUserAnalysis,
  getMealImage,
};
