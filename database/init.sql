-- Create database meo_traker (run as postgres superuser)
-- Usage (psql):
--   psql -U postgres -f database/init.sql

SELECT 'CREATE DATABASE meo_traker'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'meo_traker')\gexec
