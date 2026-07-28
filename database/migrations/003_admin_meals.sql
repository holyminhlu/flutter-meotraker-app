-- Admin role, meal photo logs, daily progress sync
-- psql -U postgres -d meo_traker -f database/migrations/003_admin_meals.sql

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS role VARCHAR(16) NOT NULL DEFAULT 'user';

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users
  ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'admin'));

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

CREATE INDEX IF NOT EXISTS idx_meal_entries_user_date
  ON meal_entries (user_id, date_key DESC);

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

-- Admin account (password: Abc#123@)
INSERT INTO users (email, password_hash, display_name, auth_provider, role)
VALUES (
  'meotraker@healthy.meotrinh',
  '$2b$10$z/wRpX0F7SuqpPVux0YoMegSxpThJnD9YhgyeC581g4hgffas2dzy',
  'Admin Meo Traker',
  'email',
  'admin'
)
ON CONFLICT (email) DO UPDATE SET
  password_hash = EXCLUDED.password_hash,
  role = 'admin',
  display_name = EXCLUDED.display_name,
  updated_at = NOW();

INSERT INTO app_meta (key, value)
VALUES ('schema_version', '3')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
