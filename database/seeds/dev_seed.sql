-- Optional seed data for local development
-- Usage:
--   psql -U postgres -d meo_traker -f database/seeds/dev_seed.sql

INSERT INTO app_meta (key, value)
VALUES ('seeded_at', NOW()::TEXT)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();
