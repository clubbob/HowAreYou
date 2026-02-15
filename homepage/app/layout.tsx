import type { Metadata } from 'next';
import './globals.css';

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://howareyou.kr';

export const metadata: Metadata = {
  title: '지금 어때 - 하루 한 번, 안부를 확인합니다',
  description:
    '혼자 있는 가족의 하루를 가볍게 확인할 수 있는 안부 서비스. 기록은 간단하게, 걱정은 줄어들게.',
  openGraph: {
    title: '지금 어때 - 하루 한 번, 안부를 확인합니다',
    description:
      '혼자 있는 가족의 하루를 가볍게 확인할 수 있는 안부 서비스.',
    url: siteUrl,
    siteName: '지금 어때',
    images: [{ url: `${siteUrl}/logo.png`, width: 512, height: 512, alt: '지금 어때 로고' }],
    locale: 'ko_KR',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: '지금 어때 - 하루 한 번, 안부를 확인합니다',
    description: '혼자 있는 가족의 하루를 가볍게 확인할 수 있는 안부 서비스.',
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
      <body className="min-h-screen bg-[#F7F8FA] text-navy-900 antialiased">{children}</body>
    </html>
  );
}
