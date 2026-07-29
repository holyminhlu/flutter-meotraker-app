const { Pool } = require('pg');
const config = require('./index');

// Aiven/Render yêu cầu TLS. Có DB_CA_CERT thì xác thực đầy đủ;
// nếu không, vẫn mã hóa nhưng bỏ qua kiểm tra CA self-signed của Aiven.
function sslConfig() {
  if (!config.db.ssl) return false;
  if (config.db.caCert) {
    return { ca: config.db.caCert, rejectUnauthorized: true };
  }
  return { rejectUnauthorized: false };
}

const ssl = sslConfig();

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
