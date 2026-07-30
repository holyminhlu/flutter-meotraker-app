const { GoogleGenAI } = require('@google/genai');
const exifr = require('exifr');
const config = require('../config');
const AppError = require('../utils/AppError');

const MEAL_LABELS = {
  breakfast: 'bữa sáng',
  lunch: 'bữa trưa',
  dinner: 'bữa tối',
};

function getGeminiClient() {
  if (!config.gemini.apiKey) {
    throw new AppError('Chưa cấu hình GEMINI_API_KEY trên máy chủ', 503);
  }
  return new GoogleGenAI({ apiKey: config.gemini.apiKey });
}

function stripDataUrl(base64OrDataUrl) {
  const raw = String(base64OrDataUrl || '');
  const idx = raw.indexOf('base64,');
  return idx >= 0 ? raw.slice(idx + 7) : raw;
}

const MINUTE_MS = 60 * 1000;

/**
 * EXIF lưu giờ treo tường, không kèm múi giờ, và exifr dựng Date theo TZ của
 * tiến trình. Đọc lại bằng getter local rồi hiểu như UTC để có đúng giờ đã ghi
 * trong ảnh, bất kể server chạy ở múi giờ nào.
 */
function wallClockMs(raw) {
  if (raw instanceof Date && !Number.isNaN(raw.getTime())) {
    return Date.UTC(
      raw.getFullYear(),
      raw.getMonth(),
      raw.getDate(),
      raw.getHours(),
      raw.getMinutes(),
      raw.getSeconds(),
    );
  }
  const m = /^(\d{4})[:-](\d{2})[:-](\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?/.exec(
    String(raw || ''),
  );
  if (!m) return null;
  return Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +(m[6] || 0));
}

/** "+07:00" / "-0330" → số phút lệch so với UTC. */
function parseOffsetMinutes(value) {
  if (value == null || value === '') return null;
  if (typeof value === 'number') {
    return Number.isFinite(value) && Math.abs(value) <= 14 * 60 ? value : null;
  }
  const m = /^([+-])(\d{1,2}):?(\d{2})$/.exec(String(value).trim());
  if (!m) return null;
  const mins = Number(m[2]) * 60 + Number(m[3]);
  if (mins > 14 * 60) return null;
  return m[1] === '-' ? -mins : mins;
}

function parseJsonLoose(text) {
  const s = String(text || '').trim();
  try {
    return JSON.parse(s);
  } catch (_) {
    const start = s.indexOf('{');
    const end = s.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return JSON.parse(s.slice(start, end + 1));
    }
    throw new AppError('AI không trả về JSON hợp lệ', 502);
  }
}

/**
 * Đọc EXIF / sidecar từ buffer ảnh (server-side, không tin client).
 */
async function extractMetadata(buffer, mimeType) {
  let exif = {};
  try {
    exif =
      (await exifr.parse(buffer, {
        tiff: true,
        ifd0: true,
        exif: true,
        gps: true,
        xmp: true,
        icc: false,
        iptc: true,
        interop: true,
        translateKeys: true,
        translateValues: true,
        reviveValues: true,
      })) || {};
  } catch (_) {
    exif = {};
  }

  const takenAt =
    exif.DateTimeOriginal ||
    exif.CreateDate ||
    exif.ModifyDate ||
    exif.DateTimeDigitized ||
    null;

  const takenAtWallMs = wallClockMs(takenAt);
  const takenAtIso =
    takenAtWallMs != null ? new Date(takenAtWallMs).toISOString() : null;
  const takenAtOffsetMinutes = parseOffsetMinutes(
    exif.OffsetTimeOriginal || exif.OffsetTime || exif.OffsetTimeDigitized,
  );

  const make = exif.Make || exif.make || null;
  const model = exif.Model || exif.model || null;
  const software = exif.Software || exif.software || null;
  const lens = exif.LensModel || exif.Lens || null;
  const lat = exif.latitude ?? exif.GPSLatitude ?? null;
  const lon = exif.longitude ?? exif.GPSLongitude ?? null;

  const suspiciousSoftware = /photoshop|snapseed|picsart|canva|screenshot|paint|gimp|lightroom/i.test(
    String(software || ''),
  );

  return {
    mimeType: mimeType || null,
    byteSize: buffer.length,
    takenAt: takenAtIso,
    takenAtWallMs,
    takenAtOffsetMinutes,
    deviceMake: make,
    deviceModel: model,
    software,
    lens,
    hasGps: lat != null && lon != null,
    gps:
      lat != null && lon != null
        ? { lat: Number(lat), lon: Number(lon) }
        : null,
    imageWidth: exif.ImageWidth || exif.ExifImageWidth || exif.PixelXDimension || null,
    imageHeight:
      exif.ImageHeight || exif.ExifImageHeight || exif.PixelYDimension || null,
    orientation: exif.Orientation || null,
    hasCameraExif: Boolean(make || model || takenAtIso),
    suspiciousSoftware,
    rawKeys: Object.keys(exif).slice(0, 40),
  };
}

