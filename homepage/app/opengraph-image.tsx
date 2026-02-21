import { ImageResponse } from 'next/og';

export const alt = '지금 어때';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (typeof process.env.VERCEL_URL === 'string'
    ? `https://${process.env.VERCEL_URL}`
    : 'https://how-are-you-nu.vercel.app');

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: '#F7F8FA',
        }}
      >
        <img
          src={`${siteUrl}/logo.png`}
          alt="logo"
          width={160}
          height={160}
          style={{ borderRadius: 24 }}
        />
      </div>
    ),
    { ...size }
  );
}
