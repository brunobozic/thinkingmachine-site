# CLAUDE.md — Project context for Claude sessions

This file is the canonical brief that any Claude session should read first when
working on the Thinking Machine site. It captures the *why*, the *how*, and the
non-obvious decisions that shape every file in the repo.

## What this is

The marketing and methodology site for **Thinking Machine d.o.o.**, a one-principal
strategic engineering advisory based in Zagreb, Croatia. Founder: **Bruno Božić**.
Live at <https://thinkingmachine.uk>.

Positioning: boutique, fixed-scope, decision-grade work for compliance-sensitive
enterprises. Three lanes — cloud cost & FinOps, cyber resilience & NFR / CRA / NIS2
advisory, AI integration for established systems. Adjacent capabilities: database
performance rescue, legacy modernisation, interim leadership, LIMS / lab automation.

Engagement shapes:
- **Discovery Sprint** — 1–2 weeks fixed fee, from €5,000
- **Rapid PoC** — 2–4 weeks fixed fee, from €14,000
- **Fractional CTO** — monthly retainer, from €5,000/month

Three locales: English (default at `/`), German (`/de/`), Croatian (`/hr/`).
Translations are native, not machine-generated; treat them as first-class content.

## Editorial constraints

- **Anonymisation is absolute.** No client names. No product names. No individual
  names beyond the founder. The standing forbidden-terms list includes
  Opennovations, Therapeer, MedCall, Alem, Vrdoljak, DACH, LiveKit, DeepFilterNet,
  Aker BP, Zeek, BMWK, STRABAG, SimonsVoss, ParkEfficient, Valhall, Yggdrasil,
  DROPS, and "psychotherapy" (use "mental-health consultations" instead).
  When in doubt, use the sector descriptor only.
- **Every load-bearing claim is sourced.** Numbers come from the engagement scope
  or a published framework; methodology pages cite verbatim from the Official
  Journal where regulation is referenced.
- **No invented testimonials.** Reference embargo language is intentional. The
  Gmail draft for Hans de Raad is the channel for the first attributable quote.
- **Tone is calm and specific.** Avoid superlatives, "passionate", "world-class",
  marketing clichés. Prefer named techniques (Position of Record, propagation
  matrix, L/I/B classification, four-category cost taxonomy, triangulated baseline)
  over generic claims of expertise.

## Tech stack — at a glance

- **Astro 5.x** static site generator, `output: 'static'`, `trailingSlash: 'never'`,
  `build.format: 'file'` (writes `/services.html` not `/services/index.html`)
- **Tailwind CSS 3** with `@tailwindcss/typography`
- **TypeScript** throughout
- **Content collections** for case studies and notes (Zod schemas in
  `src/content/config.ts`)
- **i18n**: `defaultLocale: 'en'`, `locales: ['en','de','hr']`,
  `prefixDefaultLocale: false`. Locale routing is handled by parallel page
  trees under `src/pages/de/` and `src/pages/hr/`.
- **Self-hosted fonts** via `@fontsource/inter` + `@fontsource-variable/source-serif-4`
  (imported in `src/styles/global.css`). NO Google Fonts CDN — privacy + "No
  trackers" footer claim.
- **Per-page OG images** via `astro-og-canvas` at `src/pages/og/[...route].png.ts`
- **`@astrojs/sitemap`** generates `/sitemap-index.xml` referenced from `robots.txt`
- **Native RSS** at `src/pages/rss.xml.ts`

## Repo geography

