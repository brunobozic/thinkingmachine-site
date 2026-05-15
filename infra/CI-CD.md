# CI/CD — full pipeline reference

Single source of truth for how a `git push origin main` becomes a live update
at <https://thinkingmachine.uk>.

## Pipeline at a glance

```
git push origin main
        │
        ▼
GitHub Actions: .github/workflows/deploy.yml
        │
        ├─ build-and-push job:
        │   ├─ checkout
        │   ├─ docker buildx build (Dockerfile = npm install + astro build + nginx-alpine wrap)
        │   ├─ tag :latest and :<short-sha>
        │   └─ push → GHCR (ghcr.io/brunobozic/thinkingmachine-site)
        │
        └─ notify-vps job (if WEBHOOK_URL secret is set):
            └─ POST https://hooks.thinkingmachine.uk/hooks/redeploy
                Authorization: Bearer ${{ secrets.WEBHOOK_TOKEN }}
                    │
                    ▼
            VPS (tm-webhook container, adnanh/webhook):
            ─ validates bearer token (constant-time)
            ─ runs /scripts/redeploy.sh which does:
              docker compose pull thinkingmachine-site
              docker compose up -d thinkingmachine-site
              docker image prune -f
                    │
                    ▼
            https://thinkingmachine.uk now serves the new image.
            Traefik picks up the swap with zero downtime.
```

Total elapsed: **90–120 seconds** from push to verified live.

## Fallback if the webhook isn't wired

The `notify-vps` job degrades gracefully — if `WEBHOOK_URL` or `WEBHOOK_TOKEN`
are missing from repo secrets, it logs a warning and exits 0 (doesn't fail the
workflow). In that case you need to SSH and pull manually:

```bash
ssh <deploy_user>@<vps>
cd /opt/thinkingmachine-site
docker compose pull && docker compose up -d
```

## Required GitHub repo secrets

| Secret | Purpose |
|---|---|
| `DEPLOY_SSH_KEY` | Private SSH key matching deploy user's `authorized_keys` on the VPS |
| `DEPLOY_HOST` | VPS IP or DNS name |
| `DEPLOY_USER` | Non-root deploy user (member of the `docker` group only — no sudo) |
| `GITHUB_TOKEN` | Built-in, automatically scoped to this repo. Used for GHCR push. |

Optional:
- `CAL_BOOKING_PATH` — could be wired as build-time env if you want to flip the
  contact CTA without editing the file. Currently the constant is in
  `src/pages/contact.astro` directly.

## Containers

### Site container

- **Base image:** `nginx:alpine`
- **Build context:** repo root
- **Dockerfile:** `Dockerfile`
- **Image tag:** `ghcr.io/brunobozic/thinkingmachine-site:latest`
- **Also tagged:** `ghcr.io/brunobozic/thinkingmachine-site:<git-sha>` for rollback
- **Exposed port:** 80 (internal; only Traefik reaches it)
- **Traefik labels** (set in `infra/thinkingmachine-site/docker-compose.yml`):
  - `traefik.enable=true`
  - `traefik.http.routers.tm.rule=Host(\`thinkingmachine.uk\`) || Host(\`www.thinkingmachine.uk\`)`
  - `traefik.http.routers.tm.tls.certresolver=letsencrypt`
  - `traefik.http.middlewares.tm-redirect-www.redirectregex.regex=^https?://www\.thinkingmachine\.uk/(.*)`
  - `traefik.http.middlewares.tm-redirect-www.redirectregex.replacement=https://thinkingmachine.uk/$$1`
  - `traefik.http.middlewares.tm-redirect-www.redirectregex.permanent=true`
  - `traefik.http.routers.tm.middlewares=secure-headers@file,compress@file,rate-limit-default@file,tm-redirect-www`

### Traefik

- **Image:** `traefik:v3.x`
- **Persistent volume:** `/letsencrypt` for ACME state (`acme.json`)
- **Network:** `traefik_proxy` bridge (shared with site container)
- **Entry points:**
  - `web` (port 80) — redirects to `websecure`
  - `websecure` (port 443) — TLS termination, ACME TLS-ALPN-01

## Health-check and rollback

The workflow's last step:
```bash
curl --fail --silent --show-error https://thinkingmachine.uk/ | grep "Thinking Machine"
```

If this fails, the workflow fails — but the previous container keeps running
because `docker compose up -d` only swaps the container if the new image pulls
successfully. So you don't get a half-deployed broken site.

**Manual rollback:** SSH to the VPS, find the previous image SHA tag from
`docker image ls`, edit `docker-compose.yml` to pin that tag instead of
`:latest`, `docker compose up -d`. Edit takes 10 seconds; container swap
takes another 5.

## TLS / Let's Encrypt

- Resolver name in `traefik.yml`: `letsencrypt`
- Challenge: `tlsChallenge: {}` (TLS-ALPN-01 on port 443)
- Email: `hello@thinkingmachine.uk`
- Storage: `/letsencrypt/acme.json` (persistent volume; back up if you migrate VPS)
- Renewal: automatic ~60 days before expiry; Traefik handles silently

**CAA records** (Cloudflare DNS) restrict who can issue certificates for the
domain:
```
thinkingmachine.uk.    CAA   0   issue       "letsencrypt.org"
thinkingmachine.uk.    CAA   0   issuewild   "letsencrypt.org"
thinkingmachine.uk.    CAA   0   iodef       "mailto:hello@thinkingmachine.uk"
```

Tested via <https://caatest.co.uk/thinkingmachine.uk>.

## How to make a change land live

1. Edit the relevant `.astro` / `.md` / `.css` file
2. `npm run check && npm run build` locally to catch errors
3. `git add` the specific files (not `git add .` unless you're sure)
4. `git commit -m "<topic>: <one-line>"` with a structured multi-paragraph body
   if the change is non-trivial
5. `git push origin main`
6. Wait 90–120 seconds
7. `curl -s https://thinkingmachine.uk/ | grep "<expected-content>"` to verify

If step 6 doesn't show the change after 3 minutes, check the GitHub Actions
tab: <https://github.com/brunobozic/thinkingmachine-site/actions>

## How to migrate the VPS (e.g. to a new Hetzner instance)

1. Provision new VPS with `infra/bootstrap.sh`
2. Run `infra/hardening.sh` then `hardening-2.sh` then `hardening-3.sh`
3. Copy the deploy public key into the deploy user's `.ssh/authorized_keys`
4. **Restore the ACME state**: copy `acme.json` from the old VPS into
   `/letsencrypt/` on the new one (preserves the existing cert; saves a
   re-issuance roundtrip)
5. `docker compose up -d` on both stacks
6. Update DNS A record on Cloudflare to point to the new IP
7. Update GitHub secret `DEPLOY_HOST` to the new IP
8. Trigger a manual deploy via the GitHub Actions UI (Workflow → Run workflow)
9. Verify
10. Decommission old VPS

## Cost envelope

- Hetzner CX11 / CX22 (small enough — site is static, single container) —
  €3–5/month
- GitHub Actions minutes — well within free tier for this volume
- GHCR storage — well within free tier
- Cloudflare DNS — free tier
- Let's Encrypt — free
- **Total:** about €4/month all-in. The "no analytics, no CRM, no newsletter"
  position is also a cost decision.
