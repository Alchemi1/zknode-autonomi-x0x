#!/usr/bin/env bash
set -euo pipefail

# Deploy / stop / check the full zknode P4P stack
# Usage: ./scripts/deploy.sh [--start|--stop|--check|--restart]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${PROJECT_DIR}"

PHASES="mixnet-proxy x0x fae walletshield storage antd mesh dashboard"

check_prereqs() {
  echo "Checking prerequisites..."
  command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found"; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose not found"; exit 1; }

  # Check subnet overlap for bridge networks
  if docker network inspect autonomi >/dev/null 2>&1; then
    echo "  ✓ autonomi network exists"
  fi

  # Check essential config files
  local missing=0
  for f in config/x0x/config.toml config/mixnet/client/thinclient.toml config/proxy/config.json; do
    if [ ! -f "$f" ]; then
      echo "  ✗ Missing config: $f"
      missing=1
    fi
  done
  if [ "$missing" -eq 1 ]; then
    echo "ERROR: Run ./scripts/setup.sh first"
    exit 1
  fi

  echo "  ✓ All configs present"
  echo "Prerequisites OK"
}

do_start() {
  echo "Starting zknode P4P stack (phased)..."
  echo ""

  # Phase 1: Mixnet (dirauths → mixes → gateway → servicenode)
  echo "── Phase 1: Mixnet ──"
  docker compose up -d mix-dirauth-1 mix-dirauth-2 mix-dirauth-3
  echo "  Waiting for dirauth consensus..."
  sleep 10
  docker compose up -d mix-1 mix-2 mix-3 mix-gateway mix-servicenode
  echo "  Waiting for mixnet convergence..."
  sleep 15
  docker compose up -d mix-client
  echo "  Waiting for PKI document..."
  sleep 10

  # Phase 2: Proxy + X0X
  echo "── Phase 2: Proxy + X0X ──"
  docker compose up -d mixnet-proxy
  sleep 5
  docker compose up -d x0xd

  # Phase 3: Storage
  echo "── Phase 3: Storage ──"
  docker compose up -d antd storage-proved-rs

  # Phase 4: Applications
  echo "── Phase 4: Apps ──"
  docker compose up -d walletshield reticulum llm-wiki fae zknode-dashboard

  echo ""
  echo "Stack started. Dashboard: http://localhost:${DASHBOARD_PORT:-8080}"
  echo "X0X API: http://127.0.0.1:${X0X_API_PORT:-11700}/health"
  echo "FAE API: http://127.0.0.1:${FAE_API_PORT:-11780}/health"
}

do_stop() {
  echo "Stopping zknode P4P stack..."
  docker compose down
  echo "Stack stopped."
}

do_check() {
  echo "Checking zknode P4P stack health..."
  docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

  echo ""
  echo "Service health checks:"
  for svc in x0xd fae mixnet-proxy walletshield antd; do
    if docker compose ps "${svc}" --format "{{.Status}}" | grep -q "Up"; then
      echo "  ✓ ${svc} is running"
    else
      echo "  ✗ ${svc} is NOT running"
    fi
  done

  echo ""
  # X0X health
  if curl -sf http://127.0.0.1:${X0X_API_PORT:-11700}/health >/dev/null 2>&1; then
    echo "  ✓ X0X daemon health check passed"
    x0x_peers=$(curl -sf http://127.0.0.1:${X0X_API_PORT:-11700}/peers 2>/dev/null | jq '.peers | length' 2>/dev/null || echo "N/A")
    echo "    x0x peers: ${x0x_peers}"
  else
    echo "  ✗ X0X daemon unreachable"
  fi

  # FAE health
  if curl -sf http://127.0.0.1:${FAE_API_PORT:-11780}/health >/dev/null 2>&1; then
    echo "  ✓ FAE health check passed"
  else
    echo "  ✗ FAE unreachable"
  fi
}

case "${1:---check}" in
  --start|start) do_start ;;
  --stop|stop) do_stop ;;
  --check|check) check_prereqs && do_check ;;
  --restart|restart) do_stop; sleep 3; check_prereqs; do_start ;;
  *)
    echo "Usage: $0 [--start|--stop|--check|--restart]"
    exit 1
    ;;
esac
