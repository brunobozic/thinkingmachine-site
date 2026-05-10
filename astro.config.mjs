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
  // i18n: English-default at /, German at /de/, Croatian at /hr/.
  // Routes for /de/ and /hr/ are accessible by URL but not yet linked from
  // the header — soft-launched while translations are reviewed.
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'de', 'hr'],
    routing: { prefixDefaultLocale: false }
  }
});
