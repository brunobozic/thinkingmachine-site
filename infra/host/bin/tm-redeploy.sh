#!/bin/sh
# tm-redeploy.sh — pulls the latest site image and rolls the container.
# Installed at /usr/local/bin/tm-redeploy.sh on the VPS.
# Called by the tm-webhook systemd service when the deploy webhook fires.

set -eu
ts() { printf '[%s] ' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; }
ts; echo "redeploy: starting"
cd /srv/thinkingmachine-site
ts; echo "docker compose pull"
docker compose pull thinkingmachine-site 2>&1
ts; echo "docker compose up -d"
docker compose up -d thinkingmachine-site 2>&1
ts; echo "docker image prune -f"
docker image prune -f >/dev/null 2>&1 || true
ts; echo "redeploy: done"
