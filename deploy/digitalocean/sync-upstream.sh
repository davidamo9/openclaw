#!/bin/bash
set -euo pipefail

# Sync fork with upstream OpenClaw repository
# Run this periodically to get latest updates from openclaw/openclaw

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cd "$REPO_DIR"

# Check if upstream remote exists
if ! git remote | grep -q upstream; then
    log_info "Adding upstream remote..."
    git remote add upstream git@github.com:openclaw/openclaw.git
fi

log_info "Fetching upstream changes..."
git fetch upstream

log_info "Current branch: $(git branch --show-current)"

# Check for conflicts
MERGE_BASE=$(git merge-base main upstream/main)
LOCAL_HEAD=$(git rev-parse main)
UPSTREAM_HEAD=$(git rev-parse upstream/main)

if [[ "$LOCAL_HEAD" == "$UPSTREAM_HEAD" ]]; then
    log_info "Already up to date with upstream!"
    exit 0
fi

log_info "Merging upstream/main..."
if git merge upstream/main --no-edit; then
    log_info "Merge successful!"
    log_info "Pushing to origin..."
    git push origin main
    log_info "Fork synced with upstream!"
else
    log_warn "Merge conflicts detected!"
    echo ""
    echo "Resolve conflicts manually, then:"
    echo "  git add ."
    echo "  git commit -m 'Merge upstream'"
    echo "  git push origin main"
    exit 1
fi
