import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://thinkingmachine.eu',
  output: 'static',
  trailingSlash: 'never',
  integrations: [
    tailwind({ applyBaseStyles: false }),
    sitemap()
  ],
  build: {
    format: 'directory',
    inlineStylesheets: 'auto'
  },
  // i18n configuration intentionally deferred until Phase 5 (Croatian translations).
  // When ready, enable:
  // i18n: {
  //   defaultLocale: 'en',
  //   locales: ['en', 'hr'],
  //   routing: { prefixDefaultLocale: false }
  // }
});
