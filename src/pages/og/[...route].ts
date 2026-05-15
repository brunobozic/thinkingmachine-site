// Per-page OG image generator.
//
// Generates a branded 1200×630 PNG per case study and per note, with the page
// title baked into the image. Hugely improves LinkedIn / Slack / Twitter card
// click-through versus the default /og-image.png shared by every page.
//
// Build behaviour: astro-og-canvas hooks getStaticPaths() so every key in
// `pages` produces a static .png at build time. URLs land at:
//   /og/work-<slug>.png   (case studies; locale-neutral — same image across EN/DE/HR
//                          since the OG thumbnail isn't translated UI)
//   /og/notes-<slug>.png  (notes; EN-only — there are no DE/HR notes)
//
// Wiring: src/pages/work/[...slug].astro and the locale variants pass
// ogImage={`/og/work-${bareSlug}.png`} to BaseLayout. src/pages/notes/[...slug].astro
// passes ogImage={`/og/notes-${slug}.png`}. Static pages (home/services/about/contact/
// pricing) continue to use the default /og-image.png.
//
// Dependencies: astro-og-canvas + canvaskit-wasm. Both pinned in package.json.
// First build downloads canvaskit (~7 MB WASM) into node_modules cache; later
// builds are fast.

import { OGImageRoute } from 'astro-og-canvas';
import { getCollection } from 'astro:content';

const cases = await getCollection('case-studies', (e) => !e.data.draft);
const notes = await getCollection('notes', (e) => !e.data.draft);

// One entry per case study (locale-neutral; the EN canonical slug). Locale
// variants share the same image to avoid 3× the build cost for what is a
// preview thumbnail.
const caseEntries = cases
  .filter((c) => !c.slug.startsWith('de/') && !c.slug.startsWith('hr/'))
  .map((c) => [
    `work-${c.slug}`,
    {
      title: c.data.title,
      description: c.data.summary,
      kind: 'Case study',
      sector: c.data.sector,
      year: c.data.year,
    },
  ] as const);

const noteEntries = notes.map((n) => [
  `notes-${n.slug}`,
  {
    title: n.data.title,
    description: n.data.summary,
    kind: 'Note',
    sector: '',
    year: '',
  },
] as const);

const pages = Object.fromEntries([...caseEntries, ...noteEntries]);

// Brand palette — kept in sync with global.css and tailwind.config theme.
const ACCENT = '#1E3A8A'; // accent.700 (deep blue)
const INK_900 = '#18181B'; // primary text
const INK_500 = '#71717A'; // muted text
const BG = '#FAFAF9'; // ink.50 (page background)

export const { getStaticPaths, GET } = OGImageRoute({
  param: 'route',
  pages,
  getImageOptions: (_path, page) => ({
    title: page.title,
    description: page.description,
    bgGradient: [
      [250, 250, 249], // BG
      [245, 245, 244], // subtle gradient toward bottom for depth
    ],
    border: {
      color: [30, 58, 138], // ACCENT in RGB
      width: 8,
      side: 'inline-start',
    },
    padding: 72,
    font: {
      title: {
        size: 64,
        families: ['Source Serif 4', 'Georgia', 'serif'],
        weight: 'SemiBold',
        color: [24, 24, 27], // INK_900
        lineHeight: 1.1,
      },
      description: {
        size: 26,
        families: ['Inter', 'sans-serif'],
        weight: 'Normal',
        color: [82, 82, 91], // INK_500-700 range
        lineHeight: 1.4,
      },
    },
    // No `logo` key set — astro-og-canvas errors with `fs.open(undefined)`
    // when `logo` is an object with no `path`. When a square brand mark
    // becomes available, drop a 200×200 PNG at public/og-logo.png and add
    // (don't comment-in):
    //   logo: { path: './public/og-logo.png', size: [120, 120] }
  }),
});
