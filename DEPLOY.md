# Deployment runbook

## Overview

```
┌──────────┐  git push   ┌────────────────┐  build+push  ┌──────────────┐
│  local   │────────────▶│  GitHub Actions │─────────────▶│  ghcr.io     │
└──────────┘             └────────────────┘              └──────┬───────┘
                                                                │ docker pull
                                                                ▼
                                          ┌──────────────────────────────┐
                                          │  VPS — Traefik + nginx (TLS) │
                                          │  https://thinkingmachine.uk  │
                                          └──────────────────────────────┘
```

## One-time setup

### 1. GHCR access on the VPS

The image is published to `ghcr.io/brunobozic/thinkingmachine-site` (private package, auth required to pull).

On the VPS:

```bash
# Create a fine-grained GitHub Personal Access Token with read:packages scope.
# Store the value somewhere safe; you'll need it for `docker login`.
echo "$GHCR_PAT" | docker login ghcr.io -u brunobozic --password-stdin
```

`/root/.docker/config.json` will now contain the credentials. Watchtower (if used) will re-use them.

### 2. DNS

Point `thinkingmachine.uk` (and optionally `www.thinkingmachine.uk`) to the VPS public IP. Verify with `dig +short thinkingmachine.uk`.

### 3. Traefik wildcard cert

Confirm your existing Traefik configuration has a `certresolver` (e.g. `letsencrypt`) that can issue or already holds a wildcard cert for `*.thinkingmachine.uk`. The compose file references `certresolver=letsencrypt` — adjust if yours is named differently.

### 4. Drop the service into the VPS compose stack

Copy `docker-compose.example.yml` into your existing stack (or merge the `services:` block).

```bash
docker compose pull thinkingmachine-site
docker compose up -d thinkingmachine-site
```

The container should come up healthy within ~30 seconds. Verify:

```bash
docker compose ps thinkingmachine-site
docker compose logs --tail=50 thinkingmachine-site
curl -I https://thinkingmachine.uk/
```

## Routine deployment (after every commit to `main`)

The CI workflow (`.github/workflows/deploy.yml`) automatically builds and pushes a new image on each push to `main`. To pick it up on the VPS:

### Option A — manual pull (default)

```bash
docker compose pull thinkingmachine-site
docker compose up -d thinkingmachine-site
```

### Option B — Watchtower (auto-update)

Add Watchtower to your stack to poll GHCR and roll forward automatically:

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /root/.docker/config.json:/config.json:ro
    command: --interval 300 --cleanup --label-enable
    networks:
      - traefik
```

Then label the site service with `com.centurylinklabs.watchtower.enable=true` (already commented in `docker-compose.example.yml` — uncomment if using Watchtower).

### Option C — webhook (instant)

For instant deploys, run a small webhook receiver on the VPS (e.g. [adnanh/webhook](https://github.com/adnanh/webhook)) that runs `docker compose pull && docker compose up -d` on receipt. The CI workflow has a commented `notify-vps` job ready to wire up — just uncomment and add `WEBHOOK_URL` and `WEBHOOK_TOKEN` to repo Secrets.

## Rollback

Every commit to `main` produces an image tagged with the commit SHA (in addition to `latest`). To roll back:

```bash
# Find the previous SHA
docker image ls ghcr.io/brunobozic/thinkingmachine-site

# Pin compose to a specific SHA temporarily
# Edit docker-compose.yml, change `:latest` to `:abc1234`, then:
docker compose up -d thinkingmachine-site
```

For a permanent rollback, revert the offending commit on `main` and let CI rebuild.

## Health & observability

- **Container health**: Docker `HEALTHCHECK` runs `wget -q --spider http://127.0.0.1/` every 30s.
- **HTTP**: nginx access/error logs go to stdout/stderr — scraped by your existing Docker log driver.
- **TLS**: Traefik handles cert lifecycle.

For external uptime monitoring, point UptimeRobot or similar at `https://thinkingmachine.uk/`.

## First-run checklist

- [ ] Repo cloned locally, `npm install`, `npm run build` succeeds
- [ ] First commit pushed to `main`; CI workflow goes green
- [ ] `ghcr.io/brunobozic/thinkingmachine-site:latest` is visible under your GitHub Packages
- [ ] DNS for `thinkingmachine.uk` resolves to the VPS
- [ ] `docker compose up -d thinkingmachine-site` succeeds on the VPS
- [ ] Traefik routes the host to the container (check `docker logs traefik`)
- [ ] `curl -I https://thinkingmachine.uk/` returns `HTTP/2 200`
- [ ] Browser load shows the site with valid TLS

## Where things live

| What | Where |
|---|---|
| Source code | this repo |
| CI workflow | `.github/workflows/deploy.yml` |
| Image registry | `ghcr.io/brunobozic/thinkingmachine-site` |
| VPS compose service | `docker-compose.example.yml` (template) |
| TLS / routing | Traefik on the VPS |
| DNS | wherever you registered `thinkingmachine.uk` |
