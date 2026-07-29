const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const db = require('../config/db');
const config = require('../config');

const UPLOAD_ROOT = path.join(__dirname, '../../uploads/meals');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

/**
 * Nén buffer ảnh sang AVIF nhỏ và lưu theo user/date/period.
 * @returns {Promise<string|null>} relative path from uploads root
 */
async function saveMealAvif({ userId, dateKey, period, imageBuffer }) {
  if (!imageBuffer || !Buffer.isBuffer(imageBuffer) || imageBuffer.length === 0) {
    return null;
  }
  const dir = path.join(UPLOAD_ROOT, String(userId), String(dateKey));
  ensureDir(dir);
  const filename = `${period}.avif`;
  const abs = path.join(dir, filename);
  await sharp(imageBuffer)
    .rotate()
    .resize({ width: 960, height: 960, fit: 'inside', withoutEnlargement: true })
    .avif({ quality: 45, effort: 4 })
    .toFile(abs);
  return path.posix.join(String(userId), String(dateKey), filename);
}

function absoluteMealImagePath(relativePath) {
  if (!relativePath) return null;
  return path.join(UPLOAD_ROOT, relativePath);
}

async function upsertMealEntry({
  userId,
  dateKey,
  period,
  foodItems = [],
  description = null,
  advice = null,
  timingStatus = null,
  marksCompleted = false,
  foodValid = false,
  imagePath = null,
  aiSummary = null,
}) {
  const result = await db.query(
    `INSERT INTO meal_entries (
      user_id, date_key, period, food_items, description, advice,
      timing_status, marks_completed, food_valid, image_path, ai_summary, updated_at
    ) VALUES ($1,$2::date,$3,$4,$5,$6,$7,$8,$9,$10,$11, NOW())
    ON CONFLICT (user_id, date_key, period) DO UPDATE SET
      food_items = EXCLUDED.food_items,
      description = COALESCE(EXCLUDED.description, meal_entries.description),
      advice = COALESCE(EXCLUDED.advice, meal_entries.advice),
      timing_status = COALESCE(EXCLUDED.timing_status, meal_entries.timing_status),
      marks_completed = EXCLUDED.marks_completed OR meal_entries.marks_completed,
      food_valid = EXCLUDED.food_valid OR meal_entries.food_valid,
      image_path = COALESCE(EXCLUDED.image_path, meal_entries.image_path),
      ai_summary = COALESCE(EXCLUDED.ai_summary, meal_entries.ai_summary),
      updated_at = NOW()
    RETURNING *`,
    [
      userId,
      dateKey,
      period,
      foodItems,
      description,
      advice,
      timingStatus,
      marksCompleted,
      foodValid,
      imagePath,
      aiSummary,
    ],
  );
  return mapMeal(result.rows[0]);
}

