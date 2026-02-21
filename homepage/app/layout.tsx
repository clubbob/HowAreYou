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
  title: '여기 어때?',
  description: '',
  openGraph: {
    title: '여기 어때?',
    description: '',
    url: siteUrl,
    siteName: '지금 어때',
    images: [
      {
        url: `${siteUrl}/logo.png`,
        width: 400,
        height: 400,
        alt: '지금 어때',
      },
    ],
    locale: 'ko_KR',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: '여기 어때?',
    description: '',
    images: [`${siteUrl}/logo.png`],
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
  const ogImageUrl = `${siteUrl}/logo.png`;
  return (
    <html lang="ko" className="scroll-smooth">
      <head>
        <link rel="icon" href="/logo.png" type="image/png" sizes="512x512" />
        {/* 링크 미리보기: 카카오톡 등 크롤러용 명시적 메타 태그 */}
        <meta property="og:image" content={ogImageUrl} />
        <meta property="og:image:width" content="512" />
        <meta property="og:image:height" content="512" />
        <meta property="og:title" content="여기 어때?" />
        <meta property="og:description" content="" />
        <meta property="og:url" content={siteUrl} />
        <meta name="twitter:card" content="summary_large_image" />
        <meta name="twitter:image" content={ogImageUrl} />
        <meta name="twitter:title" content="여기 어때?" />
      </head>
      <body className="min-h-screen overflow-x-hidden bg-[#F7F8FA] text-navy-900 antialiased">{children}</body>
    </html>
  );
}
