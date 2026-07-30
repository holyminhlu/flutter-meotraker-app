const AppError = require('../utils/AppError');
const { analyzeMealImage } = require('../services/meal_analysis.service');
const mealStore = require('../services/meal_store.service');

/** Ngày ghi nhận theo lịch của người dùng, không theo UTC của server. */
function dateKeyFromIso(iso, tzOffsetMinutes) {
  const d = iso ? new Date(iso) : new Date();
  const base = Number.isNaN(d.getTime()) ? new Date() : d;
  const offset = Number.isFinite(Number(tzOffsetMinutes))
    ? Number(tzOffsetMinutes)
    : 0;
  const shifted = new Date(base.getTime() + offset * 60 * 1000);
  return shifted.toISOString().slice(0, 10);
}

function buildSimpleAdvice(foodItems, description) {
  const joined = `${(foodItems || []).join(' ')} ${description || ''}`.toLowerCase();
  const tips = [];
  if (!/(thịt|gà|cá|trứng|tôm|đậu|sữa)/.test(joined)) {
    tips.push('Bữa hơi thiếu đạm — bổ sung trứng hoặc sữa đậu.');
  } else {
    tips.push('Có nguồn đạm tốt.');
  }
  if (!/(rau|cải|salad|trái|chuối|cam)/.test(joined)) {
    tips.push('Thiếu rau/trái cây — thêm vào bữa kế.');
  }
  return tips.slice(0, 2).join(' ');
}

async function analyze(req, res, next) {
  try {
    const {
      imageBase64,
      mimeType,
      mealPeriod,
      clientNowIso,
      windowStartIso,
      windowEndIso,
      timingStatus,
      tzOffsetMinutes,
    } = req.body || {};
    if (!imageBase64) {
      throw new AppError('imageBase64 là bắt buộc', 400);
    }

    const dateKey = dateKeyFromIso(clientNowIso, tzOffsetMinutes);

    const raw = Buffer.from(
      String(imageBase64).replace(/^data:[^;]+;base64,/, ''),
      'base64',
    );
    const result = await analyzeMealImage({
      imageBase64,
      mimeType,
      mealPeriod,
      clientNowIso,
      windowStartIso,
      windowEndIso,
      timingStatus,
      tzOffsetMinutes,
    });

    let savedMeal = null;
    const foodItems = Array.isArray(result.ai?.foodItems)
      ? result.ai.foodItems
      : [];
    const description = result.ai?.description || null;
    const shouldStore =
      result.foodValid ||
      foodItems.length > 0 ||
      (description && String(description).trim());

    if (shouldStore && mealPeriod) {
      let imagePath = null;
      try {
        imagePath = await mealStore.saveMealAvif({
          userId: req.user.id,
          dateKey,
          period: mealPeriod,
          imageBuffer: raw,
        });
      } catch (imgErr) {
        console.warn('saveMealAvif failed:', imgErr.message || imgErr);
      }

      const advice = buildSimpleAdvice(foodItems, description);
      savedMeal = await mealStore.upsertMealEntry({
        userId: req.user.id,
        dateKey,
        period: mealPeriod,
        foodItems,
        description,
        advice,
        timingStatus: result.timingStatus || timingStatus || null,
        marksCompleted: Boolean(result.marksCompleted),
        foodValid: Boolean(result.foodValid),
        imagePath,
        aiSummary: result.summary || null,
      });
    }

    res.json({ ok: true, ...result, mealEntryId: savedMeal?.id || null });
  } catch (err) {
    next(err);
  }
}

module.exports = { analyze };
