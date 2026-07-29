// Tạo/cập nhật tài khoản admin trên DB production.
//
// Dùng:
//   ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=StrongPass node scripts/seed_admin.js
//   (hoặc đặt trong .env rồi chạy: npm run db:seed-admin)

const bcrypt = require('bcryptjs');
const db = require('../src/config/db');

async function main() {
  const email = (process.env.ADMIN_EMAIL || '').trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD || '';
  const name = process.env.ADMIN_NAME || 'Admin';

  if (!email || !password) {
    console.error('Cần ADMIN_EMAIL và ADMIN_PASSWORD.');
    process.exit(1);
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const result = await db.query(
    `INSERT INTO users (email, password_hash, display_name, auth_provider, role)
     VALUES ($1, $2, $3, 'email', 'admin')
     ON CONFLICT (email) DO UPDATE SET
       password_hash = EXCLUDED.password_hash,
       display_name = EXCLUDED.display_name,
       role = 'admin',
       updated_at = NOW()
     RETURNING id, email, role`,
    [email, passwordHash, name],
  );

  console.log('Admin sẵn sàng:', result.rows[0]);
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed admin thất bại:', err);
  process.exit(1);
});
