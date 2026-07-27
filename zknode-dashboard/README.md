# Dashboard Integration

To add X0X and FAE tabs to the existing zknode-dashboard:

## Server (index.js)

Add the contents of `server/x0x-fae-routes.mjs` after the existing routes (before `app.get('*', ...)`). This adds:

- `GET /api/x0x/health` — X0X daemon health
- `GET /api/x0x/agent` — Agent identity
- `GET /api/x0x/peers` — Connected peers
- `GET /api/x0x/contacts` — Contact/trust list
- `GET /api/x0x/diagnostics` — Connectivity diagnostics
- `GET /api/x0x/groups` — Named groups
- `GET /api/x0x/stores` — KV stores
- `GET /api/x0x/task-lists` — CRDT task lists
- `GET /api/fae/health` — FAE daemon health
- `GET /api/fae/status` — FAE status
- `GET /api/fae/skills` — FAE skills list
- `GET /api/fae/memory` — Memory stats

## Frontend (public/index.html)

Add the sidebar buttons and tab panes from `public/x0x-fae-tabs.html`:

1. **Sidebar**: Add two buttons to `sidebar-nav` (after MESH NET):
   - `X0X NET` (icon ⊕)
   - `FAE` (icon ◆)

2. **Tab panes**: Add `#tab-x0x` and `#tab-fae` divs inside `#tabContent`

3. **JS polling**: Add x0x/fae polling to the existing refresh loop:
   ```js
   // Inside existing poll interval
   fetchX0xStatus();
   fetchFaeStatus();
   ```

## JS Functions to Add

```js
async function fetchX0xStatus() {
  const [health, agent, peers, contacts, diagnostics] = await Promise.all([
    fetch('/api/x0x/health').then(r => r.json()),
    fetch('/api/x0x/agent').then(r => r.json()),
    fetch('/api/x0x/peers').then(r => r.json()),
    fetch('/api/x0x/contacts').then(r => r.json()),
    fetch('/api/x0x/diagnostics').then(r => r.json())
  ]);
  // Update DOM...
}

async function fetchFaeStatus() {
  const [health, status, skills] = await Promise.all([
    fetch('/api/fae/health').then(r => r.json()),
    fetch('/api/fae/status').then(r => r.json()),
    fetch('/api/fae/skills').then(r => r.json())
  ]);
  // Update DOM...
}
```
