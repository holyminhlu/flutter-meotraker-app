const fs = require('fs');
const path = require('path');
const db = require('./db');

const MIGRATIONS_DIR = path.join(__dirname, '../../../database/migrations');
const SCHEMA_FILE = path.join(__dirname, '../../../database/schema.sql');

async function run() {
  // Base schema (idempotent — dùng IF NOT EXISTS).
  if (fs.existsSync(SCHEMA_FILE)) {
    console.log('Applying schema.sql...');
    await db.query(fs.readFileSync(SCHEMA_FILE, 'utf8'));
  }

  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    console.log(`Applying migration ${file}...`);
    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
    await db.query(sql);
  }

  console.log('All migrations applied.');
  process.exit(0);
}

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