/**
 * Chấm điểm metadata chống ảnh giả / ảnh cũ / ảnh tải mạng.
 */
function scoreMetadata(meta, { mealPeriod, clientNowIso, takenAtMs = null }) {
  const reasons = [];
  let score = 50;
  const now = clientNowIso ? new Date(clientNowIso) : new Date();
  const nowMs = Number.isNaN(now.getTime()) ? Date.now() : now.getTime();

  if (meta.hasCameraExif) {
    score += 15;
    reasons.push('Có EXIF thiết bị/thời gian chụp');
  } else {
    score -= 25;
    reasons.push('Thiếu EXIF camera — dễ là ảnh tải / screenshot');
  }

  if (meta.deviceMake || meta.deviceModel) {
    score += 10;
    reasons.push(
      `Thiết bị: ${[meta.deviceMake, meta.deviceModel].filter(Boolean).join(' ')}`,
    );
  }

  if (meta.suspiciousSoftware) {
    score -= 20;
    reasons.push(`Phần mềm chỉnh sửa đáng ngờ: ${meta.software}`);
  }

  if (takenAtMs != null) {
    const diffH = (nowMs - takenAtMs) / 3600000;
    if (diffH < -1) {
      score -= 30;
      reasons.push('Thời gian chụp ở tương lai');
    } else if (diffH <= 6) {
      score += 20;
      reasons.push('Ảnh chụp trong vòng 6 giờ');
    } else if (diffH <= 24) {
      score += 8;
      reasons.push('Ảnh trong ngày (≤24 giờ)');
    } else if (diffH <= 72) {
      score -= 10;
      reasons.push('Ảnh hơi cũ (1–3 ngày)');
    } else {
      score -= 35;
      reasons.push('Ảnh quá cũ — nghi dùng lại ảnh cũ');
    }
  } else if (meta.takenAt) {
    // Có giờ chụp nhưng không biết múi giờ → đối chiếu sẽ lệch, bỏ qua.
    reasons.push('Có giờ chụp nhưng thiếu múi giờ để đối chiếu');
  } else {
    score -= 15;
    reasons.push('Không đọc được ngày/giờ chụp');
  }

  if (meta.hasGps) {
    score += 5;
    reasons.push('Có tọa độ GPS');
  }

  if (mealPeriod && MEAL_LABELS[mealPeriod]) {
    reasons.push(`Đối chiếu khung ${MEAL_LABELS[mealPeriod]}`);
  }

  score = Math.max(0, Math.min(100, score));
  return { score, reasons };
}

/**
 * Nhận diện thức ăn bằng Gemini (ảnh → JSON).
 * Bắt buộc mô tả món ở mức chung; từ chối ảnh không phải bữa ăn.
 */
