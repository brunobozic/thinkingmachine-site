import typography from '@tailwindcss/typography';

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        serif: ['"Source Serif 4"', 'Georgia', 'ui-serif', 'serif']
      },
      colors: {
        ink: {
          50: '#FAFAF9',
          100: '#F5F5F4',
          200: '#E7E5E4',
          300: '#D6D3D1',
          500: '#78716C',
          700: '#44403C',
          800: '#292524',
          900: '#1C1917'
        },
        accent: {
          600: '#1E40AF',
          700: '#1E3A8A',
          800: '#172554'
        }
      },
      maxWidth: {
        prose: '720px',
        narrow: '640px',
        page: '1100px'
      },
      typography: ({ theme }) => ({
        DEFAULT: {
          css: {
            color: theme('colors.ink.800'),
            maxWidth: theme('maxWidth.prose'),
            fontFamily: theme('fontFamily.sans').join(','),
            fontSize: '1.0625rem',
            lineHeight: '1.7',
            'h1, h2, h3, h4': {
              fontFamily: theme('fontFamily.serif').join(','),
              color: theme('colors.ink.900'),
              letterSpacing: '-0.015em'
            },
            'h2': { marginTop: '2.5em' },
            'a': {
              color: theme('colors.accent.700'),
              textDecorationThickness: '1px',
              textUnderlineOffset: '3px'
            },
            'a:hover': { color: theme('colors.accent.800') },
            'strong': { color: theme('colors.ink.900') },
            'blockquote': {
              borderLeftColor: theme('colors.accent.700'),
              color: theme('colors.ink.700'),
              fontStyle: 'normal'
            },
            'code': {
              color: theme('colors.ink.900'),
              backgroundColor: theme('colors.ink.100'),
              padding: '0.125em 0.375em',
              borderRadius: '0.25rem',
              fontWeight: '500'
            },
            'code::before': { content: '""' },
            'code::after': { content: '""' }
          }
        }
      })
    }
  },
  plugins: [typography]
};
