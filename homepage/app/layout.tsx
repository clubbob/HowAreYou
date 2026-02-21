import type { Metadata } from 'next';
import './globals.css';

// 카카오톡 등 링크 미리보기: 실제 배포 URL 사용 (Vercel 자동 감지)
const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (typeof process.env.VERCEL_URL === 'string'
    ? `https://${process.env.VERCEL_URL}`
    : 'https://howareyou.kr');

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: '지금 어때 - 매일 전화 대신 3초로 확인',
  description:
    '매일 전화하지 않아도 됩니다. 하루 3초 기록으로 충분해요. 부모님도 부담 없이 사용할 수 있는 마음을 편하게 해주는 관계 습관 앱.',
  openGraph: {
    title: '지금 어때 - 매일 전화 대신 3초로 확인',
    description: '하루 3초 기록으로 가족 안부 확인. 부담 없는 안심 앱',
    url: siteUrl,
    siteName: '지금 어때',
    images: [
      {
        url: `${siteUrl}/logo.png`,
        width: 512,
        height: 512,
        alt: '지금 어때 로고',
      },
    ],
    locale: 'ko_KR',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: '지금 어때 - 매일 전화 대신 3초로 확인',
    description: '하루 3초 기록으로 가족 안부 확인. 부담 없는 안심 앱',
  },
  robots: {
    index: true,
    follow: true,
  },
  alternates: {
    canonical: siteUrl,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className="scroll-smooth">
      <head>
        <link rel="icon" href="/logo.png" type="image/png" sizes="512x512" />
      </head>
      <body className="min-h-screen overflow-x-hidden bg-[#F7F8FA] text-navy-900 antialiased">{children}</body>
    </html>
  );
}
