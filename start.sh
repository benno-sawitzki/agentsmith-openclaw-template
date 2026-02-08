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

# Register OAuth token (from Claude Pro/Max subscription) if provided.
# This uses OpenClaw's built-in auth profile system instead of ANTHROPIC_API_KEY.
if [ -n "$ANTHROPIC_OAUTH_TOKEN" ]; then
  npx openclaw onboard --auth-choice token --token-provider anthropic \
    --token "$ANTHROPIC_OAUTH_TOKEN" --token-expires-in 365d 2>&1 || true
  echo "✓ Anthropic OAuth token registered"
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
