import Link from 'next/link';

const FOOTER_INFO = {
  company: '새봄인터내셔널',
  businessNumber: '129-09-53285',
  representative: '박진희',
  privacyOfficer: '고형석',
  email: 'clubbob@naver.com',
  phone: '010-6391-4520',
};

export function Footer() {
  return (
    <footer className="border-t border-primary-100 bg-cream-100/80 px-6 py-14">
      <div className="mx-auto max-w-3xl space-y-5 text-center">
        {/* 이용약관 · 개인정보처리방침 */}
        <nav className="flex flex-wrap items-center justify-center gap-4">
          <Link
            href="/terms"
            className="text-sm font-medium text-primary-600 transition-colors hover:text-primary-800 hover:underline"
          >
            이용약관
          </Link>
          <Link
            href="/privacy"
            className="text-sm font-medium text-primary-600 transition-colors hover:text-primary-800 hover:underline"
          >
            개인정보처리방침
          </Link>
        </nav>

        {/* 회사명 · 대표 · 사업자등록번호 */}
        <p className="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-sm text-primary-700">
          <span>회사명 : {FOOTER_INFO.company}</span>
          <span>대표 : {FOOTER_INFO.representative}</span>
          <span>사업자등록번호 : {FOOTER_INFO.businessNumber}</span>
        </p>

        {/* 개인정보 보호책임자 · 이메일 · 연락처 */}
        <p className="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-sm text-primary-700">
          <span>개인정보 보호책임자 : {FOOTER_INFO.privacyOfficer}</span>
          <span>
            이메일 :{' '}
            <a href={`mailto:${FOOTER_INFO.email}`} className="text-primary-600 hover:underline">
              {FOOTER_INFO.email}
            </a>
          </span>
          <span>
            연락처 :{' '}
            <a href={`tel:${FOOTER_INFO.phone.replace(/-/g, '')}`} className="text-primary-600 hover:underline">
              {FOOTER_INFO.phone}
            </a>
          </span>
        </p>

        {/* Copyright */}
        <p className="pt-2 text-sm text-primary-500">
          Copyright © 2026 지금 어때. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
