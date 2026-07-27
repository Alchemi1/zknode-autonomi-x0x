# P4P Mesh Architecture

Peer-for-Peer mesh: each node is a full participant, not a client.

## Three Transport Tiers

| Tier | Technology | Latency | Throughput | Privacy | Use Case |
|------|-----------|---------|-----------|---------|----------|
| 1 | X0X QUIC (direct P2P) | <50ms | 100Mbps | None | High-bandwidth coordination |
| 2 | Katzenpost mixnet | 500ms-2s | 1Mbps | Full (metadata-hiding) | Metadata-private storage |
| 3 | Reticulum (LoRa/packet) | 1s-60s | 10Kbps | Network-level | Offline mesh, censorship |

## Transport Selection

FAE agents choose transport tier based on:

1. **Data sensitivity**: storage traffic → Tier 2 (mixnet)
2. **Peer reachability**: direct QUIC if possible → Tier 1
3. **Network conditions**: offline → Tier 3 (Reticulum)
4. **Bandwidth needs**: large files → Tier 1, then archived via Tier 2

## Node Roles

| Role | Responsibilities |
|------|-----------------|
| **Storage Node** | ant-node, chunk storage, proving |
| **Mix Node** | Katzenpost mix relay |
| **Gateway Node** | Mixnet entry for clients |
| **Mesh Router** | Reticulum transport forwarding |
| **Agent Host** | Runs FAE + x0xd, mesh intelligence |
| **Full Node** | All of the above (zknode default) |

## Discovery

- **X0X FOAF**: Trust graph via friend-of-a-friend queries (3 hops)
- **X0X Gossip**: Presence beacons broadcast over pub/sub
- **Autonomi DHT**: Global node discovery for storage peers
- **Reticulum**: Local mesh discovery via IBSS WiFi / LoRa
- **mDNS**: Local network discovery (X0X ant-quic)
