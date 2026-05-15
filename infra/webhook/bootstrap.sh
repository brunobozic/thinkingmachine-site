#!/bin/bash
# One-shot VPS bootstrap for auto-deploy. Run ONCE on the VPS as root.
#
# Usage from your working shell:
#   ssh root@178.105.104.173 'bash -s' < infra/webhook/bootstrap.sh
# or:
#   ssh root@178.105.104.173 'curl -fsSL https://raw.githubusercontent.com/brunobozic/thinkingmachine-site/main/infra/webhook/bootstrap.sh | bash'
#
# What it does:
# 1. Pulls + rolls the new site image (immediate deploy — fixes pending debt)
# 2. Generates a webhook token, stores at /etc/thinkingmachine/webhook.env
# 3. Downloads the webhook receiver files into /opt/thinkingmachine-webhook
# 4. Brings the webhook receiver up behind Traefik
# 5. Prints the GitHub Actions secrets + DNS records you need to add
#
# After this, every push to main auto-deploys. No manual SSH ever again.

set -euo pipefail

log() { printf '\n\e[1;36m[bootstrap]\e[0m %s\n' "$*"; }
err() { printf '\n\e[1;31m[bootstrap ERROR]\e[0m %s\n' "$*" >&2; }

SITE_DIR=/opt/thinkingmachine-site
WEBHOOK_DIR=/opt/thinkingmachine-webhook
ENV_DIR=/etc/thinkingmachine
REPO_RAW=https://raw.githubusercontent.com/brunobozic/thinkingmachine-site/main

# ---- Step 1: immediate deploy ----
log "Pulling latest site image and rolling container"
if [ ! -d "$SITE_DIR" ]; then
  err "$SITE_DIR not found — check where the site compose lives and edit SITE_DIR above"
  exit 1
fi
cd "$SITE_DIR"
docker compose pull thinkingmachine-site
docker compose up -d thinkingmachine-site
docker image prune -f >/dev/null 2>&1 || true
log "Site image rolled. Verifying HTTP..."
sleep 3
if curl -fsSI -o /dev/null -w "live HTTP_%{http_code}\n" --max-time 10 http://127.0.0.1/; then
  log "Container responding."
else
  err "Container didn't respond on :80 — investigate before proceeding"
  exit 1
fi

# ---- Step 2: webhook token ----
log "Generating webhook token"
mkdir -p "$ENV_DIR"
chmod 700 "$ENV_DIR"
if [ ! -f "$ENV_DIR/webhook.env" ]; then
  TOKEN=$(openssl rand -hex 32)
  printf 'WEBHOOK_TOKEN=%s\n' "$TOKEN" > "$ENV_DIR/webhook.env"
  chmod 600 "$ENV_DIR/webhook.env"
  log "New token generated."
else
  TOKEN=$(grep -E '^WEBHOOK_TOKEN=' "$ENV_DIR/webhook.env" | cut -d= -f2-)
  log "Existing webhook.env reused."
fi

# ---- Step 3: webhook receiver files ----
log "Installing webhook receiver to $WEBHOOK_DIR"
mkdir -p "$WEBHOOK_DIR/scripts"
curl -fsSL "$REPO_RAW/infra/webhook/docker-compose.yml" -o "$WEBHOOK_DIR/docker-compose.yml"
curl -fsSL "$REPO_RAW/infra/webhook/hooks.yaml" -o "$WEBHOOK_DIR/hooks.yaml"
curl -fsSL "$REPO_RAW/infra/webhook/scripts/redeploy.sh" -o "$WEBHOOK_DIR/scripts/redeploy.sh"
chmod +x "$WEBHOOK_DIR/scripts/redeploy.sh"

# ---- Step 4: bring it up ----
log "Starting webhook container"
cd "$WEBHOOK_DIR"
docker compose pull
docker compose up -d
log "Webhook container running. Traefik should be issuing a cert for hooks.thinkingmachine.uk now."

# ---- Step 5: tell the user what to wire up ----
cat <<EOF

═════════════════════════════════════════════════════════════════════════
✓ Auto-deploy is now installed on this VPS.
═════════════════════════════════════════════════════════════════════════

Two one-time wiring steps remain — copy these into the right places:

1) Cloudflare DNS — add this A record (proxied = OFF):

     hooks.thinkingmachine.uk    A    178.105.104.173

2) GitHub repo secrets — Settings → Secrets and variables → Actions:

     WEBHOOK_URL    = https://hooks.thinkingmachine.uk/hooks/redeploy
     WEBHOOK_TOKEN  = $TOKEN

3) After Cloudflare propagation (~30 seconds), verify from anywhere:

     curl -i -X POST \\
       -H "Authorization: Bearer $TOKEN" \\
       https://hooks.thinkingmachine.uk/hooks/redeploy

   Expect: 200 OK with body "redeploy triggered".

═════════════════════════════════════════════════════════════════════════

From now on, every push to main automatically deploys to this VPS.
No more manual docker compose pull.

EOF
