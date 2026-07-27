# Mixnet Proxy — Root Cause & Fix

## Symptom

mixnet-proxy logs "waiting for gateway…" indefinitely. SOCKS5 proxy at `:1080` never becomes available.

## Architecture

```
mixnet-proxy ──thinclient──▶ kpclientd:64332 ──kpclientd──▶ gateway1:30004 ──▶ mixnet
    │
    └──SOCKS5 :1080──▶ ant-node / x0xd
```

The proxy runs a Katzenpost **thinclient** that connects to **kpclientd** (`mix-client`), which in turn connects to the mixnet **gateway**. The chain must work end-to-end.

## Root Causes

### Cause 1: Stale volume override in docker-compose.yml (PRIMARY)

The mix-client container mounted `/tmp/client.toml.orig` over the actual `client.toml`:

```yaml
volumes:
  - /tmp/client.toml.orig:/var/lib/katzenpost/client/client.toml:ro  # ← REMOVED
```

This host file likely doesn't exist or has stale content. kpclientd reads `client.toml` on startup to find gateway address, pinned keys, Sphinx geometry. Without the correct config, it never connects to the gateway.

**Fix**: Remove the override. The `config/mixnet/client/client.toml` from the repo is correct.

### Cause 2: Stale root authority.toml geometry

The root `config/mixnet/authority.toml` had `PacketLength = 2754` while all actual auth configs (`auth1/2/3/authority.toml`) have `PacketLength = 3082`. This doesn't break anything (each auth uses its own config) but confuses debugging.

**Fix**: Root `config/mixnet/authority.toml` now matches `authN/authority.toml` with `PacketLength = 3082`.

### Cause 3: Tight startup timeout

The original `for i in $(seq 1 30); do ... sleep 2` gave a 60-second window for PKI consensus. On slow hardware (SCM4, SD card), the first PKI epoch can take 2-3 minutes.

**Fix**: Increased to `seq 1 60` with `sleep 5` (300-second window).

## Verification

The Sphinx geometry is **already consistent** across all configs:

| Config File | PacketLength | NrHops | Status |
|------------|-------------|--------|--------|
| auth1/authority.toml | 3082 | 5 | ✓ |
| auth2/authority.toml | 3082 | 5 | ✓ |
| auth3/authority.toml | 3082 | 5 | ✓ |
| mix1/katzenpost.toml | 3082 | 5 | ✓ |
| mix2/katzenpost.toml | 3082 | 5 | ✓ |
| mix3/katzenpost.toml | 3082 | 5 | ✓ |
| gateway1/katzenpost.toml | 3082 | 5 | ✓ |
| servicenode1/katzenpost.toml | 3082 | 5 | ✓ |
| client/client.toml | 3082 | 5 | ✓ |
| proxy/thinclient.toml | 3082 | 5 | ✓ |
| root authority.toml | 3082 | 5 | ✓ (fixed) |

## Post-Fix Verification

```bash
# 1. Check kpclientd has correct config
docker compose exec mix-client cat /var/lib/katzenpost/client/client.toml
# Should show gateway1 at 127.0.0.1:30004, PacketLength=3082

# 2. Check kpclientd is listening
docker compose exec mix-client ss -tlnp | grep 64332
# Should show LISTEN

# 3. Check kpclientd connected to gateway
docker compose logs mix-client --tail 20 | grep -i "gateway\|PKI\|connected"

# 4. Check proxy status
curl -sf http://127.0.0.1:9090/status

# 5. Test SOCKS5 through proxy
curl -sf --proxy socks5://127.0.0.1:1080 http://nyc.x0x.md:5483/health

# 6. Test ant-node through proxy
docker compose exec antd ant node status
```

## If Still Broken

```bash
# Full container logs
docker compose logs mix-client --tail 50
docker compose logs mix-gateway --tail 50
docker compose logs mixnet-proxy --tail 50

# Test kpclientd directly
echo -n "" | nc -w 3 127.0.0.1 64332

# Check gateway is listening
ss -tlnp | grep 30004

# Verify dirauth consensus
curl -sf http://127.0.0.1:30001/health
```
