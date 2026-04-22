#!/bin/bash
# session-start-test.sh - Tests for the SessionStart hook JSON payload

set -euo pipefail

tmp_payload="$(mktemp)"
trap 'rm -f "$tmp_payload"' EXIT

payload="$(bash hooks/session-start.sh)"
printf '%s' "$payload" > "$tmp_payload"

PAYLOAD_PATH="$tmp_payload" node <<'NODE'
const fs = require('fs');

const payload = JSON.parse(fs.readFileSync(process.env.PAYLOAD_PATH, 'utf8'));

if (payload.priority !== 'IMPORTANT') {
  throw new Error(`expected IMPORTANT priority, got ${payload.priority}`);
}

if (!payload.message.includes('agent-skills loaded.')) {
  throw new Error('message is missing startup preface');
}

if (!payload.message.includes('# Using Agent Skills')) {
  throw new Error('message is missing using-agent-skills content');
}

console.log('session-start JSON payload OK');
NODE
