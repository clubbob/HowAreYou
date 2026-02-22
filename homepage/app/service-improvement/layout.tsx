import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '서비스 개선 - 지금 어때',
  description: '지금 어때 서비스에 대한 의견을 보내주세요.',
};

export default function ServiceImprovementLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
