function errorHandler(err, _req, res, _next) {
  const status = err.status || 500;
  if (status >= 500) {
    console.error(err);
  }

  res.status(status).json({
    error: err.message || 'Internal Server Error',
    message: err.message || 'Internal Server Error',
  });
}

module.exports = errorHandler;
