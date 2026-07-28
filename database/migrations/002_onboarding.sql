-- Onboarding + auth extensions for meo_traker
-- Usage:
--   psql -U postgres -d meo_traker -f database/migrations/002_onboarding.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS phone VARCHAR(20) UNIQUE,
  ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(32) NOT NULL DEFAULT 'email';

ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

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

UPDATE app_meta
SET value = '2', updated_at = NOW()
WHERE key = 'schema_version';
