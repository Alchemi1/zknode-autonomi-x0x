# X0X Integration Details

## Architecture

The x0xd daemon runs as a Docker container alongside the existing zknode stack. It connects to:

1. **Local REST API** (127.0.0.1:11700) — zknode-dashboard, FAE, and any local app talk to x0xd
2. **mixnet-proxy** (SOCKS5 :1080) — all outbound P2P traffic is routed through Katzenpost for metadata privacy
3. **Global bootstrap nodes** — initial peer discovery via 6 global bootstrap nodes (nyc, sfo, helsinki, nuremberg, singapore, sydney)

## Container Setup

```
Service: x0xd
Image: zknode-x0xd:latest (multi-arch: arm64, amd64)
Build: Dockerfile.x0x
Runtime: x0xd --config /etc/x0x/config.toml
API: 127.0.0.1:11700
Ports: 5483/udp (QUIC P2P, host network)
```

## Identity

Generated on first start in `/var/lib/x0x/`:
- `machine.key` — ML-DSA-65 keypair, hardware-pinned
- `agent.key` — ML-DSA-65 keypair, portable identity

Can be pre-generated with `./scripts/gen-x0x-identity.sh` for deterministic identity.

## Configuration

Two config profiles in `config/x0x/`:
- `config.toml` — Standard config with SOCKS5 proxy for mixnet routing
- `mixnet-config.toml` — Alternate config with explicit transport settings

## REST API (Key Endpoints)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Daemon health |
| `/agent` | GET | Agent identity |
| `/peers` | GET | Connected peers |
| `/publish` | POST | Gossip pub/sub |
| `/subscribe` | POST | Subscribe to topic |
| `/events` | GET | SSE event stream |
| `/contacts` | GET | Contact list |
| `/contacts/trust` | PUT | Set trust level |
| `/direct/send` | POST | Direct message |
| `/direct/events` | GET | DM SSE stream |
| `/task-lists` | GET/POST | CRDT task lists |
| `/stores` | GET/POST | CRDT KV stores |
| `/groups` | GET/POST | Named groups |
| `/files/send` | POST | File transfer |
| `/exec/run` | POST | Remote exec |

## Troubleshooting

### x0xd won't start
```bash
docker logs x0xd
# Check if ports are free (5483, 11700)
ss -tlnp | grep -E '5483|11700'
```

### No peers discovered
```bash
# Check bootstrap connectivity
docker compose exec x0xd x0x network

# Check if mixnet-proxy is accepting connections
curl -sf http://127.0.0.1:9090/status

# Check SOCKS5 proxy
curl -sf --proxy socks5://127.0.0.1:1080 http://nyc.x0x.md:5483/health
```

### Identity lost after restart
```bash
# Check data directory persistence
ls -la data/x0x/
# Should contain: machine.key, agent.key, api.port, api-token
```
