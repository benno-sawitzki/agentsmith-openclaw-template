#!/bin/bash
set -e

# Default internal port for OpenClaw gateway
export OPENCLAW_PORT="${OPENCLAW_PORT:-4000}"

# Decode brand data from env var into SOUL.md
if [ -n "$SOUL_MD" ]; then
  echo "$SOUL_MD" | base64 -d > workspace/SOUL.md
  echo "✓ SOUL.md written ($(wc -c < workspace/SOUL.md) bytes)"
else
  echo "⚠ No SOUL_MD env var set — using placeholder"
fi

# Start OpenClaw gateway in the background (on internal port)
npx openclaw start &
OPENCLAW_PID=$!

# Give OpenClaw a moment to bind its port
sleep 2

# Start the proxy (serves /api/workspace-files + proxies everything else)
node proxy.js &
PROXY_PID=$!

echo "✓ OpenClaw on :$OPENCLAW_PORT, proxy on :${PORT:-3000}"

# Wait for either process to exit
wait -n $OPENCLAW_PID $PROXY_PID
