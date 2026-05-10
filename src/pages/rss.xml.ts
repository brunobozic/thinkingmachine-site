// /rss.xml — minimal RSS 2.0 feed for Notes.
//
// Hand-written rather than using @astrojs/rss to keep the build dependency
// surface small. Astro renders endpoints with `.xml.ts` extension as static
// files at build time when `output: 'static'`.

import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

const SITE = 'https://thinkingmachine.uk';

const escape = (s: string): string =>
  s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');

export const GET: APIRoute = async () => {
  const notes = (await getCollection('notes', ({ data }) => !data.draft)).sort(
    (a, b) => b.data.publishedAt.localeCompare(a.data.publishedAt)
  );

  const items = notes
    .map(
      (n) => `    <item>
      <title>${escape(n.data.title)}</title>
      <link>${SITE}/notes/${n.slug}</link>
      <guid isPermaLink="true">${SITE}/notes/${n.slug}</guid>
      <pubDate>${new Date(n.data.publishedAt).toUTCString()}</pubDate>
      <description>${escape(n.data.summary)}</description>
      ${n.data.tags.map((t) => `<category>${escape(t)}</category>`).join('\n      ')}
    </item>`
    )
    .join('\n');

  const lastBuild = notes.length
    ? new Date(notes[0].data.publishedAt).toUTCString()
    : new Date().toUTCString();

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>Thinking Machine — Notes</title>
    <link>${SITE}/notes</link>
    <description>Cross-domain essays on engineering, integration, cost, and compliance.</description>
    <language>en-GB</language>
    <atom:link href="${SITE}/rss.xml" rel="self" type="application/rss+xml" />
    <lastBuildDate>${lastBuild}</lastBuildDate>
${items}
  </channel>
</rss>
`;

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/rss+xml; charset=utf-8',
      'Cache-Control': 'no-cache, must-revalidate',
    },
  });
};
