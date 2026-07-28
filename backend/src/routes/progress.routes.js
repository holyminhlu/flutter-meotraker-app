const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const progressController = require('../controllers/progress.controller');

const router = express.Router();

router.post('/sync', requireAuth, progressController.sync);

module.exports = router;
