import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://thinkingmachine.uk',
  output: 'static',
  trailingSlash: 'never',
  integrations: [
    tailwind({ applyBaseStyles: false }),
    sitemap()
  ],
  build: {
    // 'file' writes /services.html (not /services/index.html). Combined with
    // trailingSlash: 'never', this means canonical URLs, sitemap entries, and
    // the URLs nginx actually serves all agree -- no 301-redirect chain that
    // dropped to plain HTTP under TLS termination.
    format: 'file',
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
