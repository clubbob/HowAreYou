import type { Metadata } from 'next';
import Link from 'next/link';
import { PRIVACY_CONTENT } from '@/lib/legal-content';

export const metadata: Metadata = {
  title: '개인정보처리방침 - 지금 어때',
  description: '지금 어때 서비스의 개인정보처리방침입니다.',
};

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-[#F7F8FA]">
      <div className="mx-auto max-w-3xl px-6 py-20">
        <Link
          href="/"
          className="mb-10 inline-flex items-center gap-1 text-[17px] font-medium text-primary-400 transition-colors hover:text-primary-500"
        >
          ← 홈으로
        </Link>
        <h1 className="mb-10 text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          개인정보처리방침
        </h1>
        <div className="whitespace-pre-line text-[17px] leading-[1.6] text-navy-700">
          {PRIVACY_CONTENT}
        </div>
      </div>
    </main>
  );
}
