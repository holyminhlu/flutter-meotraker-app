require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function main() {
  const c = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  });
  await c.connect();
  const sql = fs.readFileSync(
    path.join(__dirname, '../../database/migrations/003_admin_meals.sql'),
    'utf8',
  );
  await c.query(sql);
  console.log('migration 003 ok');
  await c.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
