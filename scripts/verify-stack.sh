#!/usr/bin/env bash
set -euo pipefail

# Full stack verification script
# Run after deployment to verify every component

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${PROJECT_DIR}"

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  ✓ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ✗ ${name}"
    FAIL=$((FAIL + 1))
  fi
}

echo "═══ zknode P4P Stack Verification ═══"
echo ""

# Container status
echo "── Container Status ──"
docker compose ps --format "table {{.Name}}\t{{.Status}}"

echo ""
echo "── Component Checks ──"

# Mixnet
check "Mixnet dirauth consensus" \
  "docker compose exec mix-client /usr/local/bin/fetch -f /var/lib/katzenpost/client/thinclient.toml 2>/dev/null"

check "Mixnet client connected" \
  "docker compose ps mix-client --format '{{.Status}}' | grep -q Up"

# Proxy
check "mixnet-proxy running" \
  "docker compose ps mixnet-proxy --format '{{.Status}}' | grep -q Up"

# X0X
check "x0xd daemon running" \
  "curl -sf http://127.0.0.1:11700/health"

check "x0x identity exists" \
  "test -f ${X0X_DATA_DIR:-./data/x0x}/machine.key"

check "x0x agent ID available" \
  "curl -sf http://127.0.0.1:11700/agent"

check "x0x network connectivity" \
  "curl -sf http://127.0.0.1:11700/peers"

# FAE
if [ -f "${FAE_DATA_DIR:-./data/fae}/config.toml" ]; then
  check "FAE config present" "true"
else
  echo "  ~ FAE binary not yet available (skipping FAE checks)"
fi

# Storage
check "antd container running" \
  "docker compose ps antd --format '{{.Status}}' | grep -q Up"

check "storage-proved-rs available" \
  "curl -sf http://127.0.0.1:9201/status"

# Dashboard
check "dashboard web UI" \
  "curl -sf http://127.0.0.1:${DASHBOARD_PORT:-8080}"

check "dashboard health API" \
  "curl -sf http://127.0.0.1:${DASHBOARD_PORT:-8080}/api/health"

# Wallet
check "walletshield running" \
  "docker compose ps walletshield --format '{{.Status}}' | grep -q Up"

echo ""
echo "── Results ──"
echo "  Passed: ${PASS}"
echo "  Failed: ${FAIL}"
echo ""

if [ "${FAIL}" -eq 0 ]; then
  echo "✓ ALL CHECKS PASSED"
  exit 0
else
  echo "✗ ${FAIL} CHECK(S) FAILED"
  exit 1
fi