```
.
├── astro.config.mjs            # Astro config — output, i18n, build.format
├── tailwind.config.mjs         # Tailwind theme — brand palette
├── nginx.conf                  # Container nginx — security headers, rate limits
├── Dockerfile                  # Build → static site → nginx-alpine
├── docker-compose.example.yml  # Local dev compose
├── infra/
│   ├── bootstrap.sh            # VPS provisioning (one-shot)
│   ├── hardening.sh            # VPS security hardening
│   ├── traefik/                # Edge reverse proxy + TLS termination
│   │   ├── docker-compose.yml
│   │   ├── traefik.yml         # Static config
│   │   └── dynamic.yml         # CSP, HSTS, rate limit, TLS options
│   └── thinkingmachine-site/
│       └── docker-compose.yml  # Site container on the VPS
├── public/
│   ├── og-image.png            # Default OG (1200x630)
│   ├── og-image.svg            # Source for the default OG
│   ├── favicon.svg
│   ├── robots.txt              # Allows everything; references sitemap-index.xml
│   └── .well-known/
│       └── security.txt        # RFC 9116 disclosure contact
├── src/
│   ├── content/
│   │   ├── config.ts           # Zod schemas for case-studies + notes
│   │   ├── case-studies/
│   │   │   ├── *.md            # EN case studies
│   │   │   ├── de/*.md         # DE case studies
│   │   │   └── hr/*.md         # HR case studies
│   │   └── notes/*.md          # EN-only methodology notes
│   ├── layouts/
│   │   └── BaseLayout.astro    # Title/meta/JSON-LD/header/footer
│   ├── components/
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── CaseStudyCard.astro
│   │   ├── CaseStudyNumbersStrip.astro
│   │   ├── CRARegulatoryClock.astro
│   │   └── SupplyChainCaseStudyCharts.astro
│   ├── pages/
│   │   ├── index.astro         # EN home
│   │   ├── services.astro
│   │   ├── pricing.astro
│   │   ├── process.astro
│   │   ├── about.astro
│   │   ├── contact.astro
│   │   ├── 404.astro
│   │   ├── work/
│   │   │   ├── index.astro
│   │   │   └── [...slug].astro
│   │   ├── notes/
│   │   │   ├── index.astro
│   │   │   └── [...slug].astro
│   │   ├── og/
│   │   │   └── [...route].png.ts  # Per-page OG image generator
│   │   ├── de/                 # German parallel tree
│   │   │   ├── index.astro
│   │   │   ├── services.astro
│   │   │   ├── pricing.astro
│   │   │   ├── about.astro
│   │   │   ├── contact.astro
│   │   │   └── work/
│   │   ├── hr/                 # Croatian parallel tree
│   │   ├── rss.xml.ts          # /rss.xml endpoint
│   │   └── sitemap.xml         # (auto-generated by @astrojs/sitemap)
│   ├── styles/
│   │   └── global.css          # Tailwind + @fontsource imports + brand tokens
│   ├── i18n/
│   │   └── paths.ts            # TRANSLATED_PATHS registry + hreflang helper
│   └── env.d.ts
├── .github/
│   ├── workflows/
│   │   └── deploy.yml          # CI/CD — build, push to GHCR, ssh deploy
│   └── dependabot.yml
└── package.json
```

## How to add content

