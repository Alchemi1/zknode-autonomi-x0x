# FAE Skill: Storage Manager

Manage Autonomi decentralized storage on the zknode.

## Capabilities

- Upload files to Autonomi (permanent storage)
- Retrieve files by address
- Check storage proving status
- Monitor chunk store health
- Verify storage proofs

## Implementation

Uses `ant` CLI through antd daemon REST API. Storage proofs verified against storage-proved-rs Merkle tree.

```
FAE ──REST──▶ antd:12000 ──ant file upload──▶ Autonomi network
  │
  └──REST──▶ storage-proved-rs:9201 ──/status──▶ merkle root
```

## Commands

- `fae store <file>` — Upload file to Autonomi
- `fae retrieve <address>` — Download file from Autonomi
- `fae prove` — Generate storage proof
- `fae status` — Check storage health
