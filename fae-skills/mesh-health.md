# FAE Skill: Mesh Health Monitor

Monitor the full zknode P4P mesh stack.

## Capabilities

- Check mixnet PKI consensus
- List x0x peers and trust levels
- Monitor ant-node DHT connections
- Check Reticulum transport status
- Verify storage proving service
- Report overall health score

## Implementation

Polls all service endpoints and aggregates into a health summary. Distributes health status via X0X gossip to other nodes.

```
FAE ──REST──▶ zknode-dashboard:8080/api/health
  │
  ├──x0x──▶ peers (distribute health)
  │
  └──CRDT──▶ shared health state
```

## Health Score

- Mixnet consensus: 25%
- x0x peers connected: 25%
- ant-node DHT peers: 25%
- Storage proving active: 25%
