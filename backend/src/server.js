const app = require('./app');
const config = require('./config');
const db = require('./config/db');

async function start() {
  try {
    await db.query('SELECT 1');
    console.log(`Connected to PostgreSQL database "${config.db.database}"`);
  } catch (err) {
    console.error('Failed to connect to PostgreSQL:', err.message);
    console.error('Check backend/.env and ensure database meo_traker exists.');
    process.exit(1);
  }

  app.listen(config.port, () => {
    console.log(`Meo Traker API running on http://localhost:${config.port}`);
    console.log(`Environment: ${config.nodeEnv}`);
  });
}

start();
