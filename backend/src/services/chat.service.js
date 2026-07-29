const config = require('../config');
const AppError = require('../utils/AppError');
const onboardingService = require('./onboarding.service');
const { getSettings } = require('./settings.service');
const {
  listMealsForUser,
  listProgress,
  getProgress,
} = require('./meal_store.service');
const { rangeToDates } = require('./admin.service');
const db = require('../config/db');

function joinList(list) {
  if (!list || !list.length) return '—';
  return list.join(', ');
}

async function getUserBasics(userId) {
  const result = await db.query(
    `SELECT display_name, email, phone FROM users WHERE id = $1`,
    [userId],
  );
  return result.rows[0] || null;
}

async function buildUserContext(userId, range = '7d') {
  const { from, to } = rangeToDates(range === 'today' ? 'today' : range);
  const today = new Date().toISOString().slice(0, 10);

  const [status, settingsRow, meals, progress, todayProgress, user] =
    await Promise.all([
      onboardingService.getStatus(userId),
      getSettings(userId),
      listMealsForUser(userId, { from, to }),
      listProgress(userId, { from, to }),
      getProgress(userId, today),
      getUserBasics(userId),
    ]);

  return {
    user,
    profile: status.profile,
    dietary: status.dietary,
    appSettings: settingsRow?.settings || null,
    meals,
    progress,
    todayProgress,
    range: { from, to },
    today,
  };
}

function formatContext(ctx) {
  const lines = [];
  const name = ctx.user?.display_name || 'Người dùng';
  lines.push(`Tên: ${name}`);

  const p = ctx.profile;
  if (p) {
    lines.push(
      `Hồ sơ: ${p.heightCm}cm, ${p.weightKg}kg → mục tiêu ${p.targetWeightKg}kg, ` +
        `tuổi ${p.age}, ${p.sex}, vận động ${p.activityLevel}, BMI ${p.bmi} (${p.bmiLabel}), ` +
        `calo mục tiêu ${p.calorieTarget}, mục tiêu ${p.goalType}`,
    );
  } else {
    lines.push('Hồ sơ: chưa hoàn thiện');
  }

  const d = ctx.dietary;
  if (d) {
    lines.push(`Thích: ${joinList(d.likedFoods)}`);
    lines.push(`Ghét: ${joinList(d.dislikedFoods)}`);
    lines.push(`Dị ứng: ${joinList(d.allergies)}`);
    lines.push(`Món đủ điều kiện: ${joinList(d.eligibleFoods)}`);
    lines.push(`Ngân sách: ${d.budgetLevel || '—'}`);
    if (d.localFoodNotes) lines.push(`Ghi chú địa phương: ${d.localFoodNotes}`);
  }

  if (ctx.appSettings) {
    lines.push(`Cài đặt app (JSON): ${JSON.stringify(ctx.appSettings)}`);
  }

  const tp = ctx.todayProgress;
  if (tp) {
    const water = (tp.waterSlots || []).filter(Boolean).length;
    const ex = (tp.exerciseSlots || []).filter(Boolean).length;
    const sessions = (tp.exerciseSessionAwards || []).filter(Boolean).length;
    lines.push(
      `Hôm nay (${ctx.today}): bữa sáng ${tp.mealBreakfast ? '✓' : '✗'}, ` +
        `trưa ${tp.mealLunch ? '✓' : '✗'}, tối ${tp.mealDinner ? '✓' : '✗'}, ` +
        `nước ${water}/6, VĐ slot ${ex}/3, phiên tập ${sessions}/3 (+${sessions} điểm VĐ), ` +
        `điểm ${tp.points}, streak ${tp.streakDays}`,
    );
  }

  if (ctx.meals?.length) {
    lines.push('Bữa ăn gần đây:');
    for (const m of ctx.meals.slice(0, 21)) {
      const foods = joinList(m.foodItems);
      lines.push(
        `- ${m.dateKey} ${m.period}: ${foods}` +
          (m.marksCompleted ? ' [đã ghi nhận]' : '') +
          (m.description ? ` — ${m.description}` : ''),
      );
    }
  } else {
    lines.push('Bữa ăn gần đây: chưa có dữ liệu');
  }

  if (ctx.progress?.length) {
    lines.push('Tiến độ các ngày:');
    for (const row of ctx.progress.slice(0, 14)) {
      const mealsDone = [
        row.mealBreakfast && 'sáng',
        row.mealLunch && 'trưa',
        row.mealDinner && 'tối',
      ]
        .filter(Boolean)
        .join('/') || '0';
      lines.push(
        `- ${row.dateKey}: bữa ${mealsDone}, điểm ${row.points}, streak ${row.streakDays}`,
      );
    }
  }

  return lines.join('\n');
}

