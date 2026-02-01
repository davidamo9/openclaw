# OpenClaw on DigitalOcean

Deploy your forked OpenClaw instance on a DigitalOcean droplet with full control.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              DigitalOcean Droplet (s-2vcpu-4gb, $24/mo)         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Docker Container                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │   │
│  │  │   Gateway   │  │    Agent    │  │  Custom Skills  │  │   │
│  │  │  (18789)    │  │ (Claude/GPT)│  │  (SecondBrain)  │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  Access: SSH + Tailscale     │ Authenticated API                 │
└──────────────────────────────┼──────────────────────────────────┘
                               │
                               ▼
               SecondBrain Backend (Railway)
```

## Quick Start

### 1. Create Droplet

- **Image**: Docker on Ubuntu 22.04 (1-Click)
- **Size**: s-2vcpu-4gb ($24/mo)
- **Region**: Choose closest
- **Auth**: SSH key (required)

### 2. Initial Setup

```bash
# SSH as root
ssh root@<droplet-ip>

# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/davidamo9/openclaw/main/deploy/digitalocean/setup-droplet.sh | bash
```

### 3. Connect Tailscale

```bash
tailscale up
tailscale ip -4  # Note this IP for future SSH
```

### 4. Deploy OpenClaw

```bash
# Switch to openclaw user
su - openclaw

# Clone your fork
git clone git@github.com:davidamo9/openclaw.git
cd openclaw/deploy/digitalocean

# Configure
cp .env.example .env
nano .env  # Add your API keys

# Deploy
./deploy.sh
```

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Production container configuration |
| `.env.example` | Environment template |
| `openclaw.json` | OpenClaw configuration |
| `setup-droplet.sh` | Initial droplet security hardening |
| `deploy.sh` | Build and deploy container |
| `update.sh` | Pull latest and rebuild |
| `sync-upstream.sh` | Sync fork with openclaw/openclaw |

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Claude API key |
| `OPENAI_API_KEY` | OpenAI API key (fallback) |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token |
| `OPENCLAW_GATEWAY_TOKEN` | Gateway auth token |
| `SECONDBRAIN_API_KEY` | SecondBrain API key |
| `SECONDBRAIN_BASE_URL` | SecondBrain backend URL |

### Model Configuration

Edit `openclaw.json` to customize:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-5",
        "fallback": "openai/gpt-4o"
      }
    }
  }
}
```

## Management Commands

```bash
# View logs
docker compose logs -f openclaw-gateway

# Restart
docker compose restart openclaw-gateway

# Health check
curl http://localhost:18789/health

# Update from fork
./update.sh

# Sync with upstream
./sync-upstream.sh

# Run onboarding
docker compose exec openclaw-gateway node dist/index.js onboard

# Check status
docker compose exec openclaw-gateway node dist/index.js channels status
```

## Security

- **SSH**: Key-only auth, root disabled
- **Firewall**: UFW with SSH + Tailscale only
- **fail2ban**: Protection against brute force
- **Tailscale**: Private network access
- **Gateway**: Loopback-only binding

## Backups

Automatic daily backups at 2am:
- Config: `~/.openclaw/`
- Environment: `.env`
- Location: `~/backups/`
- Retention: 7 days

Manual backup:
```bash
~/backup.sh
```

## Cost

| Component | Monthly |
|-----------|---------|
| Droplet (2vCPU/4GB) | $24 |
| Tailscale | Free |
| Backups | Free |
| **Total** | **$24** |
| + LLM API usage | Variable |

## Troubleshooting

### Container won't start
```bash
docker compose logs --tail=100 openclaw-gateway
```

### Telegram not receiving messages
1. Check bot token: `docker compose exec openclaw-gateway node dist/index.js channels status`
2. Verify webhook (if applicable)

### SecondBrain skill not working
```bash
# Test connection
curl -H "Authorization: Bearer $SECONDBRAIN_API_KEY" \
  "$SECONDBRAIN_BASE_URL/api/v1/health"
```

### Out of memory
Consider upgrading to s-4vcpu-8gb ($48/mo) for heavy workloads.
