const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const settingsController = require('../controllers/settings.controller');

const router = express.Router();

router.post('/sync', requireAuth, settingsController.sync);
router.get('/me', requireAuth, settingsController.getMine);

module.exports = router;