function buildSystemPrompt(contextText, mode) {
  const base =
    'Bạn là Meo AI — trợ lý dinh dưỡng thân thiện của app Meo Traker (vùng Trà Vinh / miền Tây). ' +
    'Trả lời bằng tiếng Việt, ngắn gọn, ấm áp, thực tế. ' +
    'Dựa trên dữ liệu user bên dưới để đưa lời khuyên, gợi ý món, nhắc uống nước/vận động, động viên streak. ' +
    'Không bịa dữ liệu không có. Nếu thiếu thông tin thì hỏi nhẹ hoặc gợi ý chung. ' +
    'Không chẩn đoán y khoa. Tôn trọng dị ứng và món user ghét.\n\n' +
    '=== DỮ LIỆU USER ===\n' +
    contextText;

  if (mode === 'greeting') {
    return (
      base +
      '\n\n=== NHIỆM VỤ ===\n' +
      'Viết 1–2 câu chào + lời khuyên/gợi ý cụ thể cho hôm nay (tối đa 120 từ). ' +
      'Không dùng markdown, không bullet.'
    );
  }

  return base;
}

async function callOpenRouter(messages) {
  const apiKey = config.openrouter.apiKey;
  if (!apiKey) {
    throw new AppError(
      'Chưa cấu hình OPENROUTER_API_KEY trên server',
      503,
    );
  }

  const res = await fetch(`${config.openrouter.baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': config.openrouter.siteUrl,
      'X-Title': config.openrouter.siteName,
    },
    body: JSON.stringify({
      model: config.openrouter.model,
      messages,
      temperature: 0.5,
      max_tokens: 800,
    }),
  });

  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg =
      body?.error?.message ||
      body?.error ||
      `OpenRouter lỗi (${res.status})`;
    throw new AppError(String(msg), res.status >= 500 ? 502 : 400);
  }

  const reply = body?.choices?.[0]?.message?.content?.trim();
  if (!reply) {
    throw new AppError('AI không trả lời', 502);
  }

  return {
    reply,
    model: body?.model || config.openrouter.model,
  };
}

async function chat(userId, { messages = [], contextRange = '7d', mode } = {}) {
  const ctx = await buildUserContext(userId, contextRange);
  const contextText = formatContext(ctx);
  const systemPrompt = buildSystemPrompt(contextText, mode);

  const apiMessages = [{ role: 'system', content: systemPrompt }];

  if (mode === 'greeting') {
    apiMessages.push({
      role: 'user',
      content: 'Hãy gửi lời chào và gợi ý hôm nay cho tôi.',
    });
  } else {
    for (const m of messages) {
      const role = m.role === 'assistant' ? 'assistant' : 'user';
      const content = String(m.content || '').trim();
      if (!content) continue;
      apiMessages.push({ role, content });
    }
    if (apiMessages.length === 1) {
      throw new AppError('messages không được rỗng', 400);
    }
  }

  const result = await callOpenRouter(apiMessages);

  return {
    reply: result.reply,
    model: result.model,
    contextUsed: {
      range: contextRange,
      mealCount: ctx.meals?.length || 0,
      hasProfile: Boolean(ctx.profile),
      hasDietary: Boolean(ctx.dietary),
      today: ctx.today,
    },
  };
}

module.exports = {
  chat,
  buildUserContext,
};
