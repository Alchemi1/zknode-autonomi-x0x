# FAE Integration Details

## Status

FAE (Personal AI Companion by Saorsa Labs) is **not yet publicly released** as a standalone binary. This is a forward-looking integration scaffold.

### What's Ready Now
- FAE config template (`config/fae/config.toml`)
- FAE Dockerfile template (`Dockerfile.fae`)
- FAE skills directory with 4 skills (`fae-skills/`)

### What's Needed
- FAE binary from Saorsa Labs (target platforms: macOS/Apple Silicon, Linux arm64/amd64)
- SDK documentation for skill development
- Final configuration schema

## Design

### FAE connects to:
1. **x0xd** (127.0.0.1:11700) — agent mesh, identity, messaging
2. **llm-wiki** (127.0.0.1:18765) — local wiki search via MCP
3. **antd** (127.0.0.1:12000) — Autonomi storage management
4. **zknode-dashboard** (127.0.0.1:8080) — mesh monitoring via API

### FAE exposes:
1. **REST API** (127.0.0.1:11780) — health, status, queries
2. **X0X agent** — FAE appears as an agent on the mesh, reachable by other agents

## Skills

| Skill | File | Purpose |
|-------|------|---------|
| Wiki Search | `fae-skills/wiki-search.md` | Query P2P wiki mesh |
| Storage Manager | `fae-skills/storage-manager.md` | Autonomi storage CRUD |
| Mesh Health | `fae-skills/mesh-health.md` | Monitor full stack |
| P4P Coordinator | `fae-skills/p4p-coordinator.md` | Cross-mesh coordination |

## OTA Path

When the FAE binary becomes available:
1. Add `RUN curl -sfL https://fae.releases.saorsalabs.com/download/fae-${TARGETARCH}.tar.gz` to `Dockerfile.fae`
2. Test against the running stack
3. Publish `zknode-fae:latest` image
