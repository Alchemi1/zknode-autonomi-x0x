---
name: zknode-p4p
description: "ZKNetwork P4P Mesh Node — Post-quantum private Autonomi storage node with X0X agent-to-agent networking and FAE AI companion. Mixnet-anonymized P2P, ZK storage proofs, mesh wiki distribution."
version: 0.1.0
metadata:
  network: "zknode-p4p"
  transport: "katzenpost-mixnet + x0x-gossip + reticulum-mesh"
  storage: "autonomi"
  agent: "x0x + fae"
---

# ZKNetwork P4P Mesh Node

**Any old computer can become a private Autonomi node.**

A self-contained, privacy-hardened decentralized storage node that routes all P2P traffic through a 3-hop post-quantum mixnet. Runs on any device with 8GB RAM + Docker (SCM4, Raspberry Pi, x86_64).

## Stack

| Layer | Component | Purpose | Crypto |
|-------|-----------|---------|--------|
| Agent | FAE | On-device AI companion | — |
| Daemon | x0xd | Agent-to-agent gossip network | ML-DSA-65 + ML-KEM-768 |
| Mixnet | Katzenpost (×8) | 3-hop onion routing | Sphinx + ML-KEM-768 |
| Storage | ant-node (Autonomi) | Permanent decentralized storage | PQC QUIC |
| Proving | storage-proved-rs | Winterfell STARK storage proofs | Rescue hash |
| Mesh | Reticulum + NomadNet | LoRa/packet/WiFi mesh | — |
| Dashboard | zknode-dashboard | Web UI (port 8080) | — |

## Quick Start

### Prerequisites
- Docker Engine 24+ with Compose v2
- 8GB RAM minimum
- aarch64 (ARM) or amd64 (x86_64)

### Deploy

```bash
# 1. Clone and enter workspace
git clone <repo> zknode-p4p
cd zknode-p4p

# 2. Generate configs (if not provided)
cp .env.example .env
./scripts/setup.sh

# 3. Start the stack
./scripts/deploy.sh --start

# 4. Verify
./scripts/verify-stack.sh
```

### Access Dashboard
```
http://<host-ip>:8080
```

## Agent Capabilities

When this skill is loaded, your agent can:

### X0X Agent Network

```bash
# Check identity
curl http://127.0.0.1:11700/agent

# Find peers
curl http://127.0.0.1:11700/peers

# Publish to topic
curl -X POST http://127.0.0.1:11700/publish \
  -H "Content-Type: application/json" \
  -d '{"topic": "zknode-discovery", "payload": "<base64>"}'

# Subscribe to events (SSE)
curl -N http://127.0.0.1:11700/events?topic=zknode-discovery
```

### X0X Direct Messaging

```bash
# Connect to peer agent
curl -X POST http://127.0.0.1:11700/agents/connect \
  -H "Content-Type: application/json" \
  -d '{"agent_id": "<peer_agent_id>"}'

# Send direct message
curl -X POST http://127.0.0.1:11700/direct/send \
  -H "Content-Type: application/json" \
  -d '{"recipient": "<agent_id>", "payload": "<base64_message>"}'

# Receive DMs (SSE)
curl -N http://127.0.0.1:11700/direct/events
```

### CRDT Coordination

```bash
# Create task list
curl -X POST http://127.0.0.1:11700/task-lists \
  -H "Content-Type: application/json" \
  -d '{"name": "mesh-coordination"}'

# Add task
curl -X POST http://127.0.0.1:11700/task-lists/<id>/tasks \
  -H "Content-Type: application/json" \
  -d '{"content": "Prove storage for epoch 240100"}'
```

### File Transfer

```bash
# Send file to peer
curl -X POST http://127.0.0.1:11700/files/send \
  -H "Content-Type: application/json" \
  -d '{"recipient": "<agent_id>", "path": "/path/to/file"}'
```

### Autonomi Storage

```bash
# Upload to permanent storage
docker compose exec antd ant file upload /path/to/file

# Retrieve from storage
docker compose exec antd ant file download <address>

# Check node status
docker compose exec antd ant node status
```

### Storage Proving

```bash
# Get Merkle root
curl http://127.0.0.1:9201/status

# Get challenge
curl http://127.0.0.1:9201/challenge

# Submit proof
curl -X POST http://127.0.0.1:9201/prove \
  -H "Content-Type: application/json" \
  -d '<challenge>'
```

### Wiki Mesh

```bash
# Search wiki
curl "http://127.0.0.1:18765/search?q=decentralized+storage"

# Read page
curl "http://127.0.0.1:18765/read/P2P_Foundation"

# List pages
curl "http://127.0.0.1:18765/list"
```

### Health Monitoring

```bash
# Full health check
curl http://127.0.0.1:8080/api/health

# Mixnet status
curl http://127.0.0.1:8080/api/mixnet

# Ant node status
curl http://127.0.0.1:8080/api/ant

# Mesh status
curl http://127.0.0.1:8080/api/mesh/rns
```

## Service Endpoints (localhost)

| Service | Port | Protocol |
|---------|------|----------|
| x0xd API | 11700 | REST/WS/SSE |
| FAE API | 11780 | REST |
| Mixnet proxy | 1080 | SOCKS5 |
| Mixnet proxy mgmt | 9090 | REST |
| Dashboard | 8080 | HTTP |
| walletshield | 9200 | JSON-RPC |
| storage-proved | 9201 | REST |
| llm-wiki | 18765 | MCP/REST |
| antd | 12000 | gRPC |

## Configuration

Environment variables (`.env`):

| Variable | Default | Description |
|----------|---------|-------------|
| `TARGETARCH` | `arm64` | Target CPU architecture |
| `AUTONOMI_EVM_NETWORK` | `arbitrum-sepolia` | EVM network for payments |
| `X0X_DATA_DIR` | `./data/x0x` | X0X identity and data |
| `FAE_DATA_DIR` | `./data/fae` | FAE memory and config |

## Verification

```bash
# Full stack verification
./scripts/verify-stack.sh

# X0X roundtrip test
./scripts/test-x0x-roundtrip.sh
```

## Architecture

```
                    ┌─────────────────────┐
                    │       FAE           │
                    │  (AI companion)      │
                    └─────────┬───────────┘
                              │ REST
                    ┌─────────▼───────────┐
                    │       x0xd          │
                    │  (agent daemon)     │
                    └─────────┬───────────┘
                              │ SOCKS5
                    ┌─────────▼───────────┐
                    │  mixnet-proxy       │
                    │  (SURB onion wrap)  │
                    └─────────┬───────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
  ┌──────▼──────┐    ┌───────▼───────┐    ┌───────▼──────┐
  │  Katzenpost │    │  ant-node     │    │  Reticulum   │
  │  3-hop mix  │    │  (Autonomi)   │    │  (mesh)      │
  └─────────────┘    └───────────────┘    └──────────────┘
```

## License

AGPL-3.0 (source) / CC-BY-SA-4.0 (docs)