async function analyzeWithAi({ buffer, mimeType, mealPeriod, metadata }) {
  const ai = getGeminiClient();
  const b64 = buffer.toString('base64');
  const media = mimeType && mimeType.startsWith('image/') ? mimeType : 'image/jpeg';
  const mealLabel = MEAL_LABELS[mealPeriod] || 'bữa ăn';
  const model = config.gemini.model;

  const prompt = `Bạn là hệ thống XÁC MINH ảnh bữa ăn cho app Meo Traker (tăng cân lành mạnh).
Nhiệm vụ: nhìn ảnh thật kỹ rồi trả về DUY NHẤT một JSON (không markdown, không giải thích ngoài JSON).

Schema bắt buộc:
{
  "isMeal": boolean,
  "containsFood": boolean,
  "confidence": number,
  "description": string,
  "foodItems": string[],
  "looksLikeScreenshotOrStock": boolean,
  "looksLikePackagingOnly": boolean,
  "looksEditedOrFake": boolean,
  "suggestedMealPeriod": "breakfast"|"lunch"|"dinner"|"unknown",
  "notes": string
}

Ngữ cảnh: user đang ghi nhận ${mealLabel}.
Metadata (tham khảo, có thể giả): ${JSON.stringify({
    takenAt: metadata.takenAt,
    deviceMake: metadata.deviceMake,
    deviceModel: metadata.deviceModel,
    software: metadata.software,
  })}

QUY TẮC NGHIÊM NGẶT:
1) isMeal=true và containsFood=true CHỈ khi ảnh rõ ràng có đồ ăn/thức uống có thể ăn được (trên đĩa, bát, tô, khay, bàn ăn...).
2) Nếu KHÔNG phải bữa ăn → isMeal=false, containsFood=false, foodItems=[], confidence thấp.
   Ví dụ PHẢI từ chối: selfie, người, tay, cảnh vật, bàn trống, tường, bàn phím, màn hình, chữ/meme,
   ảnh stock, screenshot, bao bì rỗng, menu giấy không có món thật, đồ vật không ăn được.
3) foodItems: liệt kê món/thành phần ở mức CHUNG tiếng Việt (1–6 mục).
   Đúng kiểu: "cơm", "thịt gà", "canh", "rau", "trứng", "cá", "mì", "sữa", "bánh mì", "trái cây".
   KHÔNG cần tên món quá chi tiết như "gà chiên nước mắm", "phở bò tái chín".
4) description: 1 câu ngắn mô tả bữa (tiếng Việt), ví dụ "Cơm với thịt gà và rau".
5) confidence từ 0 đến 1 — chỉ ≥0.7 khi chắc chắn là đồ ăn thật.`;

  const response = await ai.models.generateContent({
    model,
    contents: [
      {
        inlineData: {
          mimeType: media,
          data: b64,
        },
      },
      { text: prompt },
    ],
    config: {
      temperature: 0.1,
      responseMimeType: 'application/json',
      maxOutputTokens: 1024,
    },
  });

  const text = response.text || '';
  const parsed = parseJsonLoose(text);

  const foodItems = Array.isArray(parsed.foodItems)
    ? parsed.foodItems
        .map((x) => String(x || '').trim())
        .filter(Boolean)
        .slice(0, 8)
    : [];

  return {
    isMeal: Boolean(parsed.isMeal),
    containsFood: Boolean(parsed.containsFood ?? parsed.isMeal),
    confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0)),
    description: String(parsed.description || ''),
    foodItems,
    looksLikeScreenshotOrStock: Boolean(parsed.looksLikeScreenshotOrStock),
    looksLikePackagingOnly: Boolean(parsed.looksLikePackagingOnly),
    looksEditedOrFake: Boolean(parsed.looksEditedOrFake),
    suggestedMealPeriod: parsed.suggestedMealPeriod || 'unknown',
    notes: String(parsed.notes || ''),
    rawModel: model,
  };
}

/**
 * Phân loại khung giờ: on_time | too_early | too_late.
 * Client có thể gửi timingStatus; server đối chiếu lại với cửa sổ.
 */
