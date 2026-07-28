const express = require('express');
const authController = require('../controllers/auth.controller');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', requireAuth, authController.me);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/oauth/google', authController.oauthGoogle);
router.post('/oauth/apple', authController.oauthApple);

module.exports = router;
