// The API is served from the same origin under /api (ALB path routing in AWS,
// nginx proxy locally), so no CORS configuration is needed.
const $ = (id) => document.getElementById(id);

function setStatus(id, ok, text) {
  const el = $(id);
  el.textContent = text;
  el.className = ok ? 'ok' : 'bad';
}

function showError(message) {
  $('error').textContent = message;
  $('error').hidden = !message;
}

async function checkStatus() {
  try {
    const health = await fetch('/api/health').then((r) => r.json());
    setStatus('api-status', true, 'up');
    $('version').textContent = health.version;
  } catch {
    setStatus('api-status', false, 'down');
  }
  try {
    const ready = await fetch('/api/ready');
    setStatus('db-status', ready.ok, ready.ok ? 'connected' : 'unavailable');
  } catch {
    setStatus('db-status', false, 'unavailable');
  }
}

async function loadMessages() {
  const res = await fetch('/api/messages');
  if (!res.ok) throw new Error(`Failed to load messages (${res.status})`);
  const list = $('messages');
  list.replaceChildren(
    ...(await res.json()).map((m) => {
      const li = document.createElement('li');
      const time = document.createElement('time');
      time.textContent = new Date(m.created_at).toLocaleString();
      li.append(m.text, time);
      return li;
    }),
  );
}

$('message-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const input = $('message-text');
  try {
    const res = await fetch('/api/messages', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ text: input.value }),
    });
    if (!res.ok) throw new Error((await res.json()).error || `Request failed (${res.status})`);
    input.value = '';
    showError('');
    await loadMessages();
  } catch (err) {
    showError(err.message);
  }
});

checkStatus();
loadMessages().catch((err) => showError(err.message));