function resolveTimingStatus({
  clientNowIso,
  windowStartIso,
  windowEndIso,
  timingStatus,
  takenAtMs,
}) {
  const reasons = [];
  let status = timingStatus;
  if (!['on_time', 'too_early', 'too_late'].includes(status)) {
    status = null;
  }

  if (windowStartIso && windowEndIso) {
    const start = new Date(windowStartIso);
    const end = new Date(windowEndIso);
    const now = clientNowIso ? new Date(clientNowIso) : new Date();
    const nowMs = Number.isNaN(now.getTime()) ? Date.now() : now.getTime();
    const skewMs = 2 * 60 * 1000;

    if (!Number.isNaN(start.getTime()) && !Number.isNaN(end.getTime())) {
      if (nowMs + skewMs < start.getTime()) {
        status = 'too_early';
      } else if (nowMs - skewMs > end.getTime()) {
        status = 'too_late';
      } else {
        status = 'on_time';
      }

      if (takenAtMs != null) {
        if (takenAtMs < start.getTime() - skewMs) {
          status = status === 'on_time' ? 'too_early' : status;
          reasons.push('Thời gian chụp sớm hơn khung giờ bữa');
        } else if (takenAtMs > end.getTime() + skewMs) {
          status = status === 'on_time' ? 'too_late' : status;
          reasons.push('Thời gian chụp trễ hơn khung giờ bữa');
        }
      }
    }
  }

  if (!status) status = 'too_late';

  if (status === 'too_early') {
    reasons.push('Ăn quá sớm so với khung giờ bữa');
  } else if (status === 'too_late') {
    reasons.push('Ăn quá trễ so với khung giờ bữa');
  } else {
    reasons.push('Trong khung giờ bữa ăn');
  }

  return { status, reasons, inWindow: status === 'on_time' };
}

function decideFood({ ai, metaScore }) {
  const infoReasons = [...metaScore.reasons];
  const failures = [];
  const foodItems = Array.isArray(ai.foodItems) ? ai.foodItems : [];

  if (!ai.isMeal || !ai.containsFood) {
    failures.push({
      kind: 'not_food',
      message: 'Ảnh không phải thức ăn / bữa ăn',
    });
  } else if (ai.looksLikePackagingOnly) {
    failures.push({
      kind: 'not_food',
      message: 'Ảnh chỉ thấy bao bì, không có đồ ăn',
    });
  } else if (ai.looksLikeScreenshotOrStock) {
    failures.push({
      kind: 'fake',
      message: 'Ảnh nghi là screenshot hoặc ảnh có sẵn, không phải chụp bữa ăn',
    });
  } else if (ai.looksEditedOrFake) {
    failures.push({
      kind: 'fake',
      message: 'Ảnh nghi chỉnh sửa / giả tạo',
    });
  } else if (foodItems.length === 0) {
    failures.push({
      kind: 'not_food',
      message: 'Không nhận diện được món ăn trong ảnh',
    });
  } else if (ai.confidence < 0.65) {
    failures.push({
      kind: 'not_food',
      message: 'AI chưa chắc đây là bữa ăn thật',
    });
  }

  if (metaScore.score < 30) {
    failures.push({
      kind: 'metadata',
      message: 'Thông số ảnh yếu — nghi ảnh tải mạng hoặc thiếu dữ liệu chụp',
    });
  }

  const foodValid = failures.length === 0;

  if (foodValid && foodItems.length > 0) {
    infoReasons.push(`Món nhận diện: ${foodItems.join(', ')}`);
  }
  if (foodValid && ai.description) {
    infoReasons.push(`Mô tả: ${ai.description}`);
  }

  return { foodValid, failures, reasons: infoReasons };
}

/**
 * Chọn đúng 1 lỗi chính để hiện cho user.
 * Ưu tiên: không phải thức ăn / giả → metadata → sai khung giờ.
 */
