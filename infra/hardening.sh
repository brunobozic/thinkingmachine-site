#!/usr/bin/env bash
# hardening.sh — Apply security hardening on top of bootstrap.sh.
#
# Run AFTER bootstrap.sh on a fresh Hetzner CX23 (Ubuntu 24.04 LTS).
# Threat model: prevent intrusions that could incur cloud costs (botnet bandwidth,
# crypto miners phoning home, account-takeover-driven resource spawning).
#
# Idempotent: safe to re-run.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/brunobozic/thinkingmachine-site/main/infra/hardening.sh | bash

set -euo pipefail

log() { printf "\n\033[1;34m▶ %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m✓\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m⚠ %s\033[0m\n" "$*"; }

# ----------------------------------------------------------------------------
# 1) Install audit/monitoring tools
# ----------------------------------------------------------------------------
log "Installing security & monitoring packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get -y -qq install \
  vnstat \
  auditd audispd-plugins \
  lynis rkhunter \
  needrestart

systemctl enable --now vnstat
systemctl enable --now auditd
ok "vnstat + auditd running"

# ----------------------------------------------------------------------------
# 2) SSH hardening — key-only, no password, restrict root
# ----------------------------------------------------------------------------
log "Hardening sshd_config"
SSHD_DROPIN=/etc/ssh/sshd_config.d/99-hardening.conf
cat > "$SSHD_DROPIN" <<'EOF'
# /etc/ssh/sshd_config.d/99-hardening.conf — applied after bootstrap
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin prohibit-password
MaxAuthTries 3
MaxSessions 4
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
UseDNS no
Protocol 2
EOF
chmod 644 "$SSHD_DROPIN"

# Validate config before reloading (refuse to break SSH)
if sshd -t; then
  systemctl reload ssh || systemctl reload sshd
  ok "sshd reloaded with hardened config"
else
  warn "sshd config validation failed — leaving previous config in place"
  rm -f "$SSHD_DROPIN"
  exit 1
fi

# ----------------------------------------------------------------------------
# 3) fail2ban — aggressive SSH jail
# ----------------------------------------------------------------------------
log "Configuring fail2ban"
cat > /etc/fail2ban/jail.d/sshd-aggressive.local <<'EOF'
[DEFAULT]
bantime  = 86400      # 24h
findtime = 600        # 10 min
maxretry = 3
backend  = systemd

[sshd]
enabled  = true
port     = ssh
filter   = sshd
maxretry = 3
bantime  = 86400
EOF

systemctl enable --now fail2ban
systemctl restart fail2ban
sleep 2
fail2ban-client status sshd 2>/dev/null | head -10 || warn "fail2ban not yet reporting"
ok "fail2ban active"

# ----------------------------------------------------------------------------
# 4) Sysctl — network/kernel hardening
# ----------------------------------------------------------------------------
log "Applying sysctl hardening"
cat > /etc/sysctl.d/99-tm-hardening.conf <<'EOF'
# /etc/sysctl.d/99-tm-hardening.conf

