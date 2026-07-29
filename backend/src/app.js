const express = require('express');
const cors = require('cors');
const config = require('./config');
const healthRoutes = require('./routes/health.routes');
const authRoutes = require('./routes/auth.routes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

app.use(cors());
app.use(express.json({ limit: '15mb' }));

app.get('/', (_req, res) => {
  res.json({
    name: 'Meo Traker API',
    version: '1.0.0',
    status: 'ok',
  });
});

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/onboarding', require('./routes/onboarding.routes'));
app.use('/api/meals', require('./routes/meal.routes'));
app.use('/api/progress', require('./routes/progress.routes'));
app.use('/api/settings', require('./routes/settings.routes'));
app.use('/api/chat', require('./routes/chat.routes'));
app.use('/api/admin', require('./routes/admin.routes'));

app.use(errorHandler);

module.exports = app;
