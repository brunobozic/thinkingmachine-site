# `infra/host/` — host-level configs on the production VPS

Every file here corresponds to a real file on `tm-prod-fsn1`. Treat this
directory as the source of truth — if you change something here, deploy it.
If you change something on the VPS, pull it back here and commit.

## Layout

```
infra/host/
├── README.md                          ← this file
├── systemd/
│   ├── tm-webhook.service             → /etc/systemd/system/tm-webhook.service
│   ├── lynis-audit.service+.timer     → /etc/systemd/system/
│   ├── docker-prune.service+.timer    → /etc/systemd/system/
│   └── acme-backup.service+.timer     → /etc/systemd/system/
├── ssh/
│   └── 99-tm-hardening.conf           → /etc/ssh/sshd_config.d/99-tm-hardening.conf
├── apt/
│   └── 51tm-auto-reboot               → /etc/apt/apt.conf.d/51tm-auto-reboot
├── journald/
│   └── 99-tm-limits.conf              → /etc/systemd/journald.conf.d/99-tm-limits.conf
├── fail2ban/
│   ├── filter.d/traefik-auth.conf     → /etc/fail2ban/filter.d/traefik-auth.conf
│   └── jail.d/traefik.conf            → /etc/fail2ban/jail.d/traefik.conf
└── bin/
    └── tm-redeploy.sh                 → /usr/local/bin/tm-redeploy.sh (chmod +x)
```

## What each file does

| File | Purpose |
|---|---|
| `systemd/tm-webhook.service` | Runs the deploy webhook on port 9001 with full systemd hardening (NoNewPrivileges, ProtectSystem=strict, ProtectKernel*, ReadOnlyPaths, RestrictAddressFamilies, 64M MemoryMax, 64 TasksMax) |
| `systemd/lynis-audit.service` + `.timer` | Weekly Lynis security audit every Sunday 04:00 UTC; logs to `/var/log/lynis-weekly.log` |
| `systemd/docker-prune.service` + `.timer` | Daily prune of Docker images + stopped containers older than 7 days |
| `systemd/acme-backup.service` + `.timer` | Daily copy of `acme.json` to `/var/backups/traefik/` with 14-day rotation — saves a cert re-issue dance if the VPS dies |
| `ssh/99-tm-hardening.conf` | Drop-in: X11Forwarding off, MaxAuthTries 3, no agent/tunnel forwarding, 30s LoginGraceTime, 5min ClientAlive |
| `apt/51tm-auto-reboot` | Reboot automatically at 03:30 UTC when a kernel upgrade is pending. Previously the VPS would accumulate kernel updates and never reboot |
| `journald/99-tm-limits.conf` | Cap journald at 200M (we were sitting at 162M with no limit), 30-day retention, compress yes |
| `fail2ban/filter.d/traefik-auth.conf` + `jail.d/traefik.conf` | Watches Traefik's JSON access log via journald; bans IPs that rack up 10x 401/403/429 in 5 minutes for 1 hour |
| `bin/tm-redeploy.sh` | The script the webhook executes — `docker compose pull && up -d` |

## Applying on a fresh VPS

After running `infra/bootstrap.sh` and `infra/hardening.sh`:

```bash
# Copy systemd units, ssh + apt + journald drop-ins, fail2ban rules, redeploy script
cp infra/host/systemd/*.service infra/host/systemd/*.timer /etc/systemd/system/
cp infra/host/ssh/99-tm-hardening.conf /etc/ssh/sshd_config.d/
cp infra/host/apt/51tm-auto-reboot /etc/apt/apt.conf.d/
mkdir -p /etc/systemd/journald.conf.d
cp infra/host/journald/99-tm-limits.conf /etc/systemd/journald.conf.d/
cp infra/host/fail2ban/filter.d/traefik-auth.conf /etc/fail2ban/filter.d/
cp infra/host/fail2ban/jail.d/traefik.conf /etc/fail2ban/jail.d/
cp infra/host/bin/tm-redeploy.sh /usr/local/bin/ && chmod +x /usr/local/bin/tm-redeploy.sh

# Reload + enable
systemctl daemon-reload
systemctl restart systemd-journald
systemctl reload ssh
systemctl enable --now tm-webhook lynis-audit.timer docker-prune.timer acme-backup.timer
systemctl restart fail2ban

# Verify
systemctl list-timers --all | grep -E "(lynis|docker-prune|acme-backup)"
systemctl status tm-webhook --no-pager
fail2ban-client status
```

## Hardening profile — what's enforced

After applying this directory, the VPS has:

- **OS:** Ubuntu 24.04 LTS, kernel sysctls hardened (ASLR=2, kptr_restrict=2, dmesg_restrict=1, yama.ptrace_scope=1, bpf_jit_harden=2, accept_redirects=0)
- **SSH:** key-only, root login restricted, X11/Agent/Tunnel forwarding off, MaxAuthTries 3, 30s LoginGrace
- **Firewall:** UFW deny-incoming + deny-outgoing by default; 22/80/443 in, DNS/HTTP/HTTPS/NTP out, SMTP egress blocked
- **fail2ban:** 5 jails — sshd, nginx-404, nginx-badbot, nginx-noscript, traefik-auth
- **Docker:** AppArmor + seccomp profiles, no userns-remap (intentional — would break our compose volume mounts), live-restore, log rotation, no-new-privileges enforced
- **Containers:** ReadOnlyRootfs, CapDrop=ALL with explicit additions only, no-new-privileges, MemoryMax + PidsLimit
- **Webhook:** systemd-hardened (NoNewPrivileges, ProtectSystem=strict, RestrictAddressFamilies, 64M memory cap, 64 task cap)
- **TLS:** Let's Encrypt via TLS-ALPN-01, TLS 1.2+ only, sniStrict, X25519+P-384 curves
- **Updates:** unattended-upgrades active, auto-reboot at 03:30 UTC on kernel changes
- **Audit:** auditd running, lynis weekly audit, fail2ban with 5 jails, journald capped
- **Backup:** daily acme.json snapshot, 14-day rotation

## What's NOT (yet) enforced

These are the deliberate next steps if/when they're worth the effort:

1. **Container image vulnerability scanning** — add a `trivy` step to the CI workflow before docker push.
2. **CrowdSec** alongside fail2ban — proactive (consensus-based) instead of reactive.
3. **CAA records tightened** — Cloudflare currently allows 5 CAs to issue; should drop to letsencrypt.org only.
4. **HSTS preload submission** — header has `preload` directive but the domain isn't actually in Chromium's preload list yet. Submit at https://hstspreload.org/.
5. **Userns-remap on Docker daemon** — eliminates the host-root-from-container-root mapping. Requires testing all our compose mounts.
6. **AIDE filesystem integrity baseline** — daily diff against a known-good snapshot.
7. **Cold-tier backup of `/srv/`** to off-VPS storage (Hetzner Storage Box or S3-compatible).
