import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Vercel Output Directory가 build/web으로 고정된 상태라 빌드 출력 위치를 맞춤
  distDir: 'build/web',
};

export default nextConfig;
