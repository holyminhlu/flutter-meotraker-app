const db = require('../config/db');
const AppError = require('../utils/AppError');
const {
  listMealsForUser,
  listProgress,
  getProgress,
} = require('./meal_store.service');
const { getSettings } = require('./settings.service');
const { GoogleGenAI } = require('@google/genai');
const config = require('../config');

async function listUsers() {
  const result = await db.query(
    `SELECT u.id, u.email, u.phone, u.display_name, u.role, u.created_at,
            p.weight_kg, p.height_cm, p.target_weight_kg, p.onboarding_completed,
            p.calorie_target, p.bmi
     FROM users u
     LEFT JOIN user_profiles p ON p.user_id = u.id
     WHERE u.role = 'user'
     ORDER BY u.created_at DESC`,
  );
  return result.rows.map((row) => ({
    id: row.id,
    email: row.email,
    phone: row.phone,
    displayName: row.display_name || 'Người dùng',
    createdAt: row.created_at,
    onboardingCompleted: row.onboarding_completed || false,
    weightKg: row.weight_kg != null ? Number(row.weight_kg) : null,
    heightCm: row.height_cm != null ? Number(row.height_cm) : null,
    targetWeightKg: row.target_weight_kg != null ? Number(row.target_weight_kg) : null,
    calorieTarget: row.calorie_target != null ? Number(row.calorie_target) : null,
    bmi: row.bmi != null ? Number(row.bmi) : null,
  }));
}

async function getUserDetail(userId) {
  const userRes = await db.query(
    `SELECT id, email, phone, display_name, auth_provider, role, created_at
     FROM users WHERE id = $1 AND role = 'user'`,
    [userId],
  );
  if (userRes.rowCount === 0) throw new AppError('Không tìm thấy user', 404);

  const profileRes = await db.query(
    `SELECT * FROM user_profiles WHERE user_id = $1`,
    [userId],
  );
  const dietRes = await db.query(
    `SELECT * FROM user_dietary_preferences WHERE user_id = $1`,
    [userId],
  );
  const appSettings = await getSettings(userId);

  const u = userRes.rows[0];
  const p = profileRes.rows[0];
  const d = dietRes.rows[0];

  return {
    id: u.id,
    email: u.email,
    phone: u.phone,
    displayName: u.display_name || 'Người dùng',
    authProvider: u.auth_provider,
    createdAt: u.created_at,
    profile: p
      ? {
          heightCm: Number(p.height_cm),
          weightKg: Number(p.weight_kg),
          targetWeightKg: Number(p.target_weight_kg),
          age: p.age,
          sex: p.sex,
          activityLevel: p.activity_level,
          bmi: Number(p.bmi),
          bmr: Number(p.bmr),
          tdee: Number(p.tdee),
          calorieTarget: Number(p.calorie_target),
          goalType: p.goal_type,
          onboardingStep: p.onboarding_step,
          onboardingCompleted: p.onboarding_completed,
          updatedAt: p.updated_at,
        }
      : null,
    dietary: d
      ? {
          likedFoods: d.liked_foods || [],
          dislikedFoods: d.disliked_foods || [],
          allergies: d.allergies || [],
          eligibleFoods: d.eligible_foods || [],
          budgetLevel: d.budget_level,
          localFoodNotes: d.local_food_notes,
          updatedAt: d.updated_at,
        }
      : null,
    appSettings: appSettings?.settings || null,
    appSettingsUpdatedAt: appSettings?.updatedAt || null,
  };
}

function rangeToDates(range) {
  const today = new Date();
  const to = today.toISOString().slice(0, 10);
  let days = 1;
  if (range === '7d') days = 7;
  else if (range === '30d') days = 30;
  const fromDate = new Date(today);
  fromDate.setDate(fromDate.getDate() - (days - 1));
  const from = fromDate.toISOString().slice(0, 10);
  return { from, to, days };
}

async function analyzeUserMeals(userId, range = 'today') {
  const { from, to, days } = rangeToDates(range === 'today' ? 'today' : range);
  const meals = await listMealsForUser(userId, { from, to });
  const progress = await listProgress(userId, { from, to });

  const mealLines = meals.map((m) => {
    const foods = (m.foodItems || []).join(', ') || m.description || '(không rõ)';
    return `- ${m.dateKey} ${m.period}: ${foods}` +
      (m.marksCompleted ? ' [đã ghi nhận]' : '') +
      (m.timingStatus ? ` (${m.timingStatus})` : '');
  });

  const progressLines = progress.map((p) => {
    const mealsDone = [
      p.mealBreakfast && 'sáng',
      p.mealLunch && 'trưa',
      p.mealDinner && 'tối',
    ].filter(Boolean).join('/') || 'không';
    const water = (p.waterSlots || []).filter(Boolean).length;
    const exercise = (p.exerciseSlots || []).filter(Boolean).length;
    const sessions = (p.exerciseSessionAwards || []).filter(Boolean).length;
    return `- ${p.dateKey}: bữa ${mealsDone}, nước ${water}/6, VĐ slot ${exercise}/3, phiên tập ${sessions}/3 (+${sessions} điểm VĐ), điểm tổng ${p.points}`;
  });

  let aiText = null;
  if (config.gemini.apiKey && meals.length > 0) {
    try {
      const ai = new GoogleGenAI({ apiKey: config.gemini.apiKey });
      const prompt =
        `Bạn là chuyên gia dinh dưỡng. Phân tích ngắn gọn (tiếng Việt) dữ liệu ăn uống của user trong ${days} ngày gần nhất.\n` +
        `Nêu: (1) tổng quan 3 bữa, (2) điểm mạnh, (3) rủi ro/thiếu chất, (4) gợi ý cải thiện cụ thể.\n` +
        `Dùng bullet ngắn, không dài dòng.\n\n` +
        `Bữa ăn:\n${mealLines.join('\n') || '(chưa có)'}\n\n` +
        `Thử thách:\n${progressLines.join('\n') || '(chưa có)'}`;
      const response = await ai.models.generateContent({
        model: config.gemini.model,
        contents: prompt,
      });
      aiText = response.text || null;
    } catch (err) {
      aiText = `Không gọi được AI phân tích: ${err.message || err}`;
    }
  } else if (meals.length === 0) {
    aiText = 'Chưa có dữ liệu bữa ăn trong khoảng thời gian này.';
  } else {
    aiText = 'Chưa cấu hình GEMINI_API_KEY — chỉ xem dữ liệu thô.';
  }

  const byPeriod = { breakfast: 0, lunch: 0, dinner: 0 };
  for (const m of meals) {
    if (m.marksCompleted || (m.foodItems && m.foodItems.length)) {
      byPeriod[m.period] = (byPeriod[m.period] || 0) + 1;
    }
  }

  return {
    range: range === 'today' ? 'today' : range,
    from,
    to,
    days,
    mealCount: meals.length,
    completedByPeriod: byPeriod,
    meals,
    progress,
    analysis: aiText,
  };
}

module.exports = {
  listUsers,
  getUserDetail,
  analyzeUserMeals,
  getProgress,
  rangeToDates,
};
