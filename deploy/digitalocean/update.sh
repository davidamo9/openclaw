#!/bin/bash
set -euo pipefail

# OpenClaw Update Script
# Pulls latest from fork and rebuilds container

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

cd "$REPO_DIR"

log_info "Pulling latest changes..."
git pull origin main

log_info "Rebuilding container..."
cd "$SCRIPT_DIR"
docker compose build

log_info "Restarting with new image..."
docker compose down
docker compose up -d

log_info "Update complete!"
docker compose ps
