# memory.md — Working memory across Claude sessions

Decisions, integrations, infrastructure details, and ongoing context. Skim this
first when picking up the project after a break. Source of truth for "where does
X live, who decided Y, and what was the reasoning Z".

---

## 1. Identity & legal

- **Company:** Thinking Machine d.o.o.
- **Founder & sole principal:** Bruno Božić (`bruno.bozic@gmail.com`)
- **Founded:** 2022
- **OIB (Croatian tax ID):** 62472822484
- **MB (Croatian company registration number):** 5637031
- **Registered office:** Zagorska ulica 11, 10000 Zagreb, Croatia
- **Site:** <https://thinkingmachine.uk> (single domain; `.eu` was the original,
  switched in commit `843004d`)
- **Repo:** <https://github.com/brunobozic/thinkingmachine-site> (private)
- **LinkedIn:** <https://www.linkedin.com/in/bruno-bo%C5%BEi%C4%87-74245876/>
- **GitHub:** <https://github.com/brunobozic>
- **Concurrent role:** Head of IoT at Reos GmbH, Hamburg, Germany. Thinking
  Machine is the channel for selective external advisory engagements that do
  not conflict with that role.

## 2. Infrastructure — full stack

### Hetzner Cloud VPS

- **Provider:** Hetzner Cloud (Falkenstein region — German data centre, EU
  data residency)
- **OS:** Ubuntu LTS
- **Provisioning:** `infra/bootstrap.sh` — one-shot installer for docker,
  docker-compose-plugin, ufw, fail2ban, unattended-upgrades
- **Hardening:** `infra/hardening.sh` + `infra/hardening-2.sh` +
  `infra/hardening-3.sh` — progressive layers of:
  - SSH: PermitRootLogin no, PasswordAuthentication no, key-only on a
    non-default port; AllowUsers limited
  - UFW: deny incoming default; allow 22 (SSH), 80 (HTTP→HTTPS redirect), 443
    (HTTPS) only
  - fail2ban: SSH + nginx-403 + nginx-noscript jails active
  - unattended-upgrades: security-only, daily; reboot at 02:30 if needed
  - sysctl hardening: standard CIS-flavoured tweaks
  - Cloud-init disabled post-first-boot

### Actual VPS layout (verified 2026-05-15)

**Note:** the repo's `infra/` folder is the *template*. The real VPS uses
`/srv/` not `/opt/`. The deploy ecosystem on the VPS itself:

| Path | Purpose |
|---|---|
| `/srv/thinkingmachine-site/docker-compose.yml` | Site container compose stack |
| `/srv/traefik/docker-compose.yml` | Traefik reverse proxy stack |
| `/srv/traefik/traefik.yml` | Traefik static config (entry points, ACME) |
| `/srv/traefik/dynamic.yml` | Traefik dynamic config (CSP, HSTS, rate limit, **webhook routing**) |
| `/srv/traefik/letsencrypt/acme.json` | TLS cert state — back up if migrating |
| `/srv/thinkingmachine-webhook/` | Holds webhook receiver compose stack (now unused — see note below) |
| `/etc/thinkingmachine/webhook.env` | `WEBHOOK_TOKEN=…` (mode 600, root only) |
| `/etc/webhook.yml` | adnanh/webhook hook definition |
| `/etc/systemd/system/tm-webhook.service` | systemd unit running webhook on host |
| `/usr/local/bin/tm-redeploy.sh` | Script the webhook calls to pull + roll |

**Webhook architecture (final, working).** We initially tried running
adnanh/webhook as a Docker container. It failed because the container is
Alpine-based and can't execute the host's dynamically-linked `docker` binary.
The working setup is **adnanh/webhook running on the host as a systemd unit**
(installed via `apt install webhook`), bound to `0.0.0.0:9001`. UFW allows
port 9001 only from the Docker bridge subnet `172.18.0.0/16`. Traefik's
dynamic.yml defines a path-based router at `Host(thinkingmachine.uk) &&
PathPrefix(/_webhook)` that proxies to `http://172.18.0.1:9001` (the bridge
gateway, which routes to the host). This means **no new subdomain DNS was
needed** — the webhook reuses the existing TLS cert.

### Containers on the VPS

Two compose stacks share the `traefik` docker bridge network:

1. **Traefik** at `/srv/traefik/` — reverse proxy, TLS terminator. Mounts
   `traefik.yml` and `dynamic.yml` from the host. ACME state persisted at
   `/srv/traefik/letsencrypt/acme.json`.
