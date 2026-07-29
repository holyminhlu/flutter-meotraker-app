const chatService = require('../services/chat.service');

async function send(req, res, next) {
  try {
    const { messages, contextRange, mode } = req.body || {};
    const result = await chatService.chat(req.user.id, {
      messages,
      contextRange: contextRange || '7d',
      mode,
    });
    res.json({ ok: true, ...result });
  } catch (err) {
    next(err);
  }
}

async function greeting(req, res, next) {
  try {
    const range = req.query.range || '7d';
    const result = await chatService.chat(req.user.id, {
      contextRange: range,
      mode: 'greeting',
    });
    res.json({ ok: true, ...result });
  } catch (err) {
    next(err);
  }
}

module.exports = { send, greeting };
