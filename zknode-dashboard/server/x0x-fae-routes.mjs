// X0X and FAE dashboard routes
// Add to zknode-dashboard/server/index.js after existing routes

// ─── X0X Endpoints ─────────────────────────────────────────────

const X0X_API = `http://127.0.0.1:${process.env.X0X_API_PORT || 11700}`;

async function x0xFetch(path, timeout = 5000) {
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), timeout);
    const r = await fetch(`${X0X_API}${path}`, { signal: ctrl.signal });
    clearTimeout(t);
    if (!r.ok) return { error: `HTTP ${r.status}` };
    return await r.json();
  } catch (e) {
    return { error: e.message };
  }
}

app.get('/api/x0x/health', async (req, res) => {
  const h = await x0xFetch('/health');
  res.json({ running: !h.error, ...h });
});

app.get('/api/x0x/agent', async (req, res) => {
  const a = await x0xFetch('/agent');
  res.json(a);
});

app.get('/api/x0x/peers', async (req, res) => {
  const p = await x0xFetch('/peers');
  res.json(p);
});

app.get('/api/x0x/contacts', async (req, res) => {
  const c = await x0xFetch('/contacts');
  res.json(c);
});

app.get('/api/x0x/diagnostics', async (req, res) => {
  const d = await x0xFetch('/diagnostics/connectivity');
  res.json(d);
});

app.get('/api/x0x/groups', async (req, res) => {
  const g = await x0xFetch('/groups');
  res.json(g);
});

app.get('/api/x0x/stores', async (req, res) => {
  const s = await x0xFetch('/stores');
  res.json(s);
});

app.get('/api/x0x/task-lists', async (req, res) => {
  const t = await x0xFetch('/task-lists');
  res.json(t);
});

// ─── FAE Endpoints ─────────────────────────────────────────────

const FAE_API = `http://127.0.0.1:${process.env.FAE_API_PORT || 11780}`;

async function faeFetch(path, timeout = 5000) {
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), timeout);
    const r = await fetch(`${FAE_API}${path}`, { signal: ctrl.signal });
    clearTimeout(t);
    if (!r.ok) return { error: `HTTP ${r.status}` };
    return await r.json();
  } catch (e) {
    return { error: e.message };
  }
}

app.get('/api/fae/health', async (req, res) => {
  const h = await faeFetch('/health');
  res.json({ running: !h.error, ...h });
});

app.get('/api/fae/status', async (req, res) => {
  const s = await faeFetch('/status');
  res.json(s);
});

app.get('/api/fae/skills', async (req, res) => {
  const s = await faeFetch('/skills');
  res.json(s);
});

app.get('/api/fae/memory', async (req, res) => {
  const m = await faeFetch('/memory/stats');
  res.json(m);
});
