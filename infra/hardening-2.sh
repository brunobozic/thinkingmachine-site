#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n\033[1;34m▶ %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m✓\033[0m %s\n" "$*"; }

# 1) Update packages (fix vulnerable ones)
log "Upgrading packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get -y -qq -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold upgrade
apt-get -y -qq autoremove
ok "Packages upgraded"

# 2) Mask Postfix (we don't run a mail server, so banner shouldn't leak)
log "Masking unused mail services"
for svc in postfix exim4 sendmail; do
  systemctl mask "$svc" 2>/dev/null || true
  systemctl stop "$svc" 2>/dev/null || true
done
ok "Mail services masked"

# 3) Disable core dumps (KRNL-5820)
log "Disabling core dumps"
cat > /etc/security/limits.d/99-disable-core.conf <<EOF
* hard core 0
* soft core 0
EOF
echo "kernel.core_pattern=|/bin/false" > /etc/sysctl.d/99-disable-cores.conf
echo "fs.suid_dumpable=0" >> /etc/sysctl.d/99-disable-cores.conf
sysctl --system >/dev/null 2>&1
ok "Core dumps disabled"

# 4) Stricter umask (AUTH-9328)
log "Tightening default umask to 027"
sed -i 's/^UMASK[[:space:]]*022/UMASK 027/' /etc/login.defs
sed -i 's/^USERGROUPS_ENAB[[:space:]]*yes/USERGROUPS_ENAB no/' /etc/login.defs
ok "umask 027"

# 5) Disable USB storage driver (USB-1000)
log "Disabling USB storage driver"
echo "blacklist usb-storage" > /etc/modprobe.d/no-usb-storage.conf
ok "USB storage blacklisted"

# 6) Password hashing rounds (AUTH-9230)
log "Increasing password hashing rounds"
sed -i 's/^#\?SHA_CRYPT_MIN_ROUNDS.*/SHA_CRYPT_MIN_ROUNDS 65536/' /etc/login.defs
sed -i 's/^#\?SHA_CRYPT_MAX_ROUNDS.*/SHA_CRYPT_MAX_ROUNDS 65536/' /etc/login.defs
grep -q "SHA_CRYPT_MIN_ROUNDS" /etc/login.defs || echo "SHA_CRYPT_MIN_ROUNDS 65536" >> /etc/login.defs
grep -q "SHA_CRYPT_MAX_ROUNDS" /etc/login.defs || echo "SHA_CRYPT_MAX_ROUNDS 65536" >> /etc/login.defs
ok "Password hashing rounds = 65536"

# 7) Disable rare/unused network protocols (NETW-3200)
log "Blacklisting rare network protocols"
cat > /etc/modprobe.d/no-uncommon-net-protos.conf <<EOF
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF
ok "DCCP/SCTP/RDS/TIPC disabled"

# 8) Copy fail2ban jail.conf to jail.local (DEB-0880)
log "Pinning fail2ban defaults to jail.local"
[ -f /etc/fail2ban/jail.local ] || cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl restart fail2ban || true
ok "fail2ban jail.local in place"

# 9) Remove SMTP from the world (the masked services may still leak; remove postfix entirely)
log "Removing postfix package"
apt-get -y -qq purge postfix 2>/dev/null || true
ok "Postfix removed"

# 10) Re-run Lynis quietly to verify improvements
log "Re-running Lynis"
lynis audit system --quick --quiet > /var/log/lynis-baseline.log 2>&1 || true
NEW_INDEX=$(grep "hardening_index" /var/log/lynis-report.dat | head -1 | cut -d= -f2)
ok "New hardening index: ${NEW_INDEX:-unknown}/100"