function pickPrimaryError({ food, timing }) {
  if (food.failures.length > 0) {
    const f = food.failures[0];
    return { kind: f.kind, message: f.message };
  }
  if (timing.status === 'too_early') {
    return {
      kind: 'too_early',
      message: 'Thời gian chụp / gửi ảnh sớm hơn khung giờ bữa ăn',
    };
  }
  if (timing.status === 'too_late') {
    return {
      kind: 'too_late',
      message: 'Thời gian chụp / gửi ảnh trễ hơn khung giờ bữa ăn',
    };
  }
  return null;
}

/**
 * @param {{ imageBase64: string, mimeType?: string, mealPeriod?: string, clientNowIso?: string, windowStartIso?: string, windowEndIso?: string, timingStatus?: string }} input
 */
async function analyzeMealImage(input) {
  const b64 = stripDataUrl(input.imageBase64);
  if (!b64 || b64.length < 100) {
    throw new AppError('Thiếu dữ liệu ảnh', 400);
  }

  let buffer;
  try {
    buffer = Buffer.from(b64, 'base64');
  } catch (_) {
    throw new AppError('Base64 ảnh không hợp lệ', 400);
  }
  if (buffer.length < 100) {
    throw new AppError('Ảnh quá nhỏ hoặc hỏng', 400);
  }
  if (buffer.length > 12 * 1024 * 1024) {
    throw new AppError('Ảnh vượt quá 12MB', 413);
  }

  const mimeType = input.mimeType || 'image/jpeg';
  const metadata = await extractMetadata(buffer, mimeType);

  // Giờ EXIF là giờ treo tường của người dùng. Muốn so với khung giờ (gửi lên
  // dạng UTC) thì phải trừ đi độ lệch múi giờ; không biết độ lệch thì bỏ qua,
  // vì đoán bừa sẽ báo sai "chụp trễ" cho user ngoài UTC.
  const offsetMinutes =
    metadata.takenAtOffsetMinutes ?? parseOffsetMinutes(input.tzOffsetMinutes);
  const takenAtMs =
    metadata.takenAtWallMs != null && offsetMinutes != null
      ? metadata.takenAtWallMs - offsetMinutes * MINUTE_MS
      : null;

  const timing = resolveTimingStatus({
    clientNowIso: input.clientNowIso,
    windowStartIso: input.windowStartIso,
    windowEndIso: input.windowEndIso,
    timingStatus: input.timingStatus,
    takenAtMs,
  });

  const metaScore = scoreMetadata(metadata, {
    mealPeriod: input.mealPeriod,
    clientNowIso: input.clientNowIso,
    takenAtMs,
  });

  let ai;
  try {
    ai = await analyzeWithAi({
      buffer,
      mimeType,
      mealPeriod: input.mealPeriod,
      metadata,
    });
  } catch (err) {
    if (err instanceof AppError) throw err;
    const msg = err?.message || 'Lỗi gọi Gemini AI';
    throw new AppError(`Gemini AI: ${msg}`, 502);
  }

  const food = decideFood({ ai, metaScore });
  const primaryError = pickPrimaryError({ food, timing });
  const marksCompleted = food.foodValid && timing.inWindow;
  const valid = marksCompleted;

  // Chỉ trả về 1 lý do chính khi lỗi; khi thành công giữ info ngắn.
  const reasons = primaryError
    ? [primaryError.message]
    : food.reasons.filter((r) => r.startsWith('Món') || r.startsWith('Mô tả'));

  let summary;
  if (primaryError) {
    summary = primaryError.message;
  } else {
    const items = (ai.foodItems || []).join(', ');
    const dish = ai.description || items || 'bữa ăn';
    summary = `Bữa hợp lệ: ${dish}`;
  }

  return {
    valid,
    foodValid: food.foodValid,
    marksCompleted,
    timingStatus: timing.status,
    primaryError: primaryError?.message || null,
    errorKind: primaryError?.kind || null,
    summary,
    reasons,
    metadata,
    metadataScore: metaScore.score,
    ai,
  };
}

module.exports = {
  analyzeMealImage,
  extractMetadata,
  scoreMetadata,
};
