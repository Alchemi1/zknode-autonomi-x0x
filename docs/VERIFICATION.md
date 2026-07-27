# Post-Deployment Verification

## Quick Check

```bash
./scripts/verify-stack.sh
```

## Full Verification Steps

### 1. Container Health

```bash
docker compose ps
# Expected: all services "Up"
```

### 2. Mixnet

```bash
# Check PKI consensus
docker compose logs mix-dirauth-1 | tail -5

# Verify epoch progressing
docker compose exec mix-client /usr/local/bin/fetch -f /var/lib/katzenpost/client/thinclient.toml
```

### 3. X0X Agent Network

```bash
# Health
curl http://127.0.0.1:11700/health

# Identity
curl http://127.0.0.1:11700/agent | jq

# Peers
curl http://127.0.0.1:11700/peers | jq '.peers | length'

# Pub/sub test
./scripts/test-x0x-roundtrip.sh
```

### 4. Autonomi Storage

```bash
# Check ant-node
docker compose exec antd ant node status

# Check chunks
docker compose exec antd ant file list

# Storage proving
curl http://127.0.0.1:9201/status | jq
```

### 5. Mesh

```bash
# Reticulum status
curl http://127.0.0.1:8080/api/mesh/rns

# Wiki search
curl "http://127.0.0.1:18765/search?q=mesh"
```

### 6. Wallet

```bash
# Balance
curl http://127.0.0.1:9200/balance

# ETH RPC
curl -X POST http://127.0.0.1:9200/ethereum \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### 7. Dashboard UI

Open `http://<host>:8080` and verify all tabs load:
- Mixnet (epoch, consensus)
- X0X (agent identity, peers)
- FAE (status, skills)
- Ant (storage, node status)
- Mesh (Reticulum, NomadNet)
- Wiki (page browser, search)
- Wallet (balance, RPC)
