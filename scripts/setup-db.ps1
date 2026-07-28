# Creates DB meo_traker and applies schema (Windows / psql)
# Usage: .\scripts\setup-db.ps1
# Requires: psql on PATH, password via PGPASSWORD or prompt

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

$env:PGPASSWORD = if ($env:PGPASSWORD) { $env:PGPASSWORD } else { "14102004" }
$DbUser = if ($env:PGUSER) { $env:PGUSER } else { "postgres" }
$DbHost = if ($env:PGHOST) { $env:PGHOST } else { "localhost" }
$DbPort = if ($env:PGPORT) { $env:PGPORT } else { "5432" }

Write-Host "Creating database meo_traker (if missing)..."
$createSql = "SELECT 'CREATE DATABASE meo_traker' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'meo_traker')\gexec"
$createSql | & psql -h $DbHost -p $DbPort -U $DbUser -d postgres -v ON_ERROR_STOP=1

Write-Host "Applying schema..."
& psql -h $DbHost -p $DbPort -U $DbUser -d meo_traker -v ON_ERROR_STOP=1 -f "$Root\database\schema.sql"

Write-Host "Applying seed..."
& psql -h $DbHost -p $DbPort -U $DbUser -d meo_traker -v ON_ERROR_STOP=1 -f "$Root\database\seeds\dev_seed.sql"

Write-Host "Done. Database meo_traker is ready."
