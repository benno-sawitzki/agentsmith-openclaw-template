#!/bin/bash
set -e

# Decode brand data from env var into SOUL.md
if [ -n "$SOUL_MD" ]; then
  echo "$SOUL_MD" | base64 -d > workspace/SOUL.md
  echo "✓ SOUL.md written ($(wc -c < workspace/SOUL.md) bytes)"
else
  echo "⚠ No SOUL_MD env var set — using placeholder"
fi

# Start the OpenClaw gateway
npx openclaw start
