#!/bin/sh
# /scripts/redeploy.sh — pulls the new image and rolls the site container.
# Invoked by adnanh/webhook after bearer-token auth succeeds.
#
# This runs INSIDE the webhook container against the host's docker daemon
# (via the mounted /var/run/docker.sock). Logs go to webhook container stdout,
# which is captured by Docker's log driver.

set -eu

# Log lines go to webhook's stdout
ts() { printf '[%s] ' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; }

ts; echo "redeploy: starting"

# Pull the new image. Will fail (exit !=0) if GHCR auth is missing or image isn't there.
ts; echo "redeploy: docker compose pull thinkingmachine-site"
docker compose -f /opt/thinkingmachine-site/docker-compose.yml pull thinkingmachine-site

# Roll the container. up -d swaps it cleanly without dropping Traefik routes.
ts; echo "redeploy: docker compose up -d thinkingmachine-site"
docker compose -f /opt/thinkingmachine-site/docker-compose.yml up -d thinkingmachine-site

# Best-effort prune of dangling images so the VPS disk doesn't fill up over time
ts; echo "redeploy: docker image prune -f"
docker image prune -f >/dev/null 2>&1 || true

ts; echo "redeploy: done"
