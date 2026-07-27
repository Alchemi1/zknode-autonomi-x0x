# FAE Skill: P4P Coordinator

Coordinate storage proving and mesh discovery across the P4P network.

## Capabilities

- Distribute storage challenges to mesh peers
- Aggregate storage proofs into mesh-wide guarantees
- Trust-based peer discovery (FOAF)
- Multi-transport routing decisions
- Economic deal negotiation

## Implementation

Uses X0X CRDT task lists for challenge/response coordination. Trust graph built from X0X FOAF queries.

```
┌──────────────────────────────────────────────┐
│           P4P Coordinator (via X0X)          │
│                                              │
│  CRDT Task: challenge_{id}                   │
│    ├── Assigned to: peer_{hash}              │
│    ├── Challenge: merkle_index_{n}           │
│    └── Status: pending │ proved              │
│                                              │
│  CRDT KV: trust_graph                        │
│    ├── peer_A → trust_level: known           │
│    └── peer_B → trust_level: trusted         │
└──────────────────────────────────────────────┘
```
