#!/usr/bin/env bash
# hardening-3.sh — cost-protective hardening pass.
# Designed to be re-runnable: every section is idempotent.

set -euo pipefail
LOG_PREFIX="[harden3]"
log() { echo "$LOG_PREFIX $*"; }

# ----------------------------------------------------------------------
# 1) Swap (1 GB)
# ----------------------------------------------------------------------
if ! swapon --show | grep -q swapfile; then
  log "Creating 1 GB swap file at /swapfile"
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  if ! grep -q '^/swapfile' /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
  fi
  # Conservative swappiness: prefer RAM, swap only when really needed
  echo "vm.swappiness=10" > /etc/sysctl.d/90-swappiness.conf
  sysctl -p /etc/sysctl.d/90-swappiness.conf >/dev/null
  log "Swap created and enabled"
else
  log "Swap already present, skipping"
fi

# ----------------------------------------------------------------------
# 2) bpf_jit_harden=2 (eBPF JIT spectre hardening)
# ----------------------------------------------------------------------
log "Setting net.core.bpf_jit_harden=2"
echo "net.core.bpf_jit_harden=2" > /etc/sysctl.d/91-bpf-harden.conf
sysctl -p /etc/sysctl.d/91-bpf-harden.conf >/dev/null

# ----------------------------------------------------------------------
# 3) fail2ban nginx jail — badbot / no-script / 404-flood
# ----------------------------------------------------------------------
log "Installing fail2ban nginx jails"
mkdir -p /etc/fail2ban/jail.d /etc/fail2ban/filter.d

cat > /etc/fail2ban/filter.d/nginx-badbot.conf <<'F'
[Definition]
badbotscustom = ahrefsbot|mj12bot|semrushbot|petalbot|dotbot|seznambot|bytespider|claudebot|amazonbot|gptbot|ccbot|facebookexternalhit
failregex = ^<HOST>.*"(GET|POST|HEAD).*HTTP.*"\s.*"(?:%(badbotscustom)s)" *$
ignoreregex =
F

cat > /etc/fail2ban/filter.d/nginx-noscript.conf <<'F'
[Definition]
failregex = ^<HOST>.*"(GET|POST|HEAD).*\.(php|asp|aspx|jsp|cgi|env|git|sql|bak|zip|rar|tar|7z|sh|exe|conf|ini)(\?|\s|HTTP).*$
ignoreregex =
F

cat > /etc/fail2ban/filter.d/nginx-404.conf <<'F'
[Definition]
failregex = ^<HOST>.* ".*HTTP.*" 404 .*$
ignoreregex = ^<HOST>.* "(GET|HEAD) /(?:apple-touch-icon|favicon|robots\.txt|sitemap).*HTTP.*" 404 .*$
F

cat > /etc/fail2ban/jail.d/nginx.conf <<'F'
[nginx-badbot]
enabled  = true
filter   = nginx-badbot
logpath  = /var/lib/docker/containers/*/*-json.log
maxretry = 1
findtime = 60m
bantime  = 7d
backend  = polling

[nginx-noscript]
enabled  = true
filter   = nginx-noscript
logpath  = /var/lib/docker/containers/*/*-json.log
maxretry = 3
findtime = 10m
bantime  = 7d
backend  = polling

