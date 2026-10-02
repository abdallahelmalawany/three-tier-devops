const fs = require('node:fs');
const { Pool } = require('pg');

// RDS enforces TLS (rds.force_ssl = 1). When a CA bundle path is provided the
// server certificate is fully verified against the AWS RDS trust store that is
// baked into the container image.
function sslOptions(env) {
  if (env.DB_SSL !== 'true') return false;
  if (env.DB_SSL_CA_PATH) {
    return { ca: fs.readFileSync(env.DB_SSL_CA_PATH, 'utf8'), rejectUnauthorized: true };
  }
  return { rejectUnauthorized: true };
}

function createDb(env = process.env) {
  const pool = new Pool({
    host: env.DB_HOST,
    port: Number(env.DB_PORT || 5432),
    database: env.DB_NAME,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    ssl: sslOptions(env),
    max: 5,
    connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
  });

  return {
    ping: () => pool.query('SELECT 1'),

    migrate: () =>
      pool.query(`
        CREATE TABLE IF NOT EXISTS messages (
          id         SERIAL PRIMARY KEY,
          text       VARCHAR(280) NOT NULL,
          created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
        )`),

    listMessages: async () => {
      const { rows } = await pool.query(
        'SELECT id, text, created_at FROM messages ORDER BY id DESC LIMIT 20',
      );
      return rows;
    },

    addMessage: async (text) => {
      const { rows } = await pool.query(
        'INSERT INTO messages (text) VALUES ($1) RETURNING id, text, created_at',
        [text],
      );
      return rows[0];
    },

    close: () => pool.end(),
  };
}

module.exports = { createDb };
