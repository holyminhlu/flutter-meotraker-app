const { Pool } = require('pg');
const config = require('./index');

// Aiven/Render yêu cầu TLS. rejectUnauthorized:false chấp nhận CA managed
// mà không cần tải file ca.pem; đủ an toàn cho kết nối mã hóa.
const ssl = config.db.ssl ? { rejectUnauthorized: false } : false;

const pool = config.db.connectionString
    ? new Pool({
        connectionString: config.db.connectionString,
        ssl,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
      })
    : new Pool({
        host: config.db.host,
        port: config.db.port,
        database: config.db.database,
        user: config.db.user,
        password: config.db.password,
        ssl,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
      });

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error', err);
  process.exit(-1);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
