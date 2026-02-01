#!/bin/bash
set -euo pipefail

# OpenClaw DigitalOcean Droplet Setup Script
# Run as root on a fresh Docker on Ubuntu 22.04 droplet

echo "=== OpenClaw DigitalOcean Setup ==="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# --- Phase 1: Create non-root user ---
log_info "Creating 'openclaw' user..."
if ! id "openclaw" &>/dev/null; then
    useradd -m -s /bin/bash openclaw
    usermod -aG docker openclaw
    log_info "User 'openclaw' created and added to docker group"
else
    log_warn "User 'openclaw' already exists"
fi

# --- Phase 2: Setup SSH for openclaw user ---
log_info "Setting up SSH for 'openclaw' user..."
mkdir -p /home/openclaw/.ssh
if [[ -f /root/.ssh/authorized_keys ]]; then
    cp /root/.ssh/authorized_keys /home/openclaw/.ssh/
    chown -R openclaw:openclaw /home/openclaw/.ssh
    chmod 700 /home/openclaw/.ssh
    chmod 600 /home/openclaw/.ssh/authorized_keys
    log_info "SSH keys copied to openclaw user"
else
    log_warn "No SSH keys found in /root/.ssh/authorized_keys"
fi

# --- Phase 3: Security Hardening ---
log_info "Hardening SSH configuration..."

# Backup sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Disable root login
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart sshd
log_info "SSH hardened: root login disabled, password auth disabled"

# --- Phase 4: Configure Firewall ---
log_info "Configuring UFW firewall..."
apt-get update -qq
apt-get install -y -qq ufw

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 41641/udp comment 'Tailscale'
ufw --force enable
log_info "Firewall enabled (SSH + Tailscale allowed)"

# --- Phase 5: Install fail2ban ---
log_info "Installing fail2ban..."
apt-get install -y -qq fail2ban
systemctl enable fail2ban
systemctl start fail2ban
log_info "fail2ban installed and enabled"

# --- Phase 6: Install Tailscale ---
log_info "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
log_info "Tailscale installed. Run 'tailscale up' to connect."

# --- Phase 7: Create backup script ---
log_info "Creating backup script..."
cat > /home/openclaw/backup.sh << 'BACKUP_EOF'
#!/bin/bash
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/openclaw_$DATE.tar.gz" ~/.openclaw/ ~/openclaw/.env 2>/dev/null || true
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
echo "Backup completed: $BACKUP_DIR/openclaw_$DATE.tar.gz"
BACKUP_EOF
chmod +x /home/openclaw/backup.sh
chown openclaw:openclaw /home/openclaw/backup.sh

# Add to crontab (daily at 2am)
(crontab -l -u openclaw 2>/dev/null || true; echo "0 2 * * * /home/openclaw/backup.sh") | crontab -u openclaw -
log_info "Daily backup configured (2am)"

# --- Phase 8: Create directory structure ---
log_info "Creating directory structure..."
mkdir -p /home/openclaw/.openclaw
mkdir -p /home/openclaw/backups
chown -R openclaw:openclaw /home/openclaw

# --- Summary ---
echo ""
echo "==================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "==================================="
echo ""
echo "Next steps:"
echo "1. Connect Tailscale: tailscale up"
echo "2. Switch to openclaw user: su - openclaw"
echo "3. Clone your fork: git clone git@github.com:YOUR_USERNAME/openclaw.git"
echo "4. Copy .env.example to .env and configure"
echo "5. Deploy: cd openclaw/deploy/digitalocean && docker compose up -d"
echo ""
echo "SSH via Tailscale: ssh openclaw@<tailscale-ip>"
echo ""
