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
      colors: {
        primary: {
          50: '#f0f7f4',
          100: '#d9ede4',
          200: '#b8ddce',
          300: '#8bc9b4',
          400: '#5fb398',
          500: '#3d9d7f',
          600: '#2d7d63',
          700: '#246350',
          800: '#1f5142',
          900: '#1c4337',
          950: '#0d241c',
        },
        cream: {
          50: '#faf9f7',
          100: '#f5f3f0',
          200: '#ebe8e3',
        },
      },
      boxShadow: {
        soft: '0 2px 12px rgba(0,0,0,0.04)',
        card: '0 4px 20px rgba(0,0,0,0.06)',
        elevated: '0 8px 32px rgba(0,0,0,0.08)',
      },
    },
  },
  plugins: [],
};
export default config;
