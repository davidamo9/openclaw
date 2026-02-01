#!/bin/bash
set -euo pipefail

# OpenClaw Deployment Script
# Run as 'openclaw' user

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as openclaw
if [[ "$(whoami)" != "openclaw" ]]; then
    log_warn "This script should be run as 'openclaw' user"
fi

cd "$SCRIPT_DIR"

# Check for .env file
if [[ ! -f .env ]]; then
    log_error ".env file not found!"
    echo "Copy .env.example to .env and configure:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Validate required environment variables
log_info "Validating environment variables..."
source .env

REQUIRED_VARS=(
    "ANTHROPIC_API_KEY"
    "TELEGRAM_BOT_TOKEN"
    "OPENCLAW_GATEWAY_TOKEN"
    "SECONDBRAIN_API_KEY"
    "SECONDBRAIN_BASE_URL"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        MISSING_VARS+=("$var")
    fi
done

if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
    log_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

log_info "Environment validated"

# Copy config file if not exists
if [[ ! -f ~/.openclaw/openclaw.json ]]; then
    log_info "Copying openclaw.json configuration..."
    mkdir -p ~/.openclaw
    cp "$SCRIPT_DIR/openclaw.json" ~/.openclaw/
fi

# Pull latest changes
log_info "Pulling latest changes from git..."
cd "$REPO_DIR"
git pull origin main

# Build and deploy
log_info "Building and deploying OpenClaw..."
cd "$SCRIPT_DIR"
docker compose build --no-cache
docker compose down 2>/dev/null || true
docker compose up -d

# Wait for container to be healthy
log_info "Waiting for container to be healthy..."
sleep 10

# Check status
if docker compose ps | grep -q "Up"; then
    log_info "OpenClaw is running!"
    echo ""
    echo "=== Deployment Status ==="
    docker compose ps
    echo ""
    echo "View logs: docker compose logs -f"
    echo "Health check: curl http://localhost:18789/health"
else
    log_error "Container failed to start!"
    docker compose logs --tail=50
    exit 1
fi
