# Webhook receiver — auto-deploy on every CI build

Closes the deploy loop: every push to `main` builds an image and the VPS pulls
it automatically. No SSH-and-pull dance, no Watchtower polling.

## Architecture

```
git push main
   │
   ▼
GitHub Actions  (.github/workflows/deploy.yml)
   │
   ├─ docker build → push to ghcr.io
   │
   └─ notify-vps job: POST https://hooks.thinkingmachine.uk/hooks/redeploy
                       (Authorization: Bearer $WEBHOOK_TOKEN)
                           │
                           ▼
              Traefik on the VPS
                           │
                           ▼
              tm-webhook container (adnanh/webhook)
              ─ validates bearer token
              ─ runs /scripts/redeploy.sh
                           │
                           ▼
              docker compose pull && up -d   (site container)
                           │
                           ▼
              https://thinkingmachine.uk now serves the new build
```

Total elapsed from `git push` to live: ~90 seconds (CI build is the long pole;
the actual VPS-side pull-and-roll is ~5 seconds).

## One-time VPS setup

You will do this **once** per VPS. Future deploys are fully automatic.

### 1. Generate a webhook token

```bash
openssl rand -hex 32
```

Copy the resulting string. You'll need it in two places (step 2 and step 3).

### 2. Store the token on the VPS

```bash
sudo mkdir -p /etc/thinkingmachine
sudo tee /etc/thinkingmachine/webhook.env >/dev/null <<EOF
WEBHOOK_TOKEN=<paste-token-here>
EOF
sudo chmod 600 /etc/thinkingmachine/webhook.env
```

### 3. Store the same token in GitHub Secrets

GitHub repo → Settings → Secrets and variables → Actions → New repository secret:

| Name | Value |
|---|---|
| `WEBHOOK_URL` | `https://hooks.thinkingmachine.uk/hooks/redeploy` |
| `WEBHOOK_TOKEN` | `<paste-the-same-token>` |

### 4. Add DNS

In Cloudflare DNS, add:

```
hooks.thinkingmachine.uk    A   <VPS public IP>   (Proxied: yes)
```

Wait ~30 seconds for propagation.

### 5. Make sure the site stack is in `/opt/thinkingmachine-site/`

The redeploy script expects the site compose stack here:

```bash
sudo mkdir -p /opt/thinkingmachine-site
# Copy your existing docker-compose.yml here, e.g. from infra/thinkingmachine-site/docker-compose.yml
```

### 6. Bring up the webhook receiver

```bash
cd <path-to-this-repo-on-vps>/infra/webhook
docker compose up -d
```

Traefik will pick up the new container automatically and issue a certificate
for `hooks.thinkingmachine.uk`. First request may take a few seconds while the
cert is issued.

### 7. Verify

```bash
curl -i -X POST \
  -H "Authorization: Bearer <your-token>" \
  https://hooks.thinkingmachine.uk/hooks/redeploy
```

Expected response: `HTTP/2 200` with body `redeploy triggered`.

You should immediately see the site container rolling in `docker ps`:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

If you see `tm-webhook` listed and the response was 200, the wiring is done.

### 8. Uncomment the `notify-vps` job in CI

In `.github/workflows/deploy.yml`, uncomment the `notify-vps` block. After
this commit lands, the next push to `main` will trigger auto-deploy.

## What can go wrong (and how to debug)

### "401 Unauthorized" from the webhook

Token mismatch between the env file on the VPS and the GitHub secret. Run
`docker compose logs tm-webhook` on the VPS to see the inbound request and
the expected value.

### "redeploy triggered" but site doesn't update

`/scripts/redeploy.sh` ran but failed silently. Check container logs:

```bash
docker compose logs tm-webhook --tail=100
```

Common causes:
- Docker socket not mounted (compose can't reach docker daemon) — verify
  `/var/run/docker.sock` volume is present.
- GHCR pull auth missing — run `docker login ghcr.io` on the VPS once.
- The site compose stack isn't at `/opt/thinkingmachine-site/` — adjust the
  volume mount in `infra/webhook/docker-compose.yml`.

### CI workflow times out trying to POST

The Cloudflare DNS for `hooks.thinkingmachine.uk` isn't pointing at the VPS,
or the cert hasn't issued yet. Manual test with curl first (step 7) — if that
works, GitHub Actions will work too.

## Security posture

- **Auth:** bearer token, constant-time match via adnanh/webhook's
  trigger-rule. Token is 32 bytes of random (256 bits). Token is never
  logged anywhere it could leak.
- **Authz:** the webhook only does one thing — pull and roll one specific
  container. The script is read-only mounted into the container. Even if
  the token leaks, the blast radius is "force a pull of an image you can
  already see on GHCR." No shell access, no arbitrary command exec.
- **Rate limit:** Traefik's `rate-limit-default` middleware applies (100 r/min
  average, 200 burst).
- **TLS:** Let's Encrypt cert via Traefik, same as the main site.
- **Docker socket exposure:** the webhook container has read-write access to
  `/var/run/docker.sock`. This is the standard adnanh/webhook + docker pattern;
  mitigated by the bearer-token gate and the narrow scope of the script.
  If you want defence-in-depth, switch to `socket-proxy` (Tecnativa/docker-socket-proxy)
  with `CONTAINERS=1 IMAGES=1 EXEC=0`.

## Rolling back

The redeploy script always pulls `:latest`. To roll back:

1. SSH to the VPS.
2. Edit `/opt/thinkingmachine-site/docker-compose.yml` and pin the image to
   a specific SHA: `image: ghcr.io/brunobozic/thinkingmachine-site:abc1234`
3. `docker compose up -d thinkingmachine-site`
4. Disable the webhook temporarily if you want to prevent auto-recovery to
   `:latest`: `docker compose -f infra/webhook/docker-compose.yml stop`
