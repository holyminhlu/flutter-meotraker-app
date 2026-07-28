-- Schema bootstrap for meo_traker
-- Usage:
--   psql -U postgres -d meo_traker -f database/schema.sql

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(120),
  auth_provider VARCHAR(32) NOT NULL DEFAULT 'email',
  role VARCHAR(16) NOT NULL DEFAULT 'user'
    CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT users_email_or_phone CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(128) NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  height_cm NUMERIC(5, 2) NOT NULL,
  weight_kg NUMERIC(5, 2) NOT NULL,
  target_weight_kg NUMERIC(5, 2) NOT NULL,
  age INTEGER NOT NULL,
  sex VARCHAR(16) NOT NULL CHECK (sex IN ('male', 'female', 'other')),
  activity_level VARCHAR(32) NOT NULL CHECK (
    activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')
  ),
  bmi NUMERIC(5, 2) NOT NULL,
  bmr NUMERIC(8, 2) NOT NULL,
  tdee NUMERIC(8, 2) NOT NULL,
  calorie_target NUMERIC(8, 2) NOT NULL,
  goal_type VARCHAR(32) NOT NULL DEFAULT 'gain_weight',
  onboarding_step VARCHAR(32) NOT NULL DEFAULT 'body_stats',
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_dietary_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  liked_foods TEXT[] NOT NULL DEFAULT '{}',
  disliked_foods TEXT[] NOT NULL DEFAULT '{}',
  allergies TEXT[] NOT NULL DEFAULT '{}',
  eligible_foods TEXT[] NOT NULL DEFAULT '{}',
  budget_level VARCHAR(32) NOT NULL DEFAULT 'medium'
    CHECK (budget_level IN ('low', 'medium', 'high')),
  local_food_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_meta (
  key VARCHAR(64) PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS meal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_key DATE NOT NULL,
  period VARCHAR(16) NOT NULL CHECK (period IN ('breakfast', 'lunch', 'dinner')),
  food_items TEXT[] NOT NULL DEFAULT '{}',
  description TEXT,
  advice TEXT,
  timing_status VARCHAR(32),
  marks_completed BOOLEAN NOT NULL DEFAULT FALSE,
  food_valid BOOLEAN NOT NULL DEFAULT FALSE,
  image_path TEXT,
  ai_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, date_key, period)
);

CREATE TABLE IF NOT EXISTS daily_progress (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_key DATE NOT NULL,
  meal_breakfast BOOLEAN NOT NULL DEFAULT FALSE,
  meal_lunch BOOLEAN NOT NULL DEFAULT FALSE,
  meal_dinner BOOLEAN NOT NULL DEFAULT FALSE,
  water_slots BOOLEAN[] NOT NULL DEFAULT ARRAY[false,false,false,false,false,false],
  exercise_slots BOOLEAN[] NOT NULL DEFAULT ARRAY[false,false,false],
  points INTEGER NOT NULL DEFAULT 0,
  streak_days INTEGER NOT NULL DEFAULT 0,
  awarded_meal BOOLEAN NOT NULL DEFAULT FALSE,
  awarded_water BOOLEAN NOT NULL DEFAULT FALSE,
  awarded_exercise BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, date_key)
);

CREATE TABLE IF NOT EXISTS user_app_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO app_meta (key, value)
VALUES ('schema_version', '4')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
