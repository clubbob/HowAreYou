import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // 개발(dev): .next 사용 (EPERM 회피) / 프로덕션 빌드: build/web (Vercel 호환)
  distDir: process.env.NODE_ENV === 'production' ? 'build/web' : '.next',
  // Windows에서 webpack 캐시 파일 잠금(UNKNOWN/ENOENT) 오류 회피
  webpack: (config, { dev }) => {
    if (dev) config.cache = false;
    return config;
  },
};

export default nextConfig;
