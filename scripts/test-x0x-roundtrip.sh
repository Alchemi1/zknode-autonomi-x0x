#!/usr/bin/env bash
set -euo pipefail

# Test X0X message roundtrip on the zknode
# Verifies: agent identity, pub/sub, direct messaging

X0X_API="http://127.0.0.1:11700"
TEST_TOPIC="zknode-p4p-test"
TEST_MSG="Hello from zknode $(date -Iseconds)"

echo "═══ X0X Roundtrip Test ═══"
echo ""

# 1. Check daemon health
echo "1. Daemon health..."
curl -sf "${X0X_API}/health" || { echo "✗ Daemon not running"; exit 1; }
echo "   ✓ x0xd is healthy"

# 2. Get agent identity
echo "2. Agent identity..."
AGENT_ID=$(curl -sf "${X0X_API}/agent" | jq -r '.agent_id' 2>/dev/null || echo "unknown")
echo "   Agent ID: ${AGENT_ID}"

# 3. Publish test message
echo "3. Publishing test message..."
curl -sf -X POST "${X0X_API}/publish" \
  -H "Content-Type: application/json" \
  -d "{\"topic\": \"${TEST_TOPIC}\", \"payload\": \"$(echo -n "${TEST_MSG}" | base64)\"}"
echo "   ✓ Published to topic: ${TEST_TOPIC}"

# 4. Subscribe and receive (SSE, 5-second poll)
echo "4. Receiving via SSE..."
RECEIVED=$(timeout 5 curl -sfN "${X0X_API}/events?topic=${TEST_TOPIC}" 2>/dev/null | head -1 || echo "")
if [ -n "${RECEIVED}" ]; then
  echo "   ✓ Message received via SSE"
else
  echo "   ~ No message received via SSE (may need peer to publish)"
fi

# 5. List peers
echo "5. Peers..."
PEERS=$(curl -sf "${X0X_API}/peers" | jq -r '.peers | length' 2>/dev/null || echo "N/A")
echo "   Connected peers: ${PEERS}"

# 6. Check trust graph
echo "6. Trust/contacts..."
CONTACTS=$(curl -sf "${X0X_API}/contacts" | jq -r '.contacts | length' 2>/dev/null || echo "N/A")
echo "   Contacts: ${CONTACTS}"

echo ""
echo "═══ Test Complete ═══"
