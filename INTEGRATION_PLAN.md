# ZKNetwork P4P Mesh Node — X0X + FAE + Autonomi Integration

> **Hardware Root of Trust**: All layers anchor to the Zymbit HSM on the SCM4/SEN400 zk-edge node. See [`docs/HARDWARE_ROOT_OF_TRUST.md`](docs/HARDWARE_ROOT_OF_TRUST.md) for the full hardware security model — secure boot, HSM-backed keys, LUKS storage encryption, FPGA-accelerated Sphinx, and hardware attestation chain.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          zknode P4P Mesh Node                            │
│                     Post-Quantum Privacy Mesh + Agent Mesh                │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Agent Layer (X0X + FAE)                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────────┐ │  │
│  │  │ FAE          │  │ X0X Agent    │  │ zknode-dashboard          │ │  │
│  │  │ (AI companion) │  │ (agent_123)  │  │ (Web UI + MCP)            │ │  │
│  │  │ skills: wiki  │  │ identity:   │  │ X0X tab · FAE tab          │ │  │
│  │  │ storage, chat │  │ ML-DSA-65   │  │ Mesh tab · Ant tab        │ │  │
│  │  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────────┘ │  │
│  └─────────┼─────────────────┼───────────────────────┼─────────────────┘  │
│            │                 │                       │                    │
│  ┌─────────▼─────────────────▼───────────────────────▼─────────────────┐  │
│  │                      x0xd (Daemon)                                   │  │
│  │  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────────────┐  │  │
│  │  │ Gossip    │ │ CRDT KV   │ │ Identity │ │ REST API · WS · SSE  │  │  │
│  │  │ Pub/Sub   │ │ + TaskLists│ │ Trust    │ │ :11700               │  │  │
│  │  └─────┬─────┘ └─────┬─────┘ └────┬─────┘ └──────────────────────┘  │  │
│  └────────┼──────────────┼────────────┼────────────────────────────────┘  │
│           │              │            │                                   │
│  ┌────────▼──────────────▼────────────▼────────────────────────────────┐  │
│  │                   Transport Layer                                     │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐ │  │
│  │  │ QUIC P2P        │  │ Katzenpost      │  │ Reticulum            │ │  │
│  │  │ (ant-quic)      │  │ Mixnet          │  │ (LoRa/Packet/WiFi)   │ │  │
│  │  │ NAT traversal   │  │ 3-hop Sphinx    │  │ IBSS mesh            │ │  │
│  │  │ direct P2P      │  │ metadata-hiding │  │ offline mesh         │ │  │
│  │  └────────┬────────┘  └────────┬────────┘  └──────────┬───────────┘ │  │
│  └───────────┼────────────────────┼──────────────────────┼──────────────┘  │
│              │                    │                      │                │
│  ┌───────────▼────────────────────▼──────────────────────▼──────────────┐  │
│  │                     Storage Layer (Autonomi)                          │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────────┐  │  │
│  │  │ ant-node         │  │ antd (daemon)     │  │ storage-proved-rs  │  │  │
│  │  │ P2P storage node │  │ CLI + REST :12000 │  │ Winterfell STARKs  │  │  │
│  │  │ chunks · scratch │  │ SDK bridge        │  │ Merkle proofs      │  │  │
│  │  └────────┬─────────┘  └────────┬─────────┘  └─────────┬──────────┘  │  │
│  │           │                     │                      │             │  │
│  │           └─────────────────────┴──────────────────────┘             │  │
│  │                           LMDB chunk store                           │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │               Security & Hardware Layer                               │  │
│  │  ┌──────────┐  ┌────────────┐  ┌─────────┐  ┌───────────────────┐   │  │
│  │  │ SCM4/CM4 │  │ ZSCM HSM   │  │ USB SSD │  │ LUKS + zymkey     │   │  │
│  │  │ 8GB RAM  │  │ (I2C)      │  │ 1-4TB   │  │ attestation       │   │  │
│  │  └──────────┘  └────────────┘  └─────────┘  └───────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

## Component Stack

| Layer | Component | Role | Crypto |
|-------|-----------|------|--------|
| **Agent** | FAE | On-device AI companion, P4P mesh intelligence | — |
| **Agent** | X0X agent | Agent-to-agent identity, trust, messaging | ML-DSA-65 |
| **Daemon** | x0xd | Gossip, CRDTs, groups, files, exec, REST API | ML-KEM + ML-DSA |
| **Mixnet** | Katzenpost (8 containers) | 3-hop onion routing, metadata privacy | Sphinx + ML-KEM-768 |
| **Mesh** | Reticulum + NomadNet | LoRa/packet radio/wifi mesh transport | — |
| **Storage** | ant-node | Autonomi decentralized storage node | PQC QUIC |
| **Proving** | storage-proved-rs | Winterfell STARK storage proofs | Rescue hash |
| **Dashboard** | zknode-dashboard | Express.js web UI (monitoring, wiki, chat) | — |
| **HSM** | ZSCM/zymkey | Hardware key storage, attestation | ECDSA |