function mapMeal(row) {
  if (!row) return null;
  return {
    id: row.id,
    userId: row.user_id,
    dateKey: row.date_key instanceof Date
      ? row.date_key.toISOString().slice(0, 10)
      : String(row.date_key).slice(0, 10),
    period: row.period,
    foodItems: row.food_items || [],
    description: row.description,
    advice: row.advice,
    timingStatus: row.timing_status,
    marksCompleted: row.marks_completed,
    foodValid: row.food_valid,
    hasImage: Boolean(row.image_path),
    imagePath: row.image_path,
    aiSummary: row.ai_summary,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

async function listMealsForUser(userId, { from, to, date } = {}) {
  const params = [userId];
  let where = 'user_id = $1';
  if (date) {
    params.push(date);
    where += ` AND date_key = $${params.length}::date`;
  } else {
    if (from) {
      params.push(from);
      where += ` AND date_key >= $${params.length}::date`;
    }
    if (to) {
      params.push(to);
      where += ` AND date_key <= $${params.length}::date`;
    }
  }
  const result = await db.query(
    `SELECT * FROM meal_entries WHERE ${where}
     ORDER BY date_key DESC, CASE period
       WHEN 'breakfast' THEN 1 WHEN 'lunch' THEN 2 ELSE 3 END`,
    params,
  );
  return result.rows.map(mapMeal);
}

async function getMealById(id) {
  const result = await db.query(`SELECT * FROM meal_entries WHERE id = $1`, [id]);
  return mapMeal(result.rows[0]);
}

async function upsertDailyProgress(userId, payload) {
  const dateKey = payload.dateKey;
  const water = Array.isArray(payload.waterSlots)
    ? payload.waterSlots.slice(0, 6)
    : [false, false, false, false, false, false];
  while (water.length < 6) water.push(false);
  const exercise = Array.isArray(payload.exerciseSlots)
    ? payload.exerciseSlots.slice(0, 3)
    : [false, false, false];
  while (exercise.length < 3) exercise.push(false);
  const sessionAwards = Array.isArray(payload.exerciseSessionAwards)
    ? payload.exerciseSessionAwards.slice(0, 3)
    : [false, false, false];
  while (sessionAwards.length < 3) sessionAwards.push(false);

  const result = await db.query(
    `INSERT INTO daily_progress (
      user_id, date_key, meal_breakfast, meal_lunch, meal_dinner,
      water_slots, exercise_slots, exercise_session_awards, points, streak_days,
      awarded_meal, awarded_water, awarded_exercise, updated_at
    ) VALUES ($1,$2::date,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13, NOW())
    ON CONFLICT (user_id, date_key) DO UPDATE SET
      meal_breakfast = EXCLUDED.meal_breakfast,
      meal_lunch = EXCLUDED.meal_lunch,
      meal_dinner = EXCLUDED.meal_dinner,
      water_slots = EXCLUDED.water_slots,
      exercise_slots = EXCLUDED.exercise_slots,
      exercise_session_awards = EXCLUDED.exercise_session_awards,
      points = EXCLUDED.points,
      streak_days = EXCLUDED.streak_days,
      awarded_meal = EXCLUDED.awarded_meal,
      awarded_water = EXCLUDED.awarded_water,
      awarded_exercise = EXCLUDED.awarded_exercise,
      updated_at = NOW()
    RETURNING *`,
    [
      userId,
      dateKey,
      Boolean(payload.mealBreakfast),
      Boolean(payload.mealLunch),
      Boolean(payload.mealDinner),
      water,
      exercise,
      sessionAwards,
      Number(payload.points) || 0,
      Number(payload.streakDays) || 0,
      Boolean(payload.awardedMeal),
      Boolean(payload.awardedWater),
      Boolean(payload.awardedExercise),
    ],
  );
  return mapProgress(result.rows[0]);
}

function mapProgress(row) {
  if (!row) return null;
  return {
    userId: row.user_id,
    dateKey: row.date_key instanceof Date
      ? row.date_key.toISOString().slice(0, 10)
      : String(row.date_key).slice(0, 10),
    mealBreakfast: row.meal_breakfast,
    mealLunch: row.meal_lunch,
    mealDinner: row.meal_dinner,
    waterSlots: row.water_slots || [],
    exerciseSlots: row.exercise_slots || [],
    exerciseSessionAwards: row.exercise_session_awards || [false, false, false],
    points: row.points,
    streakDays: row.streak_days,
    awardedMeal: row.awarded_meal,
    awardedWater: row.awarded_water,
    awardedExercise: row.awarded_exercise,
    updatedAt: row.updated_at,
  };
}

async function getProgress(userId, dateKey) {
  const result = await db.query(
    `SELECT * FROM daily_progress WHERE user_id = $1 AND date_key = $2::date`,
    [userId, dateKey],
  );
  return mapProgress(result.rows[0]);
}

async function listProgress(userId, { from, to } = {}) {
  const params = [userId];
  let where = 'user_id = $1';
  if (from) {
    params.push(from);
    where += ` AND date_key >= $${params.length}::date`;
  }
  if (to) {
    params.push(to);
    where += ` AND date_key <= $${params.length}::date`;
  }
  const result = await db.query(
    `SELECT * FROM daily_progress WHERE ${where} ORDER BY date_key DESC`,
    params,
  );
  return result.rows.map(mapProgress);
}

module.exports = {
  UPLOAD_ROOT,
  saveMealAvif,
  absoluteMealImagePath,
  upsertMealEntry,
  listMealsForUser,
  getMealById,
  upsertDailyProgress,
  getProgress,
  listProgress,
  configPathHint: () => path.resolve(UPLOAD_ROOT),
};
