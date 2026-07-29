const fs = require('fs');
const path = require('path');
const db = require('../src/config/db');

async function main() {
  const sql = fs.readFileSync(
    path.join(__dirname, '../../database/migrations/005_exercise_session_awards.sql'),
    'utf8',
  );
  await db.query(sql);
  console.log('migration 005 ok');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
