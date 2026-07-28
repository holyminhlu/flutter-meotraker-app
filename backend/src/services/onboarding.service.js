const db = require('../config/db');
const AppError = require('../utils/AppError');
const { calculateMetrics, bmiCategory } = require('../utils/nutrition');

function toNumber(value, field) {
  const n = Number(value);
  if (!Number.isFinite(n)) {
    throw new AppError(`${field} không hợp lệ`, 400);
  }
  return n;
}

function normalizeList(value) {
  if (!value) return [];
  if (Array.isArray(value)) {
    return value.map((v) => String(v).trim()).filter(Boolean);
  }
  return String(value)
    .split(/[,;\n]/)
    .map((v) => v.trim())
    .filter(Boolean);
}

function mapProfile(row) {
  if (!row) return null;
  return {
    heightCm: Number(row.height_cm),
    weightKg: Number(row.weight_kg),
    targetWeightKg: Number(row.target_weight_kg),
    age: Number(row.age),
    sex: row.sex,
    activityLevel: row.activity_level,
    bmi: Number(row.bmi),
    bmiLabel: bmiCategory(Number(row.bmi)),
    bmr: Number(row.bmr),
    tdee: Number(row.tdee),
    calorieTarget: Number(row.calorie_target),
    goalType: row.goal_type,
    onboardingStep: row.onboarding_step,
    onboardingCompleted: row.onboarding_completed,
  };
}

function mapDiet(row) {
  if (!row) return null;
  return {
    likedFoods: row.liked_foods || [],
    dislikedFoods: row.disliked_foods || [],
    allergies: row.allergies || [],
    eligibleFoods: row.eligible_foods || [],
    budgetLevel: row.budget_level,
    localFoodNotes: row.local_food_notes || '',
  };
}

async function getStatus(userId) {
  const profileResult = await db.query(
    `SELECT * FROM user_profiles WHERE user_id = $1`,
    [userId],
  );
  const dietResult = await db.query(
    `SELECT * FROM user_dietary_preferences WHERE user_id = $1`,
    [userId],
  );

  const profile = mapProfile(profileResult.rows[0]);
  const dietary = mapDiet(dietResult.rows[0]);

  let step = 'body_stats';
  let completed = false;
  if (!profile) step = 'body_stats';
  else if (!dietary) step = 'dietary';
  else {
    step = 'done';
    completed = true;
  }

  return { step, completed, profile, dietary };
}

async function previewMetrics(payload) {
  const heightCm = toNumber(payload.heightCm, 'Chiều cao');
  const weightKg = toNumber(payload.weightKg, 'Cân nặng');
  const targetWeightKg = toNumber(payload.targetWeightKg, 'Cân nặng mục tiêu');
  const age = toNumber(payload.age, 'Tuổi');
  const sex = String(payload.sex || '').toLowerCase();
  const activityLevel = String(payload.activityLevel || '').toLowerCase();

  if (heightCm < 100 || heightCm > 250) {
    throw new AppError('Chiều cao phải từ 100–250 cm', 400);
  }
  if (weightKg < 30 || weightKg > 300) {
    throw new AppError('Cân nặng phải từ 30–300 kg', 400);
  }
  if (targetWeightKg < 30 || targetWeightKg > 300) {
    throw new AppError('Cân nặng mục tiêu phải từ 30–300 kg', 400);
  }
  if (age < 10 || age > 100) {
    throw new AppError('Tuổi phải từ 10–100', 400);
  }
  if (!['male', 'female', 'other'].includes(sex)) {
    throw new AppError('Giới tính không hợp lệ', 400);
  }
  if (
    !['sedentary', 'light', 'moderate', 'active', 'very_active'].includes(
      activityLevel,
    )
  ) {
    throw new AppError('Mức vận động không hợp lệ', 400);
  }

  const metrics = calculateMetrics({
    heightCm,
    weightKg,
    targetWeightKg,
    age,
    sex,
    activityLevel,
  });

  return {
    ...metrics,
    bmiLabel: bmiCategory(metrics.bmi),
    heightCm,
    weightKg,
    targetWeightKg,
    age,
    sex,
    activityLevel,
  };
}

async function saveBodyStats(userId, payload) {
  const preview = await previewMetrics(payload);

  await db.query(
    `INSERT INTO user_profiles (
      user_id, height_cm, weight_kg, target_weight_kg, age, sex, activity_level,
      bmi, bmr, tdee, calorie_target, goal_type, onboarding_step, onboarding_completed, updated_at
    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'dietary', FALSE, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
      height_cm = EXCLUDED.height_cm,
      weight_kg = EXCLUDED.weight_kg,
      target_weight_kg = EXCLUDED.target_weight_kg,
      age = EXCLUDED.age,
      sex = EXCLUDED.sex,
      activity_level = EXCLUDED.activity_level,
      bmi = EXCLUDED.bmi,
      bmr = EXCLUDED.bmr,
      tdee = EXCLUDED.tdee,
      calorie_target = EXCLUDED.calorie_target,
      goal_type = EXCLUDED.goal_type,
      onboarding_step = 'dietary',
      onboarding_completed = FALSE,
      updated_at = NOW()`,
    [
      userId,
      preview.heightCm,
      preview.weightKg,
      preview.targetWeightKg,
      preview.age,
      preview.sex,
      preview.activityLevel,
      preview.bmi,
      preview.bmr,
      preview.tdee,
      preview.calorieTarget,
      preview.goalType,
    ],
  );

  return preview;
}

async function saveDietary(userId, payload) {
  const profile = await db.query(
    `SELECT user_id FROM user_profiles WHERE user_id = $1`,
    [userId],
  );
  if (profile.rowCount === 0) {
    throw new AppError('Hãy hoàn thành thông tin cơ thể trước', 400);
  }

  const likedFoods = normalizeList(payload.likedFoods);
  const dislikedFoods = normalizeList(payload.dislikedFoods);
  const allergies = normalizeList(payload.allergies);
  const eligibleFoods = normalizeList(payload.eligibleFoods);
  const budgetLevel = String(payload.budgetLevel || 'medium').toLowerCase();
  const localFoodNotes = String(payload.localFoodNotes || '').trim();

  if (!['low', 'medium', 'high'].includes(budgetLevel)) {
    throw new AppError('Ngân sách không hợp lệ', 400);
  }

  await db.query(
    `INSERT INTO user_dietary_preferences (
      user_id, liked_foods, disliked_foods, allergies, eligible_foods,
      budget_level, local_food_notes, updated_at
    ) VALUES ($1,$2,$3,$4,$5,$6,$7, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
      liked_foods = EXCLUDED.liked_foods,
      disliked_foods = EXCLUDED.disliked_foods,
      allergies = EXCLUDED.allergies,
      eligible_foods = EXCLUDED.eligible_foods,
      budget_level = EXCLUDED.budget_level,
      local_food_notes = EXCLUDED.local_food_notes,
      updated_at = NOW()`,
    [
      userId,
      likedFoods,
      dislikedFoods,
      allergies,
      eligibleFoods,
      budgetLevel,
      localFoodNotes || null,
    ],
  );

  await db.query(
    `UPDATE user_profiles
     SET onboarding_completed = TRUE, onboarding_step = 'done', updated_at = NOW()
     WHERE user_id = $1`,
    [userId],
  );

  return getStatus(userId);
}

module.exports = {
  getStatus,
  previewMetrics,
  saveBodyStats,
  saveDietary,
};
