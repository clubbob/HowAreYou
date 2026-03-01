import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '서비스 개선 - 오늘 어때',
  description: '더 나은 안심을 위해, 여러분의 의견이 오늘 어때를 더 단단하게 만듭니다.',
};

export default function ServiceImprovementLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}
