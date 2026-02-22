import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '문의 확인 - 오늘 어때',
  description: '1:1 문의 답변을 확인하세요.',
};

export default function InquiryCheckLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
