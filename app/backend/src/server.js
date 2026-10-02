const { createApp } = require('./app');
const { createDb } = require('./db');
const logger = require('./logger');

const port = Number(process.env.PORT || 3000);
const version = process.env.APP_VERSION || 'dev';

const db = createDb();
const app = createApp({ db, logger, version });

// The API starts even if the database is not reachable yet; the schema is
// applied in the background with retries and /api/ready reports DB status.
async function migrateWithRetry(attempt = 1) {
  try {
    await db.migrate();
    logger.info('database schema ready');
  } catch (err) {
    const delayMs = Math.min(30000, 1000 * 2 ** attempt);
    logger.warn('database migration failed, retrying', { attempt, delay_ms: delayMs, error: err.message });
    setTimeout(() => migrateWithRetry(attempt + 1), delayMs).unref();
  }
}

const server = app.listen(port, () => {
  logger.info('backend listening', { port, version });
  migrateWithRetry();
});

// ECS sends SIGTERM on deployments / scale-in: stop accepting connections,
// drain in-flight requests, then close the DB pool.
function shutdown(signal) {
  logger.info('shutting down', { signal });
  server.close(async () => {
    await db.close().catch(() => {});
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