2. **Site container** at `/srv/thinkingmachine-site/` — runs
   `ghcr.io/brunobozic/thinkingmachine-site:latest`. Traefik labels route
   `thinkingmachine.uk` and `www.thinkingmachine.uk` here; www → apex 301.

Both stacks share the `traefik` (not `traefik_proxy`) docker bridge network.
Nothing else is exposed publicly. Webhook routing is a Traefik file-provider
entry, not a docker label.

### TLS / certificates

- **Issuer:** Let's Encrypt (production endpoint)
- **Challenge:** ACME TLS-ALPN-01 (configured in `traefik.yml`)
- **Renewal:** automatic via Traefik; rotates ~60 days before expiry
- **CAA records** on Cloudflare DNS restrict issuance to Let's Encrypt only:
  ```
  thinkingmachine.uk.    CAA   0   issue       "letsencrypt.org"
  thinkingmachine.uk.    CAA   0   issuewild   "letsencrypt.org"
  thinkingmachine.uk.    CAA   0   iodef       "mailto:hello@thinkingmachine.uk"
  ```
  These were added via Cloudflare dashboard (task #25–#27 in the history).
- **TLS options** (`infra/traefik/dynamic.yml`):
  - Min version: TLS 1.2
  - sniStrict: true
  - Cipher suites: TLS 1.3 AEAD + ECDHE-AES-GCM/ChaCha20 for TLS 1.2
  - Curves: X25519, P-384

### DNS

- **Registrar:** [TBD — Bruno owns this; not stored in repo]
- **DNS managed by:** Cloudflare
- **Apex (`thinkingmachine.uk`):** A record → Hetzner VPS public IP
- **`www`:** A record → same IP; Traefik redirects to apex
- **MX / TXT:** [Bruno-managed, not relevant for site deploy]
- **CAA:** as above
- **DNSSEC:** [check — was on the to-do; verify on the Cloudflare side]

### Security headers (Traefik `dynamic.yml`)

Current full CSP:
```
default-src 'self';
script-src 'self' 'unsafe-inline';
style-src 'self' 'unsafe-inline';
font-src 'self';
img-src 'self' data:;
connect-src 'self';
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
object-src 'none';
upgrade-insecure-requests
```

Plus:
- HSTS: 1 year, includeSubdomains, preload, force
- Permissions-Policy: geolocation, microphone, camera, payment, usb, interest-cohort all denied
- X-Frame-Options: SAMEORIGIN (Traefik also frameDeny)
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin
- Cross-Origin-Opener-Policy: same-origin
- Cross-Origin-Resource-Policy: same-origin
- `Server` and `X-Powered-By` blanked

`nginx.conf` adds an inner defensive layer:
- Rate limit: 10 r/s per IP, burst 20
- Connection limit: 30 concurrent per IP
- Body limits: 32 KB max, 4×8 KB large_client_header_buffers
- Timeouts: client_body/header 10 s, send 20 s
- gzip on for text types

## 3. CI/CD pipeline — every step

File: `.github/workflows/deploy.yml`. Triggers on push to `main`.

1. **Checkout** the repo (full history not needed; shallow is fine)
2. **Setup Node** (Node 20)
3. **`npm ci`** — clean install from `package-lock.json`
4. **`npm run check`** — `astro check` validates TypeScript + content collections
5. **`npm run build`** — produces `dist/`. This step generates:
   - All HTML pages (EN/DE/HR)
   - Sitemap (`sitemap-index.xml`, `sitemap-0.xml`)
   - RSS feed at `/rss.xml`
   - Per-page OG images under `/og/*.png` (via astro-og-canvas + canvaskit-wasm)
6. **Build Docker image** using `Dockerfile`:
   - Base: `nginx:alpine`
   - Copies `dist/` to `/usr/share/nginx/html`
   - Copies `nginx.conf` to `/etc/nginx/nginx.conf`
   - Tag: `ghcr.io/brunobozic/thinkingmachine-site:latest` (and SHA tag)
7. **Push to GHCR** using `GITHUB_TOKEN` (built-in, scoped to this repo)
8. **SSH to Hetzner VPS** using a deploy key (stored as `DEPLOY_SSH_KEY` secret;
   public key on the VPS in the deploy user's `.ssh/authorized_keys`)
9. **On the VPS**, the workflow runs:
   ```
   docker login ghcr.io …
   docker pull ghcr.io/brunobozic/thinkingmachine-site:latest
   docker compose -f /opt/thinkingmachine-site/docker-compose.yml up -d
   docker image prune -f
   ```
10. **Health check:** workflow curls `https://thinkingmachine.uk/` and asserts
    HTTP 200 + the title contains "Thinking Machine"

Typical end-to-end: **90–120 seconds**. If the workflow fails, the previous
container keeps running — no half-deployed states.

### Required GitHub secrets

- `DEPLOY_SSH_KEY` — private key for VPS access
- `DEPLOY_HOST` — VPS IP or hostname
- `DEPLOY_USER` — non-root deploy user (has docker group membership only)
- `GHCR_TOKEN` — optional; usually the default `GITHUB_TOKEN` is sufficient

### Required GitHub repo settings

- Dependabot enabled (`.github/dependabot.yml`) for npm + docker + GHA updates
- Branch protection on `main` — direct push allowed only by Bruno; PRs
  require check pass

## 4. Integrations / MCPs we have used

| MCP / Tool | What we used it for | Notes |
|---|---|---|
| `mcp__workspace__bash` | Sandbox bash (Linux) for read-only git ops, file inspection, curl checks | Cannot write to `.git/` (mount policy). Has limited network — `npm install` may hang. |
| `mcp__workspace__web_fetch` | Live-site verification after deploys | Provenance-restricted: can only fetch URLs that have appeared in user messages or prior fetches. |
| `mcp__Desktop_Commander__start_process` | **Primary** path for git ops on Windows | Spawns cmd.exe / powershell.exe on Bruno's real machine. Use this for any git command. |
| `mcp__Desktop_Commander__interact_with_process` | Interactive REPL (Python, node) on Bruno's machine | Useful for in-place data work, but `Start-Process`-style one-shot scripts are usually more reliable. |
| `mcp__cowork__create_artifact` | Not used here — would be for live HTML dashboards | |
| `mcp__cowork__request_cowork_directory` | Not invoked — user has provided the repo path | |
| Edit / Write / Read | All file edits go through these | They write to the Windows filesystem path; sandbox bash sees the same files at the mapped Linux path. |
| Gmail MCP (`mcp__3af42882…`) | Drafted testimonial-request email to Hans de Raad | Draft is in Bruno's Gmail Drafts folder; awaiting reply. |
| Claude in Chrome MCP | Browser verification of short+expand interaction across EN/DE/HR | Used in earlier session (task #56). |
| `mcp__scheduled-tasks__*` | Not currently used; available if a recurring brief is wanted | |
| GitHub MCP (`mcp__plugin_engineering_github__*`) | Was identified as a fallback for commit-via-API if local git is blocked. Not currently used — HTTPS + Git Credential Manager works. | |

## 5. External services attached to the site

| Service | Used for | Where it's wired |
|---|---|---|
| **Cloudflare DNS** | DNS hosting, CAA records | Bruno's Cloudflare account |
| **Let's Encrypt** | TLS certificates | ACME TLS-ALPN-01 via Traefik |
| **GitHub** | Source repo + CI/CD + GHCR | repo: brunobozic/thinkingmachine-site |
| **Hetzner Cloud** | VPS hosting | Falkenstein region |
| **Gmail** (`hello@thinkingmachine.uk`) | Inbound contact email | Gmail-hosted; MX records on Cloudflare |
| **Cal.com** | NOT yet activated — scaffold in place | Wire by setting `CAL_BOOKING_PATH` in `src/pages/contact.astro` and updating Traefik CSP |
| **No analytics** | Deliberate. No GA, no Plausible, no Fathom. The footer claim "No trackers. No newsletter. No CRM." is honest. |
| **No newsletter** | As above. |
| **No CRM** | As above. |

## 6. Gotchas index (full detail in AGENTS.md)

Quick reference — if you hit one of these symptoms, see AGENTS.md for the fix:

1. **`Filename too long` on git ops** → `git config --global core.longpaths true`
2. **Sandbox can't write `.git/`** → use Desktop Commander on the Windows shell
3. **Local working tree stale** → clone fresh to `C:\tm-fresh`, overlay edits, push
4. **SSH key denied to GitHub** → switch remote to HTTPS, use Git Credential Manager
5. **`&` invocation produces no output in PowerShell** → use `Start-Process cmd /c … > outfile`
6. **`.bat` has empty PATH** → `set PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%` at top
7. **Content collection schema strips unknown fields** → declare every frontmatter field in `src/content/config.ts`
8. **`**bold**` renders literally in Quick reads** → see the inline regex Markdown processor in the work renderer
9. **Trailing-slash 404 or TLS downgrade** → don't change one of nginx + Astro + sitemap; they must agree
10. **hreflang to 404** → only add a path to `TRANSLATED_PATHS` after all locales are live
11. **JSON-LD `inLanguage` was hardcoded** → never hardcode; reference `localeMeta.lang`
12. **Astro `<script>` is build-time** → emit JSON-LD via `<script set:html={…} />`
13. **mailto: is temporary** → Cal.com scaffold is in place, gated on a single constant
14. **"we" is a stylistic choice** → don't rewrite to "I"
15. **Don't re-add Google Fonts CDN** → fonts are self-hosted via @fontsource
16. **astro-og-canvas first-install downloads ~7 MB WASM** → expected
17. **Don't commit `dist/`** → gitignored; double-check the index
18. **Quick reads target 200–280 words** → sanity-check word count
19. **Run anonymisation regex sweep before push** → see AGENTS.md §19
20. **CI takes 90–120s from push to live** → wait that long before web-fetch verification

## 7. Outstanding work (current punch list)

- **Hans de Raad testimonial** — Gmail draft prepared (task #53). Awaiting reply.
- **Alem Bišćan testimonial** — Need Bruno to provide company name + email.
- **Cal.com activation** — Bruno signs up at cal.com, gets the booking path, sets
  `CAL_BOOKING_PATH` in `src/pages/contact.astro`, updates Traefik CSP.
- **Phone / Signal / WhatsApp on /contact** — waiting for Bruno's channel choice.
- **OG brand-mark logo** (optional) — drop 200×200 PNG at `public/og-logo.png`,
  uncomment in `src/pages/og/[...route].png.ts`.
- **DNSSEC verification** — check Cloudflare is signing the zone.

## 8. Major historical decisions

| When | What | Why |
|---|---|---|
| 2026-05-09 | Switched domain `.eu` → `.uk` | Better brand availability + UK is an attractive secondary market |
| 2026-05-09 | Astro `build.format: 'file'` + `trailingSlash: 'never'` + nginx no-slash redirect | Canonical / sitemap / served URLs all agree; no TLS-downgrade redirect chain |
| 2026-05-10 | Three-locale i18n (EN/DE/HR) | German market is the practice's largest opportunity; Croatian is home market |
| 2026-05-11 | Anonymisation: sector descriptor only, never names | Reference embargo is reality; consistency builds trust |
| 2026-05-12 | Five named methodology techniques as the brand-tier value prop | "We rent the library, not the labour to build it" |
| 2026-05-13 | Short+expand Quick read pattern across case studies | Long bodies were burying the hook; pattern doubles expected scroll depth |
| 2026-05-14 | Quick read rewrites: each opens with the most distinctive sentence | "Find the best sentence you've already written, promote it to the lead" |
| 2026-05-15 | Self-host fonts; per-page OG images; FAQ + Person + Article schema; trust ribbon; pricing anchor | Conversion + AI-search visibility + privacy + brand consistency |
| 2026-05-15 | `core.longpaths=true` set globally on Bruno's machine | Cowork session repo path was 214 chars; Windows MAX_PATH was breaking git ops |
| 2026-05-15 | Switched remote to HTTPS, use Git Credential Manager | None of the four `~/.ssh/` keys auth to GitHub; HTTPS+GCM works |

## 9. Brand tokens

- **Accent (primary):** `#1E3A8A` — deep blue (Tailwind `accent.700`)
- **Background:** `#FAFAF9` — warm off-white (`ink.50`)
- **Text dark:** `#18181B` (`ink.900`)
- **Text mid:** `#52525B` (`ink.700`)
- **Text light:** `#71717A` (`ink.500`)
- **Borders:** `#E4E4E7` (`ink.200`)
- **Serif (titles):** Source Serif 4
- **Sans (body):** Inter, weights 400 / 500 / 600

## 10. Editorial style notes

- **Tone:** calm, specific, never breathless. Avoid "passionate", "world-class",
  "industry-leading", "cutting-edge", "innovative".
- **Voice:** "we" is editorial first-person. Resolution on /about page makes
  it clear it's one principal plus named partners under sub-NDA.
- **Sentence rhythm:** prefer fragments and short paragraphs over long flowing
  prose. The two best fragments on the site are:
  - *"Starting posture: weak but not yet in breach."*
  - *"The deadlines do not move."*
  Both on the CRA-readiness case study Quick read.
- **Numbers:** every number that appears in user-facing text comes from the
  engagement scope, the published framework, or the Official Journal. No
  invented metrics.
- **Hedge language:** when a claim is qualitative ("typical", "usually",
  "around"), keep the hedge. Don't strip them in pursuit of "punchy" copy.
