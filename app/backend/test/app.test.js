const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../src/app');

const silentLogger = { info() {}, warn() {}, error() {} };

// In-memory stand-in for the database so the tests need no Postgres.
function fakeDb({ healthy = true } = {}) {
  const messages = [];
  return {
    ping: async () => {
      if (!healthy) throw new Error('connection refused');
    },
    listMessages: async () => [...messages].reverse(),
    addMessage: async (text) => {
      const row = { id: messages.length + 1, text, created_at: new Date().toISOString() };
      messages.push(row);
      return row;
    },
  };
}

function start(db) {
  return new Promise((resolve) => {
    const server = createApp({ db, logger: silentLogger, version: 'test' }).listen(0, () => {
      resolve({ server, baseUrl: `http://127.0.0.1:${server.address().port}` });
    });
  });
}

let healthy;
let broken;

before(async () => {
  healthy = await start(fakeDb());
  broken = await start(fakeDb({ healthy: false }));
});

after(() => {
  healthy.server.close();
  broken.server.close();
});

test('GET /api/health returns ok without touching the database', async () => {
  const res = await fetch(`${broken.baseUrl}/api/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: 'ok', version: 'test' });
});

test('GET /api/ready reflects database availability', async () => {
  assert.equal((await fetch(`${healthy.baseUrl}/api/ready`)).status, 200);
  assert.equal((await fetch(`${broken.baseUrl}/api/ready`)).status, 503);
});

test('POST then GET /api/messages round-trips a message', async () => {
  const created = await fetch(`${healthy.baseUrl}/api/messages`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ text: '  hello from CI  ' }),
  });
  assert.equal(created.status, 201);
  assert.equal((await created.json()).text, 'hello from CI');

  const list = await (await fetch(`${healthy.baseUrl}/api/messages`)).json();
  assert.equal(list[0].text, 'hello from CI');
});

test('POST /api/messages rejects invalid input', async () => {
  for (const body of [{}, { text: '' }, { text: 'x'.repeat(281) }, { text: 42 }]) {
    const res = await fetch(`${healthy.baseUrl}/api/messages`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });
    assert.equal(res.status, 400, `expected 400 for ${JSON.stringify(body)}`);
  }
});

test('unknown routes return 404 JSON', async () => {
  const res = await fetch(`${healthy.baseUrl}/api/nope`);
  assert.equal(res.status, 404);
  assert.deepEqual(await res.json(), { error: 'not found' });
});
