-- Exercise session awards (1 point per completed timed workout)
-- node backend/scripts/run_005_migration.js

ALTER TABLE daily_progress
  ADD COLUMN IF NOT EXISTS exercise_session_awards BOOLEAN[]
  NOT NULL DEFAULT ARRAY[false,false,false];

UPDATE app_meta
SET value = '5', updated_at = NOW()
WHERE key = 'schema_version';