## Data Flows

### X0X Agent-to-Agent (through mixnet)
```
FAE ──REST──▶ x0xd ──QUIC──▶ mixnet-proxy ──SURB──▶ Katzenpost ──▶ peer x0xd
```

### X0X Direct (no mixnet, for mesh peers)
```
FAE ──REST──▶ x0xd ──QUIC──▶ Reticulum ──LoRa/WiFi──▶ peer x0xd
```

### Storage via X0X
```
FAE skill ──REST──▶ x0xd ──REST──▶ antd ──gRPC──▶ ant-node ──P2P──▶ Autonomi
```

### P4P Wiki
```
llm-wiki ──MCP──▶ dashboard ──REST──▶ x0xd ──gossip──▶ peer wikis
                     │
                     └───ant file upload──▶ Autonomi (archive)
```

## Integration Phases

### Phase 1: Foundation (X0X on the node)
- [ ] Containerize x0xd (Dockerfile.x0x)
- [ ] Add x0xd to docker-compose.yml
- [ ] Configure x0x identity (ML-DSA-65 keys)
- [ ] Route x0x gossip through mixnet-proxy
- [ ] REST API health check from dashboard
- [ ] Fix mixnet-proxy (Sphinx geometry alignment)

### Phase 2: Storage Integration
- [ ] X0X storage backend via ant-sdk REST API
- [ ] File transfer: x0x DMs → Autonomi permanent storage
- [ ] CRDT KV stores backed by Autonomi scratchpads
- [ ] Wiki pages as CRDT documents gossiped between nodes

### Phase 3: FAE Agent Layer
- [ ] Containerize FAE (Dockerfile.fae)
- [ ] Connect FAE to x0xd (local REST)
- [ ] FAE skills: wiki search, storage, mesh health
- [ ] Multi-FAE discovery across X0X gossip

### Phase 4: Advanced P4P Mesh
- [ ] Discovery mesh (X0X FOAF trust graph)
- [ ] Coordinated storage proving (CRDT challenge/response)
- [ ] Multi-modal transport (mixnet/Reticulum/direct QUIC)
- [ ] Economic layer (Autonomi wallet via X0X agents)

---

## File Structure

```
autonomi/                        # ← This workspace
├── INTEGRATION_PLAN.md          # This document
├── docker-compose.yml           # Full stack with X0X + FAE
├── .env.example                 # Environment template
│
├── Dockerfile.x0x               # x0xd container
├── Dockerfile.fae               # FAE container
├── Dockerfile.ant-node          # Autonomi storage node
├── Dockerfile.mixnet-proxy      # SOCKS5 bridge (patched)
├── Dockerfile.mixnet            # Katzenpost mixnet node
├── Dockerfile.walletshield      # EVM RPC proxy
├── Dockerfile.storage-proved-rs # Winterfell STARK prover
├── Dockerfile.reticulum         # Reticulum transport
├── Dockerfile.nomadnet          # NomadNet mesh chat/wiki
├── Dockerfile.llm-wiki          # Local LLM wiki proxy
│
├── config/
│   ├── x0x/
│   │   ├── config.toml          # x0xd config
│   │   └── identity/            # ML-DSA-65 keys (generated)
│   ├── fae/
│   │   └── config.toml          # FAE config
│   ├── mixnet/                  # Katzenpost PKI + node configs
│   ├── proxy/                   # mixnet-proxy configs
│   ├── autonomi/                # ant-node + antd configs
│   ├── walletshield/            # EVM proxy config
│   ├── nomadnet/                # NomadNet config
│   ├── llm-wiki/                # LLM wiki config
│   └── reticulum/               # Reticulum config
│
├── cmd/
│   ├── mixnet-proxy/            # SOCKS5 bridge source
│   └── storage-proved-rs/       # Winterfell prover source
│
├── fae-skills/                  # FAE skill definitions
│   ├── wiki-search.md
│   ├── storage-manager.md
│   ├── mesh-health.md
│   └── p4p-coordinator.md
│
├── scripts/
│   ├── deploy.sh                # Full stack deploy
│   ├── setup.sh                 # Init directories + keys
│   ├── gen-x0x-identity.sh      # Generate x0x keys
│   ├── verify-stack.sh          # Health check all services
│   └── test-x0x-roundtrip.sh    # X0X messaging test
│
├── docs/
│   ├── X0X_INTEGRATION.md       # X0X integration details
│   ├── FAE_INTEGRATION.md       # FAE integration details
│   ├── P4P_MESH.md              # P4P mesh architecture
│   ├── MIXNET_PROXY_DEBUG.md    # SOCKS5 bridge troubleshooting
│   └── VERIFICATION.md          # Post-deploy verification
│
├── zknode-dashboard/            # Web UI (with X0X + FAE tabs)
│   ├── server/
│   │   └── index.js
│   └── public/
│       └── index.html
│
├── patches/                     # Katzenpost patches
│   └── fix-decoy-sender-nil-pointer.patch
│
├── SKILL.md                     # Agent-facing integration skill
└── README.md                    # Project root
```