[nginx-404]
enabled  = true
filter   = nginx-404
logpath  = /var/lib/docker/containers/*/*-json.log
maxretry = 30
findtime = 10m
bantime  = 1h
backend  = polling
F

systemctl reload fail2ban || systemctl restart fail2ban
log "fail2ban jails reloaded"
fail2ban-client status | head -5

# ----------------------------------------------------------------------
# 4) Egress traffic shaper — cap eth0 outbound at 20 Mbps
# ----------------------------------------------------------------------
# Static site needs <<1 Mbps. 20 Mbps cap means catastrophic burn would
# still produce only ~6.5 GB/hour — alarms trigger long before quota hit.
log "Installing tc-based egress traffic shaper (20 Mbps cap)"

cat > /usr/local/sbin/tm-egress-shaper.sh <<'F'
#!/usr/bin/env bash
# Caps eth0 egress at 20 Mbps via tc HTB. Idempotent: clears existing qdisc first.
set -e
DEV=eth0
RATE=20mbit
CEIL=20mbit
tc qdisc del dev "$DEV" root 2>/dev/null || true
tc qdisc add dev "$DEV" root handle 1: htb default 10
tc class add dev "$DEV" parent 1: classid 1:1 htb rate "$RATE" ceil "$CEIL"
tc class add dev "$DEV" parent 1:1 classid 1:10 htb rate "$RATE" ceil "$CEIL"
F
chmod +x /usr/local/sbin/tm-egress-shaper.sh

# systemd unit so it survives reboots
cat > /etc/systemd/system/tm-egress-shaper.service <<'F'
[Unit]
Description=Egress bandwidth cap (20 Mbps) for cost protection
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/tm-egress-shaper.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
F
systemctl daemon-reload
systemctl enable tm-egress-shaper.service >/dev/null
systemctl start tm-egress-shaper.service
log "Egress shaper installed and started"
tc qdisc show dev eth0 | head -3

# ----------------------------------------------------------------------
# 5) Bandwidth monitor + kill switch
# ----------------------------------------------------------------------
log "Installing bandwidth monitor + kill switch"

mkdir -p /var/log/tm-bw /var/lib/tm-bw

cat > /usr/local/sbin/tm-bw-check.sh <<'F'
#!/usr/bin/env bash
# Runs every 5 minutes via cron.
# - Logs current rx/tx + delta to /var/log/tm-bw/bw.log
# - Tracks monthly totals in /var/lib/tm-bw/month-{YYYY-MM}.txt
# - If monthly traffic exceeds 16 TB (80% of 20 TB Hetzner cap), STOPS
#   the user-facing containers to prevent overage charges.
# - Logs an alert at 50% (10 TB) and 75% (15 TB) thresholds.
set -euo pipefail
LOGFILE=/var/log/tm-bw/bw.log
STATE_DIR=/var/lib/tm-bw
DEV=eth0
MONTH=$(date +%Y-%m)
MONTH_FILE="$STATE_DIR/month-${MONTH}.txt"
LAST_FILE="$STATE_DIR/last.txt"
KILL_FILE="$STATE_DIR/killed-${MONTH}.flag"

# Thresholds in bytes
T_50=10995116277760  # 10 TB
T_75=16492674416640  # 15 TB
T_80=17592186044416  # 16 TB (KILL)

now_ts=$(date +%s)
now_iso=$(date -Iseconds)
rx=$(cat /sys/class/net/${DEV}/statistics/rx_bytes)
tx=$(cat /sys/class/net/${DEV}/statistics/tx_bytes)
total=$((rx + tx))

# delta since last run
prev_rx=0; prev_tx=0; prev_total=0
if [[ -f "$LAST_FILE" ]]; then
  read prev_ts prev_rx prev_tx prev_total < "$LAST_FILE"
fi
delta=$((total - prev_total))
[[ $delta -lt 0 ]] && delta=0  # boot reset
echo "$now_ts $rx $tx $total" > "$LAST_FILE"

# add delta to the monthly counter
month_total=0
[[ -f "$MONTH_FILE" ]] && month_total=$(cat "$MONTH_FILE")
month_total=$((month_total + delta))
echo "$month_total" > "$MONTH_FILE"

# log line
month_gb=$(awk "BEGIN{printf \"%.2f\", $month_total/1073741824}")
delta_kb=$(awk "BEGIN{printf \"%.0f\", $delta/1024}")
echo "$now_iso  delta=${delta_kb}KB  month=${month_gb}GB  rx_lifetime=$(awk "BEGIN{printf \"%.2f\", $rx/1073741824}")GB  tx_lifetime=$(awk "BEGIN{printf \"%.2f\", $tx/1073741824}")GB" >> "$LOGFILE"

# threshold actions
if [[ $month_total -gt $T_80 && ! -f $KILL_FILE ]]; then
  echo "$now_iso  CRITICAL: monthly traffic ${month_gb}GB > 16 TB. STOPPING CONTAINERS." >> "$LOGFILE"
  /usr/bin/docker compose -f /srv/thinkingmachine-site/docker-compose.yml stop 2>>"$LOGFILE" || true
  /usr/bin/docker compose -f /srv/traefik/docker-compose.yml stop 2>>"$LOGFILE" || true
  date -Iseconds > "$KILL_FILE"
  logger -t tm-bw -p crit "Containers stopped: monthly bandwidth at ${month_gb}GB"
elif [[ $month_total -gt $T_75 ]]; then
  if [[ ! -f "$STATE_DIR/alert-75-${MONTH}.flag" ]]; then
    echo "$now_iso  ALERT: monthly traffic ${month_gb}GB > 15 TB (75%)" >> "$LOGFILE"
    date -Iseconds > "$STATE_DIR/alert-75-${MONTH}.flag"
    logger -t tm-bw -p warning "Bandwidth at 75% of monthly cap: ${month_gb}GB"
  fi
elif [[ $month_total -gt $T_50 ]]; then
  if [[ ! -f "$STATE_DIR/alert-50-${MONTH}.flag" ]]; then
    echo "$now_iso  ALERT: monthly traffic ${month_gb}GB > 10 TB (50%)" >> "$LOGFILE"
    date -Iseconds > "$STATE_DIR/alert-50-${MONTH}.flag"
    logger -t tm-bw -p notice "Bandwidth at 50% of monthly cap: ${month_gb}GB"
  fi
fi
F
chmod +x /usr/local/sbin/tm-bw-check.sh

# Cron every 5 minutes
cat > /etc/cron.d/tm-bw-check <<'F'
# Bandwidth monitoring + kill switch (cost protection)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * root /usr/local/sbin/tm-bw-check.sh
# Daily summary line for easy review
59 23 * * * root tail -1 /var/log/tm-bw/bw.log | logger -t tm-bw-daily
F
chmod 644 /etc/cron.d/tm-bw-check

# Logrotate so the log file doesn't grow forever
cat > /etc/logrotate.d/tm-bw <<'F'
/var/log/tm-bw/bw.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    su root root
}
F
log "Bandwidth monitor installed"

# ----------------------------------------------------------------------
# 6) Re-run Lynis to confirm posture
# ----------------------------------------------------------------------
log "Running Lynis audit (last 30 lines)"
lynis audit system --quick --no-colors 2>&1 | tail -30

log "Hardening pass complete."
