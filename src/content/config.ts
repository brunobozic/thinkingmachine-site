import { defineCollection, z } from 'astro:content';

const caseStudies = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    sector: z.string(),
    engagementType: z.string(),
    year: z.string(),
    region: z.string(),
    summary: z.string(),
    // Marketing-grade short summary rendered above the collapsible full body.
    // Optional: studies without a quickRead fall back to rendering the full
    // body directly (see /work/[...slug].astro conditional).
    quickRead: z.string().optional(),
    publishedAt: z.string().optional(),
    featured: z.boolean().default(true),
    draft: z.boolean().default(false)
  })
});

const notes = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    summary: z.string(),
    publishedAt: z.string(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false)
  })
});

export const collections = {
  'case-studies': caseStudies,
  'notes': notes,
};
