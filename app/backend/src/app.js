const express = require('express');
const defaultLogger = require('./logger');

const MAX_MESSAGE_LENGTH = 280;

function createApp({ db, logger = defaultLogger, version = 'dev' }) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '10kb' }));

  // Access log (health checks are skipped to keep the log signal useful).
  app.use((req, res, next) => {
    if (req.path === '/api/health') return next();
    const started = process.hrtime.bigint();
    res.on('finish', () => {
      logger.info('request', {
        method: req.method,
        path: req.path,
        status: res.statusCode,
        duration_ms: Number(process.hrtime.bigint() - started) / 1e6,
      });
    });
    return next();
  });

  // Liveness: used by the ALB target group. Does not touch the database so a
  // DB blip does not make ECS kill otherwise healthy containers.
  app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', version });
  });

  // Readiness: verifies the database dependency.
  app.get('/api/ready', async (req, res) => {
    try {
      await db.ping();
      res.json({ status: 'ready', database: 'ok' });
    } catch (err) {
      logger.error('database not reachable', { error: err.message });
      res.status(503).json({ status: 'unavailable', database: 'error' });
    }
  });

  app.get('/api/messages', async (req, res) => {
    res.json(await db.listMessages());
  });

  app.post('/api/messages', async (req, res) => {
    const text = typeof req.body?.text === 'string' ? req.body.text.trim() : '';
    if (!text || text.length > MAX_MESSAGE_LENGTH) {
      return res
        .status(400)
        .json({ error: `text must be a non-empty string of at most ${MAX_MESSAGE_LENGTH} characters` });
    }
    return res.status(201).json(await db.addMessage(text));
  });

  app.use((req, res) => {
    res.status(404).json({ error: 'not found' });
  });

  // Express 5 forwards rejected promises from async handlers here.
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({ error: 'invalid JSON body' });
    }
    logger.error('unhandled error', { path: req.path, error: err.message });
    return res.status(500).json({ error: 'internal server error' });
  });

  return app;
}

module.exports = { createApp };