**A new case study** — drop `src/content/case-studies/<slug>.md` plus
`src/content/case-studies/de/<slug>.md` and `src/content/case-studies/hr/<slug>.md`.
Frontmatter must include `title`, `sector`, `engagementType`, `year`, `region`,
`summary`. Optional but recommended: `quickRead` (marketing-grade short summary
rendered above the collapsible full body) and `publishedAt` (drives the Article
schema's datePublished).

The renderer at `src/pages/work/[...slug].astro` automatically generates Article
JSON-LD when `publishedAt` is present, and a per-page OG image via
`/og/work-<slug>.png` (locale-neutral across EN/DE/HR — same thumbnail).

**A new note** — drop `src/content/notes/<slug>.md`. Notes are EN-only.
Frontmatter: `title`, `summary`, `publishedAt` (required), `tags`. The renderer
adds an Article JSON-LD node, a visible "By Bruno Božić · Verified as of …"
byline, and a per-page OG image at `/og/notes-<slug>.png`.

**A new static page** — copy an existing page (e.g. `pricing.astro`) and update
the title/description in the BaseLayout call. If translations exist or are
planned, add the path to `TRANSLATED_PATHS` in `src/i18n/paths.ts` so hreflang
alternates render correctly.

## Build commands

```
npm install
npm run dev       # localhost:4321 with HMR
npm run build     # produces dist/
npm run preview   # serves dist/ locally
npm run check     # astro check (TypeScript + content collection validation)
```

`@fontsource/*` and `astro-og-canvas` + `canvaskit-wasm` are bundled at build
time. First `npm install` pulls down canvaskit's ~7 MB WASM into node_modules
cache; subsequent installs are fast.

## What's still on the punch list

- Hans de Raad testimonial — Gmail draft prepared; awaiting reply
- Alem Bišćan testimonial — waiting for Bruno to provide company name + email
- Cal.com activation — Bruno sets `CAL_BOOKING_PATH` in `src/pages/contact.astro`
  and updates Traefik CSP to allow `app.cal.com`
- Optional brand-mark logo for the OG image template (drop a 200×200 PNG at
  `public/og-logo.png` and uncomment the `logo` block in `src/pages/og/[...route].png.ts`)
- Phone / Signal / WhatsApp contact option on /contact (waiting for Bruno to
  decide the channel and number)

## When changing the site

1. **Read `AGENTS.md` for the operating rules.**
2. Make the edit. If it's content, mirror across EN/DE/HR or note explicitly that
   one locale is being held back.
3. Run `npm run check` and `npm run build` locally. The build must be green.
4. Commit with a structured message. The commits in this repo's history are
   templates worth following — multi-section, each section a heading.
5. Push to `main`. **CI auto-deploys** — see `infra/CI-CD.md` for the full
   pipeline (also summarised in `AGENTS.md` §22).
6. **After ~90 seconds**, run `bash infra/verify-all-pages.sh` from any shell
   with curl. All 41 URLs should return 200 with content markers present.

## Deploy + ops at a glance (no surprises)

| Thing | Where |
|---|---|
| Production VPS | Hetzner `tm-prod-fsn1` at `178.105.104.173` (Falkenstein, CX23) |
| SSH access | `ssh tm-prod` — key at `~/.ssh/hetzner_tm`, alias in `~/.ssh/config` |
| Site compose stack on VPS | `/srv/thinkingmachine-site/docker-compose.yml` |
| Traefik compose stack on VPS | `/srv/traefik/docker-compose.yml` |
| Traefik dynamic config (CSP, webhook routing) | `/srv/traefik/dynamic.yml` |
| Let's Encrypt cert state | `/srv/traefik/letsencrypt/acme.json` |
| Deploy webhook (systemd unit on host) | `tm-webhook` listening on `0.0.0.0:9001` |
| Webhook hook definition | `/etc/webhook.yml` |
| Webhook token | `/etc/thinkingmachine/webhook.env` (mode 600) |
| Redeploy script the webhook runs | `/usr/local/bin/tm-redeploy.sh` |
| Public deploy webhook URL | `https://thinkingmachine.uk/_webhook/hooks/redeploy` |
| GitHub repo secrets | `WEBHOOK_URL`, `WEBHOOK_TOKEN` (both set) |
| CI workflow | `.github/workflows/deploy.yml` — `build-and-push` + `notify-vps` |
| Container registry | `ghcr.io/brunobozic/thinkingmachine-site:latest` (+ `:sha`) |
| DNS | Cloudflare-managed; A record points direct to VPS (no proxy) |

To verify the loop end-to-end at any time:

```bash
# Sanity-check: trigger a deploy manually with the bearer token
ssh tm-prod "grep WEBHOOK_TOKEN /etc/thinkingmachine/webhook.env"
TOKEN="...paste..."
curl -i -X POST -H "Authorization: Bearer $TOKEN" https://thinkingmachine.uk/_webhook/hooks/redeploy
# Expect HTTP 200 "redeploy triggered". Check logs:
ssh tm-prod 'journalctl -u tm-webhook --since "1 minute ago" --no-pager'
```
