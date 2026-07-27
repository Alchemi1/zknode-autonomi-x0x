# ZKNetwork P4P Mesh Node — Autonomi × X0X × FAE

**Post-quantum private Autonomi storage node with agent-to-agent networking.**

A self-contained, privacy-hardened decentralized storage node that routes all P2P traffic through a 3-hop post-quantum mixnet. Built for SCM4/CM4 (8GB RAM) or any machine with Docker.

## What's Inside

| Component | What it does |
|-----------|-------------|
| **x0xd** | Agent-to-agent gossip network. Identity, trust, pub/sub, DMs, CRDTs, file transfer |
| **FAE** | On-device AI companion. Wiki search, storage management, mesh health |
| **Katzenpost** | 3-hop post-quantum mixnet. Hides your IP from storage peers (×8 containers) |
| **Autonomi** | Decentralized permanent storage. One-time payment, lifetime storage |
| **Reticulum** | LoRa/packet radio mesh transport. Works without internet |
| **llm-wiki** | Local LLM-powered wiki engine. MCP protocol for agent access |
| **storage-proved** | Winterfell STARK storage proofs. Hardware-attested via ZSCM HSM |
| **zknode-dashboard** | Web UI. Monitor, chat, wiki, wallet, health |

## Quick Start

```bash
git clone <repo> zknode-p4p
cd zknode-p4p
cp .env.example .env
./scripts/deploy.sh --start
```

Then open http://localhost:8080

## Architecture

```
FAE ──REST──▶ x0xd ──SOCKS5──▶ mixnet-proxy ──onion──▶ Katzenpost ──▶ peers
                 │
                 └──REST──▶ antd ──gRPC──▶ ant-node (Autonomi storage)
```

All P2P traffic is anonymized through the mixnet. External peers see only the mixnet exit IP.

## Documentation

| Doc | What |
|-----|------|
| [Integration Plan](INTEGRATION_PLAN.md) | Full architecture and phased plan |
| [X0X Integration](docs/X0X_INTEGRATION.md) | X0X daemon setup and API |
| [FAE Integration](docs/FAE_INTEGRATION.md) | FAE companion setup |
| [P4P Mesh](docs/P4P_MESH.md) | Multi-transport mesh architecture |
| [Verification](docs/VERIFICATION.md) | Post-deploy verification steps |
| [SKILL.md](SKILL.md) | Agent-facing installation skill |

## License

AGPL-3.0 (source) / CC-BY-SA-4.0 (docs)
