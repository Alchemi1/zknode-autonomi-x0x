#!/usr/bin/env bash
set -euo pipefail

# Generate x0x identity for containerized daemon
# Usage: ./scripts/gen-x0x-identity.sh [data-dir]

DATA_DIR="${1:-./data/x0x}"

echo "Generating x0x identity in ${DATA_DIR}..."

mkdir -p "${DATA_DIR}"
docker compose run --rm -v "${DATA_DIR}:/var/lib/x0x" x0xd --generate-keys

echo "Identity generated:"
echo "  Machine key: ${DATA_DIR}/machine.key"
echo "  Agent key: ${DATA_DIR}/agent.key"
echo ""
echo "Agent ID:"
docker compose run --rm -v "${DATA_DIR}:/var/lib/x0x" x0x agent --data-dir /var/lib/x0x
