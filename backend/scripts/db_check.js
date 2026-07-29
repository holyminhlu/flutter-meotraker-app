// Kiểm tra nhanh kết nối DB: liệt kê bảng + schema_version.
//   node scripts/db_check.js

const db = require('../src/config/db');

async function main() {
  const info = await db.query(
    'SELECT current_database() AS db, current_user AS usr',
  );
  console.log(`Connected: ${info.rows[0].db} as ${info.rows[0].usr}`);

  const tables = await db.query(
    "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY 1",
  );
  console.log('Tables:', tables.rows.map((r) => r.tablename).join(', '));

  const version = await db.query(
    "SELECT value FROM app_meta WHERE key = 'schema_version'",
  );
  console.log('schema_version:', version.rows[0] ? version.rows[0].value : 'n/a');

  process.exit(0);
}

main().catch((err) => {
  console.error('DB check failed:', err.message);
  process.exit(1);
});
