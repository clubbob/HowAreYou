import type { Metadata } from 'next';
import { Suspense } from 'react';

export const metadata: Metadata = {
  title: '1:1 문의 - 지금 어때',
  description: '지금 어때 서비스 이용 중 궁금한 점을 문의해 주세요.',
};

export default function InquiryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <Suspense fallback={<div className="min-h-[400px]" />}>{children}</Suspense>;
}
