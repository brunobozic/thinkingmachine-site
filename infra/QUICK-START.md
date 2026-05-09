# Server quick-start

Run these in order on a fresh Hetzner CX22 (Ubuntu 24.04 LTS) once you have its IP.

## 0. SSH in

```bash
ssh root@<server-ip>
```

## 1. Bootstrap (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/brunobozic/thinkingmachine-site/main/infra/bootstrap.sh | bash
```

If the repo is private and the script is therefore not publicly downloadable, paste the contents of `infra/bootstrap.sh` into the SSH session directly — it's just a shell script.

After bootstrap finishes, it prints your server's public IP. Copy it.

## 2. DNS — point thinkingmachine.uk at the server

In your DNS provider (Cloudflare Registrar's DNS panel, or wherever you registered):

```
thinkingmachine.uk      A   <server-ip>   proxied: OFF
www.thinkingmachine.uk  A   <server-ip>   proxied: OFF
```

If using Cloudflare, set proxy status to **DNS only** (grey cloud) — this is required for the Let's Encrypt HTTP-01 challenge to succeed. You can flip to proxied (orange cloud) later if you want CDN edge in front.

Verify propagation:

```bash
dig +short thinkingmachine.uk
```

Wait until it returns the server IP before continuing.

## 3. Drop Traefik config onto the server

Three files go to `/srv/traefik/` — `traefik.yml`, `dynamic.yml`, `docker-compose.yml`.

From your local machine, after the GitHub repo is populated:

```bash
# Variables
SERVER=<server-ip>

# Copy Traefik configs
scp infra/traefik/traefik.yml         root@$SERVER:/srv/traefik/traefik.yml
scp infra/traefik/dynamic.yml         root@$SERVER:/srv/traefik/dynamic.yml
scp infra/traefik/docker-compose.yml  root@$SERVER:/srv/traefik/docker-compose.yml

# Copy site compose
scp infra/thinkingmachine-site/docker-compose.yml \
    root@$SERVER:/srv/thinkingmachine-site/docker-compose.yml
```

## 4. Authenticate Docker against GHCR (one-time)

On GitHub: **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.

- Resource owner: brunobozic
- Repository access: only `thinkingmachine-site` is fine, OR all repositories
- Permissions: **Packages: Read** (read-only is enough)
- Expiration: 90 days, set a calendar reminder to rotate

Copy the token (shown once).

On the VPS:

```bash
echo "<paste-PAT-here>" | docker login ghcr.io -u brunobozic --password-stdin
```

Credentials persist in `/root/.docker/config.json`.

## 5. Bring up Traefik

```bash
cd /srv/traefik
docker compose up -d
docker compose logs -f traefik   # check for ACME activity, Ctrl-C when stable
```

The first time it runs, Traefik will request the cert from Let's Encrypt — usually under 10 seconds. Look for `acme.go ... obtained certificates`.

## 6. Bring up the site

```bash
cd /srv/thinkingmachine-site
docker compose pull
docker compose up -d
docker compose logs --tail=50 thinkingmachine-site
```

## 7. Verify

```bash
# From the VPS
curl -I http://127.0.0.1/

# From anywhere
curl -I https://thinkingmachine.uk/
```

You should see `HTTP/2 200`. Open the site in a browser to sanity-check.

## 8. Day-2: routine deploys

Every push to `main` produces a new `:latest` image. Pull and roll:

```bash
cd /srv/thinkingmachine-site
docker compose pull && docker compose up -d
```

Three lines, ~10 seconds of downtime (during which Traefik 502s briefly).
For zero-downtime, use Watchtower (label-enabled) or a webhook-driven deploy.

## Rollback

Every CI run also publishes a `:<commit-sha>` tag. To roll back to a known-good SHA:

```bash
cd /srv/thinkingmachine-site
# Edit docker-compose.yml: change `:latest` to `:abc1234` (the good SHA)
docker compose up -d
```

To restore `:latest`, edit back and `docker compose up -d` again.

## Health & monitoring

- **Container health**: built into Docker — `docker ps` shows healthy/unhealthy.
- **External uptime**: point UptimeRobot, Better Stack, or similar at `https://thinkingmachine.uk/`.
- **Cert renewal**: Traefik auto-renews 30 days before expiry — verify by watching the Traefik logs the day before any cert expires.

## File index

| File on VPS | Source | Purpose |
|---|---|---|
| `/srv/traefik/traefik.yml` | `infra/traefik/traefik.yml` | Static Traefik config |
| `/srv/traefik/dynamic.yml` | `infra/traefik/dynamic.yml` | TLS + middleware config (hot-reloaded) |
| `/srv/traefik/docker-compose.yml` | `infra/traefik/docker-compose.yml` | Traefik service definition |
| `/srv/traefik/letsencrypt/acme.json` | (created by Traefik) | Cert storage |
| `/srv/thinkingmachine-site/docker-compose.yml` | `infra/thinkingmachine-site/docker-compose.yml` | Site service definition |
