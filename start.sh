#!/bin/bash
set -e

# Write config from env var if present (pushed by Agent Smith brand sync).
# This enables HTTP chatCompletions and sets the gateway port/auth.
if [ -n "$OPENCLAW_CONFIG_JSON" ]; then
  echo "$OPENCLAW_CONFIG_JSON" > openclaw.json
  echo "✓ openclaw.json written from OPENCLAW_CONFIG_JSON"
fi

# Decode brand data from env var into SOUL.md
if [ -n "$SOUL_MD" ]; then
  echo "$SOUL_MD" | base64 -d > workspace/SOUL.md
  echo "✓ SOUL.md written ($(wc -c < workspace/SOUL.md) bytes)"
else
  echo "⚠ No SOUL_MD env var set — using placeholder"
fi

# When OPENCLAW_CONFIG_JSON is set, OpenClaw listens directly on PORT
# (no proxy needed — Agent Smith reads workspace files via Railway env vars).
# Otherwise, fall back to the legacy proxy setup.
if [ -n "$OPENCLAW_CONFIG_JSON" ]; then
  echo "✓ Direct mode: OpenClaw on :${PORT:-3000}"
  exec npx openclaw start
else
  export OPENCLAW_PORT="${OPENCLAW_PORT:-4000}"

  npx openclaw start &
  OPENCLAW_PID=$!

  sleep 2

  node proxy.js &
  PROXY_PID=$!

  echo "✓ OpenClaw on :$OPENCLAW_PORT, proxy on :${PORT:-3000}"
  wait -n $OPENCLAW_PID $PROXY_PID
fi
