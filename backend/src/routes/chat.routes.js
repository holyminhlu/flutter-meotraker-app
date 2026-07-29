const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const chatController = require('../controllers/chat.controller');

const router = express.Router();

router.use(requireAuth);
router.get('/greeting', chatController.greeting);
router.post('/', chatController.send);

module.exports = router;
