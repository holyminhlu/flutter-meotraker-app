require('dotenv').config();

function parseDatabaseUrl(url) {
  if (!url) return null;
  try {
    const parsed = new URL(url);
    return {
      host: parsed.hostname,
      port: Number(parsed.port) || 5432,
      database: parsed.pathname.replace(/^\//, '') || 'meo_traker',
      user: decodeURIComponent(parsed.username),
      password: decodeURIComponent(parsed.password),
    };
  } catch (_) {
    return null;
  }
}

const fromUrl = parseDatabaseUrl(process.env.DATABASE_URL);

// Bật SSL khi chạy production hoặc khi dịch vụ (Aiven/Render) yêu cầu.
const dbSsl =
  process.env.DB_SSL === 'true' ||
  process.env.NODE_ENV === 'production' ||
  Boolean(process.env.DATABASE_URL);

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  jwt: {
    secret: process.env.JWT_SECRET || 'meo_traker_dev_secret_change_me',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  db: {
    connectionString: process.env.DATABASE_URL || '',
    host: fromUrl?.host || process.env.DB_HOST || 'localhost',
    port: fromUrl?.port || Number(process.env.DB_PORT) || 5432,
    database: fromUrl?.database || process.env.DB_NAME || 'meo_traker',
    user: fromUrl?.user || process.env.DB_USER || 'postgres',
    password: fromUrl?.password || process.env.DB_PASSWORD || '',
    ssl: dbSsl,
  },
  // Thư mục lưu ảnh bữa ăn. Trên Render nên trỏ vào Persistent Disk.
  uploadsDir: process.env.UPLOADS_DIR || '',
  gemini: {
    apiKey: process.env.GEMINI_API_KEY || '',
    model: process.env.GEMINI_MEAL_MODEL || 'gemini-3.5-flash-lite',
  },
  openrouter: {
    apiKey: process.env.OPENROUTER_API_KEY || '',
    model: process.env.OPENROUTER_MODEL || 'xiaomi/mimo-v2.5',
    baseUrl: (process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1').replace(/\/$/, ''),
    siteUrl: process.env.OPENROUTER_SITE_URL || 'https://meo-traker.local',
    siteName: process.env.OPENROUTER_SITE_NAME || 'Meo Traker',
  },
};
