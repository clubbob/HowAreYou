import { ImageResponse } from 'next/og';

export const alt = '지금 어때';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (typeof process.env.VERCEL_URL === 'string'
    ? `https://${process.env.VERCEL_URL}`
    : 'https://howareyou.kr');

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
          background: 'linear-gradient(135deg, #E8F4F8 0%, #F0F9FC 100%)',
        }}
      >
        <img
          src={`${siteUrl}/logo.png`}
          alt="지금 어때"
          width={358}
          height={358}
          style={{ objectFit: 'contain' }}
        />
      </div>
    ),
    { ...size }
  );
}
