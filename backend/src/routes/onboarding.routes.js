const express = require('express');
const requireAuth = require('../middleware/requireAuth');
const onboardingController = require('../controllers/onboarding.controller');

const router = express.Router();

router.use(requireAuth);
router.get('/status', onboardingController.status);
router.post('/preview', onboardingController.preview);
router.post('/body-stats', onboardingController.saveBody);
router.post('/dietary', onboardingController.saveDietary);

module.exports = router;
