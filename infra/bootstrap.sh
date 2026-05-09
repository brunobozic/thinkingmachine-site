#!/usr/bin/env bash
# bootstrap.sh — Take a fresh Ubuntu 24.04 LTS Hetzner CX22 from zero to
# "Docker + Traefik running, ready to deploy thinkingmachine-site".
#
# Usage (after SSHing in as root):
#   curl -fsSL https://raw.githubusercontent.com/brunobozic/thinkingmachine-site/main/infra/bootstrap.sh -o bootstrap.sh
#   chmod +x bootstrap.sh
#   ./bootstrap.sh
#
# Or just paste the script into the SSH session.
#
# Idempotent: safe to re-run.

set -euo pipefail

log() { printf "\n\033[1;34m▶ %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }

# ----------------------------------------------------------------------------
# 1) System update + base packages
# ----------------------------------------------------------------------------
log "Updating system packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get -y -qq -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold upgrade
apt-get -y -qq install \
  ca-certificates curl gnupg lsb-release \
  ufw fail2ban unattended-upgrades \
  htop ncdu jq vim
ok "Base packages installed"

# ----------------------------------------------------------------------------
# 2) Docker Engine + Compose plugin (official Docker repo, not Ubuntu's)
# ----------------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get -y -qq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  ok "Docker installed: $(docker --version)"
else
  ok "Docker already installed: $(docker --version)"
fi

# ----------------------------------------------------------------------------
# 3) Firewall (UFW)
# ----------------------------------------------------------------------------
log "Configuring firewall"
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp   comment "SSH"
ufw allow 80/tcp   comment "HTTP (Traefik / ACME challenge)"
ufw allow 443/tcp  comment "HTTPS (Traefik)"
ufw --force enable
ok "Firewall: 22/80/443 inbound, all outbound"

# ----------------------------------------------------------------------------
# 4) Unattended-upgrades for security patches
# ----------------------------------------------------------------------------
log "Enabling unattended security upgrades"
dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1 || true
ok "Unattended upgrades enabled"

# ----------------------------------------------------------------------------
# 5) Directory layout
# ----------------------------------------------------------------------------
log "Creating /srv layout"
mkdir -p /srv/traefik/letsencrypt
mkdir -p /srv/thinkingmachine-site
chmod 700 /srv/traefik/letsencrypt 2>/dev/null || true
ok "Directories created under /srv"

# ----------------------------------------------------------------------------
# 6) Docker network used by Traefik + apps
# ----------------------------------------------------------------------------
if ! docker network inspect traefik >/dev/null 2>&1; then
  log "Creating shared 'traefik' Docker network"
  docker network create traefik >/dev/null
fi
ok "Docker network 'traefik' ready"

# ----------------------------------------------------------------------------
# 7) Done — print next steps
# ----------------------------------------------------------------------------
SERVER_IP=$(curl -fsS https://ifconfig.me 2>/dev/null || echo "<server-ip>")
cat <<EOF

\033[1;32m═══════════════════════════════════════════════════════════════════\033[0m
  Bootstrap complete. Server is ready for Traefik + site deployment.
\033[1;32m═══════════════════════════════════════════════════════════════════\033[0m

Server public IP: $SERVER_IP

Next steps (in order):

  1. Point DNS:  thinkingmachine.uk        A    $SERVER_IP
                 www.thinkingmachine.uk    A    $SERVER_IP
     Wait for DNS to propagate (usually 1-5 min). Check with:
        dig +short thinkingmachine.uk

  2. Drop the Traefik compose into /srv/traefik/docker-compose.yml
     and the static config into /srv/traefik/traefik.yml.
     Then:
        cd /srv/traefik && docker compose up -d

  3. Authenticate Docker with GitHub Container Registry (one-time):
        docker login ghcr.io -u brunobozic
     (paste the PAT with read:packages scope when prompted)

  4. Drop the site compose into /srv/thinkingmachine-site/docker-compose.yml.
     Then:
        cd /srv/thinkingmachine-site && docker compose up -d

  5. Verify:
        curl -I https://thinkingmachine.uk/

EOF
