# Agent Smith — OpenClaw Template

Template repository for deploying OpenClaw AI chatbot instances via Railway from the Agent Smith dashboard.

## How it works

1. Agent Smith provisions a Railway service from this repo
2. Brand intelligence data is pushed as a base64-encoded `SOUL_MD` environment variable
3. `start.sh` decodes it into `workspace/SOUL.md` before starting the OpenClaw gateway
4. The gateway exposes an OpenAI-compatible chat API that Agent Smith proxies to

## Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENCLAW_GATEWAY_TOKEN` | Auth token for the gateway API (auto-generated) |
| `SOUL_MD` | Base64-encoded brand personality document (set via brand sync) |
| `PORT` | Server port (Railway sets this automatically) |
| `TELEGRAM_ENABLED` | Enable Telegram channel (`true`/`false`) |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from @BotFather |
| `WHATSAPP_ENABLED` | Enable WhatsApp channel (`true`/`false`) |

## Local Development

```bash
npm install
export OPENCLAW_GATEWAY_TOKEN=test-token
bash start.sh
```
