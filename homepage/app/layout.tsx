import type { Metadata } from 'next';
import './globals.css';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://howareyou.kr';

export const metadata: Metadata = {
  title: '지금 어때 - 하루 한 번, 안부를 남기세요',
  description:
    '갑작스러운 사고나 무응답 상황을 대비하는 가장 간단한 일상 기록 앱. 감시하지 않고, 평가하지 않고, 일상 확인만을 위한 구조입니다.',
  openGraph: {
    title: '지금 어때 - 하루 한 번, 안부를 남기세요',
    description:
      '갑작스러운 사고나 무응답 상황을 대비하는 가장 간단한 일상 기록 앱.',
    url: siteUrl,
    images: [{ url: `${siteUrl}/logo.png`, width: 512, height: 512, alt: '지금 어때 로고' }],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className="scroll-smooth">
      <body className="min-h-screen bg-cream-50 text-[#1a1a1a]">{children}</body>
    </html>
  );
}
