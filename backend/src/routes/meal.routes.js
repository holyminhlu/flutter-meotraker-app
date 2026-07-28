const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const mealController = require('../controllers/meal.controller');

const router = express.Router();

router.post('/analyze', requireAuth, mealController.analyze);

module.exports = router;
