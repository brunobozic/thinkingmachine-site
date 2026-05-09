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
    publishedAt: z.string().optional(),
    featured: z.boolean().default(true),
    draft: z.boolean().default(false)
  })
});

export const collections = {
  'case-studies': caseStudies
};
