#!/usr/bin/env bash
set -euo pipefail

# Initialize project structure and configs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
cd "${PROJECT_DIR}"

echo "═══ zknode P4P Setup ═══"
echo ""

# 1. Environment
if [ ! -f .env ]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
fi

# 2. Data directories
echo "Creating data directories..."
mkdir -p \
  data/x0x/identity \
  data/x0x/data \
  data/x0x/dms \
  data/fae/memory \
  data/fae/skills \
  data/chunks \
  data/logs \
  data/antd \
  data/ant \
  data/wikis \
  data/walletshield \
  data/nomadnet \
  data/reticulum

# 3. Check for mixnet configs
if [ ! -d config/mixnet/auth1 ]; then
  echo ""
  echo "NOTE: Mixnet configs not found."
  echo "Generate with: ./scripts/gen-mixnet-configs.sh"
  echo "Or copy from: zknode-autonomi-P4P-node/config/mixnet/"
fi

# 4. Generate x0x identity (if not exists)
if [ ! -f data/x0x/machine.key ]; then
  echo ""
  echo "Generating x0x identity..."
  echo "Run this after docker is available:"
  echo "  docker compose run --rm x0xd --generate-keys --data-dir /var/lib/x0x"
  echo ""
  echo "Or copy existing keys to: data/x0x/"
fi

echo ""
echo "Setup complete."
echo ""
echo "Next steps:"
echo "  1. Ensure mixnet configs are in config/mixnet/"
echo "  2. Generate x0x identity (see above)"
echo "  3. ./scripts/deploy.sh --start"
echo "  4. ./scripts/verify-stack.sh"
