const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const requireAdmin = require('../middleware/requireAdmin');
const adminController = require('../controllers/admin.controller');

const router = express.Router();

router.use(requireAuth, requireAdmin);

router.get('/users', adminController.listUsers);
router.get('/users/:userId', adminController.getUser);
router.get('/users/:userId/meals', adminController.getUserMeals);
router.get('/users/:userId/analysis', adminController.getUserAnalysis);
router.get('/users/:userId/meals/:mealId/image', adminController.getMealImage);

module.exports = router;
