# thinkingmachine-site

Public marketing site for **Thinking Machine d.o.o.** — built with Astro, Tailwind CSS, and content collections; deployed as a static container behind Traefik.

> **Domain:** [thinkingmachine.uk](https://thinkingmachine.uk)
> **Stack:** Astro 5 · Tailwind 3 · TypeScript · nginx (runtime)
> **Deployment:** Docker image published to GHCR via GitHub Actions; pulled by VPS behind Traefik.

## Local development

```bash
npm install
npm run dev          # http://localhost:4321
npm run build        # static output to ./dist
npm run preview      # serve ./dist locally
```

Requires Node 20+.

## Project structure

```
src/
├── components/        # Reusable .astro components (Header, Footer, cards)
├── content/
│   ├── config.ts      # Content collection schemas
│   └── case-studies/  # Anonymised client engagements (markdown)
├── layouts/
│   └── BaseLayout.astro
├── pages/             # File-based routing
│   ├── index.astro
│   ├── services.astro
│   ├── about.astro
│   ├── contact.astro
│   └── work/
│       ├── index.astro
│       └── [...slug].astro
└── styles/
    └── global.css
public/                # Static assets (favicon, etc.)
```

## Adding a new case study

1. Create `src/content/case-studies/<slug>.md`.
2. Add frontmatter — see existing files for the schema (title, sector, engagementType, year, region, summary, featured, draft).
3. Run `npm run build` to validate, then commit.

The case study will be picked up automatically by `/work` (index) and `/work/<slug>` (detail).

## Confidentiality discipline

Case studies must contain **no** client names, project names, internal codenames, named individuals, or specific currency figures. Sector descriptors only. The anonymisation rules are the same as in the source-of-truth copy under `outputs/site-copy/00-README.md` — see that file for the operating doctrine before adding new case studies.

## Deployment

See [`DEPLOY.md`](./DEPLOY.md) for the full runbook. Short version: push to `main`, GitHub Actions builds and publishes a Docker image to `ghcr.io/brunobozic/thinkingmachine-site:latest`, the VPS pulls and restarts.

## License

All rights reserved. Proprietary. Not licensed for redistribution.

---

*© Thinking Machine d.o.o. · Zagreb, Croatia · Founded 2022*