## Key Integration Points

### 1. X0X + Mixnet (Metadata Privacy)
X0X's ant-quic transport can be configured to route through a SOCKS5 proxy. The mixnet-proxy at `:1080` provides this. x0xd connects → mixnet-proxy → Katzenpost → peer. The peer sees the mixnet exit IP, not the node's real IP.

**Config**: `x0xd` environment variable `SOCKS5_PROXY=socks5://127.0.0.1:1080`

### 2. X0X + Autonomi (Storage Backend)
x0x file transfers (DM-based, SHA-256 verified) land in `~/.x0x/transfers/`. A bridge agent (or FAE skill) monitors this directory and uploads to Autonomi via `ant file upload`. Permanent storage with one-time payment.

### 3. X0X + Dashboard (Web UI)
The dashboard talks to x0xd via its REST API (`:11700`). The X0X tab shows: agent identity, connected peers, recent messages, CRDT store state, trust graph.

### 4. X0X + Reticulum (Mesh Transport)
x0xd's QUIC transport can bind to Reticulum's TCP interface (`:4242`). This allows X0X gossip over LoRa/packet radio mesh when IP-based networks are unavailable.

### 5. FAE + Everything (Agent Intelligence)
FAE connects to x0xd locally, giving it x0x's full capabilities. Skills extend FAE to:
- Query llm-wiki for P2P wiki content
- Monitor mixnet health via dashboard API
- Manage Autonomi storage (upload, verify, prove)
- Coordinate with other FAEs across the mesh via X0X CRDTs

## Dependencies

| Service | Depends On | Notes |
|---------|-----------|-------|
| x0xd | mixnet-proxy (for mixed routing), network | Can fall back to direct QUIC |
| FAE | x0xd | Local REST only |
| mixnet-proxy | mix-client | Currently broken (Gap 2) |
| mix-client | mix-gateway | |
| mix-gateway | mix-1/2/3 | |
| mix-1/2/3 | mix-dirauth-1/2/3 | |
| ant-node | mixnet-proxy | SOCKS5 for P2P traffic |
| antd | ant-node | Management daemon |
| storage-proved-rs | ant-node (LMDB access) | |
| zknode-dashboard | All services (via Docker API) | |

## Known Blockers

| Blocker | Impact | Status |
|---------|--------|--------|
| mixnet-proxy "waiting for gateway" | X0X cannot route through mixnet | Needs Sphinx geometry fix |
| Physical SCM4 dead (Supervised Boot) | Cannot test on real hardware | Recovery path documented |
| FAE platform requirements | FAE requires Apple Silicon primary | Check Linux support |
| x0xd not yet containerized | Not available in Docker stack | Phase 1 deliverable |

## Verification

After each phase, run:

```bash
# Phase 1 verification
./scripts/verify-stack.sh          # All containers healthy
x0x health                         # Daemon running
x0x agent                          # Identity created
x0x find                           # Peers discovered

# Phase 2 verification
x0x send-file test.txt <peer>      # File transfer
ant file upload transfers/*        # Permanent storage

# Phase 3 verification
fae status                         # Agent running
fae skill list                     # Skills loaded
fae ask "what is on the mesh?"     # Wiki query

# Phase 4 verification
./scripts/test-mesh-roundtrip.sh   # Full roundtrip
```

## Hardware Root of Trust

All components anchor to the Zymbit HSM on the SCM4/SEN400 zk-edge node. See [`docs/HARDWARE_ROOT_OF_TRUST.md`](docs/HARDWARE_ROOT_OF_TRUST.md) for the full hardware security model:

- **Secure boot**: Bootware verifies every boot artifact. Tamper → key erasure.
- **HSM-backed keys**: Mixnet node keys, X0X ML-DSA-65 machine key, BIP32 wallet seed, LUKS encryption keys — all generated and stored inside the HSM. Private keys never touch CPU memory.
- **Storage encryption**: Chunk DB on LUKS-encrypted USB pool. Key locked to HSM, bound to Device Unique ID.
- **Hardware attestation**: Storage proofs signed by HSM, binding Merkle root to specific hardware.
- **FPGA acceleration** (SEN400): Lattice iCE40 for Sphinx unwrap (<5ms latency) and ML-KEM-768 decapsulation.
```
