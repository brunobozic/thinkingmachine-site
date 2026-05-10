// Shared registry of which paths are available in which locales.
// As more pages are translated, add their no-locale-prefix path here.
//
// Used by:
//   - Header.astro (switcher: where to send user when clicking EN|DE|HR)
//   - BaseLayout.astro (hreflang: which alternates are real vs missing)
//
// Format: paths are written WITHOUT a locale prefix and WITHOUT trailing slash.
// '/' is the home page. '/services' is the services page in the active locale.

export const SUPPORTED_LOCALES = ['en', 'de', 'hr'] as const;
export type Locale = (typeof SUPPORTED_LOCALES)[number];

// Set of paths that exist in DE and HR. EN is the default and always exists.
export const TRANSLATED_PATHS = new Set<string>([
  '/',
  '/services',
  '/about',
  '/contact',
]);

export function isTranslated(pathInsideLocale: string): boolean {
  return TRANSLATED_PATHS.has(pathInsideLocale);
}

// Build a URL for a given locale. If the target locale doesn't have this page,
// fall back to the locale home (avoids 404s from the language switcher).
export function buildLocaleUrl(locale: Locale, pathInsideLocale: string): string {
  const targetPath = TRANSLATED_PATHS.has(pathInsideLocale) ? pathInsideLocale : '/';
  if (locale === 'en') return targetPath;
  return targetPath === '/' ? `/${locale}` : `/${locale}${targetPath}`;
}
