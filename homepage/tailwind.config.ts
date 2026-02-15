import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Noto Sans KR', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
      fontSize: {
        h1: ['2.25rem', { lineHeight: '1.3' }],
        'h1-lg': ['2.625rem', { lineHeight: '1.3' }],
        h2: ['1.75rem', { lineHeight: '1.4' }],
        body: ['1.0625rem', { lineHeight: '1.6' }],
        'body-lg': ['1.125rem', { lineHeight: '1.6' }],
      },
      colors: {
        primary: {
          50: '#E8F2FC',
          100: '#D1E5F9',
          200: '#A3CBF3',
          300: '#75B1ED',
          400: '#4A90E2',
          500: '#2E7BD6',
          600: '#1F5FA8',
          700: '#1F2A44',
          800: '#1A2439',
          900: '#151E2E',
        },
        navy: {
          50: '#F0F2F5',
          100: '#E0E4EA',
          200: '#C1C9D5',
          300: '#A2AEC0',
          400: '#8393AB',
          500: '#647896',
          600: '#4A5A72',
          700: '#1F2A44',
          800: '#1A2439',
          900: '#151E2E',
        },
      },
      spacing: {
        'section': '5rem',
        'section-lg': '6rem',
      },
      borderRadius: {
        card: '1rem',
        button: '0.75rem',
      },
    },
  },
  plugins: [],
};
export default config;
