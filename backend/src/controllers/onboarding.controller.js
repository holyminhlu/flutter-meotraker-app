const onboardingService = require('../services/onboarding.service');

async function status(req, res, next) {
  try {
    const data = await onboardingService.getStatus(req.user.id);
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function preview(req, res, next) {
  try {
    const data = await onboardingService.previewMetrics(req.body || {});
    res.json(data);
  } catch (err) {
    next(err);
  }
}

async function saveBody(req, res, next) {
  try {
    const metrics = await onboardingService.saveBodyStats(
      req.user.id,
      req.body || {},
    );
    res.json({ metrics });
  } catch (err) {
    next(err);
  }
}

async function saveDietary(req, res, next) {
  try {
    const data = await onboardingService.saveDietary(req.user.id, req.body || {});
    res.json(data);
  } catch (err) {
    next(err);
  }
}

module.exports = { status, preview, saveBody, saveDietary };