# IP forwarding off — we're not a router
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Reverse path filter (anti-spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Disable ICMP redirects (defense vs. MITM)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore broadcast pings (anti-Smurf)
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Process restrictions
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_userns_clone = 1   # needed by Docker rootless / nginx

# Reduce visibility
kernel.randomize_va_space = 2
EOF

sysctl --system >/dev/null 2>&1
ok "sysctl hardening applied"

# ----------------------------------------------------------------------------
# 5) UFW egress restrictions — defense vs. botnet/miner phone-home
# ----------------------------------------------------------------------------
log "Restricting outbound traffic via UFW (defense vs. unauthorized egress)"

# Default deny outbound
ufw default deny outgoing

# Allow only what's actually needed:
ufw allow out 53/udp     comment "DNS"
ufw allow out 53/tcp     comment "DNS (TCP fallback)"
ufw allow out 80/tcp     comment "HTTP (apt, ACME, etc.)"
ufw allow out 443/tcp    comment "HTTPS - apt ghcr lets-encrypt docker"
ufw allow out 123/udp    comment "NTP"
ufw allow out 11371/tcp  comment "GPG keyservers"

# Outbound SSH for git operations (we don't use it but keep for now)
ufw allow out 22/tcp     comment "SSH out for git"

# Block port 25 outbound explicitly (Hetzner already blocks it but defense in depth)
# UFW comments must avoid apostrophes and most non-word punctuation.
ufw deny out 25/tcp      comment "SMTP blocked anti-spam"
ufw deny out 465/tcp     comment "SMTPS blocked"
ufw deny out 587/tcp     comment "Submission blocked"

ufw --force enable
ufw reload
ok "UFW outbound restricted to essentials"

# ----------------------------------------------------------------------------
# 6) vnstat — traffic monitoring with monthly threshold reminder
# ----------------------------------------------------------------------------
log "Configuring vnstat for bandwidth tracking"
# Initialize the database for the primary interface
PRIMARY_IF=$(ip -o -4 route show default | awk '{print $5}' | head -1)
if [ -n "$PRIMARY_IF" ] && [ ! -e "/var/lib/vnstat/${PRIMARY_IF}" ]; then
  vnstat -u -i "$PRIMARY_IF" 2>/dev/null || true
fi
systemctl restart vnstat
ok "vnstat tracking ${PRIMARY_IF:-default interface}"

# A simple cron-based traffic alert that emails when monthly outbound exceeds 10 TB
# (50% of Hetzner's 20 TB included quota).
cat > /etc/cron.daily/tm-traffic-alert <<'EOF'
#!/bin/bash
# Daily traffic check — log a warning to syslog if monthly outbound > 10 TB
THRESHOLD_GB=10000
PRIMARY_IF=$(ip -o -4 route show default | awk '{print $5}' | head -1)
TX_GB=$(vnstat --json m 1 -i "$PRIMARY_IF" 2>/dev/null | jq -r '.interfaces[0].traffic.month[0].tx // 0' | awk '{print int($1/1024/1024/1024)}')
if [ -n "$TX_GB" ] && [ "$TX_GB" -gt "$THRESHOLD_GB" ]; then
  logger -t tm-traffic "WARNING: monthly outbound ${TX_GB} GB exceeds ${THRESHOLD_GB} GB threshold"
fi
EOF
chmod +x /etc/cron.daily/tm-traffic-alert
ok "Daily traffic threshold check cron installed"

# ----------------------------------------------------------------------------
# 7) Docker daemon — security defaults
# ----------------------------------------------------------------------------
log "Configuring Docker daemon for safer defaults"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "live-restore": true,
  "no-new-privileges": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  }
}
EOF
systemctl restart docker
ok "Docker daemon hardened (live-restore, no-new-privileges default, log rotation)"

# ----------------------------------------------------------------------------
# 8) Lynis audit baseline (informational — review output later)
# ----------------------------------------------------------------------------
log "Running Lynis security audit (output to /var/log/lynis-baseline.log)"
lynis audit system --quick --quiet > /var/log/lynis-baseline.log 2>&1 || true
ok "Lynis baseline saved — view with:  less /var/log/lynis-baseline.log"

# ----------------------------------------------------------------------------
# 9) Disable unused services (reduce attack surface)
# ----------------------------------------------------------------------------
log "Disabling unused services"
for svc in cups avahi-daemon snapd ModemManager; do
  if systemctl list-unit-files | grep -q "^${svc}\.service"; then
    systemctl disable --now "$svc" 2>/dev/null || true
  fi
done
ok "Unused services disabled (where present)"

# ----------------------------------------------------------------------------
# 10) Log persistence (so we keep evidence across reboots)
# ----------------------------------------------------------------------------
log "Persisting journald logs"
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald
ok "Journald logs now persistent"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
cat <<EOF

\033[1;32m═══════════════════════════════════════════════════════════════════\033[0m
  Hardening complete.
\033[1;32m═══════════════════════════════════════════════════════════════════\033[0m

What's now in place:

  ✓ SSH:        key-only, no passwords, root restricted to keys, MaxAuthTries=3
  ✓ fail2ban:   3 fails in 10 min = 24h ban
  ✓ Sysctl:     SYN flood, no IP forwarding, no source routing, no redirects
  ✓ UFW out:    deny by default; allow 53/80/443/123/11371/22 only
  ✓ Port 25/465/587: explicitly blocked outbound (anti-spam)
  ✓ vnstat:     tracking outbound, daily check warns if > 10 TB/mo
  ✓ Docker:     no-new-privileges default, log rotation, live-restore
  ✓ auditd:     active
  ✓ Lynis:      baseline at /var/log/lynis-baseline.log
  ✓ journald:   persistent across reboots

Cost-incurrence threat surface:

  • Bandwidth abuse (botnet/miner) → vnstat alert at 10 TB,
    Hetzner caps at 20 TB included; over that = €1/TB
  • Outbound spam → ports 25/465/587 blocked
  • Account-level resource abuse → set Hetzner SERVER limit to 1
    via console.hetzner.com → Limits → Request change

Recommended manual follow-ups:

  • Review:  less /var/log/lynis-baseline.log
  • Per-server traffic alert in Hetzner console (server detail page)
  • Periodic:  apt list --upgradable && unattended-upgra