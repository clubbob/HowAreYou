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
    <footer className="border-t border-primary-100/80 bg-white/80 px-6 py-14 backdrop-blur-sm">
      <div className="mx-auto max-w-2xl">
        {/* 회사 정보 */}
        <div className="mb-8 grid gap-4 text-sm text-primary-700/90 sm:grid-cols-2">
          <div>
            <p className="font-semibold text-primary-900">
              {FOOTER_INFO.company}
              <span className="ml-1 font-normal text-primary-600/80">({FOOTER_INFO.businessNumber})</span>
            </p>
            <p className="mt-0.5">대표: {FOOTER_INFO.representative}</p>
            <p>개인정보 보호책임자: {FOOTER_INFO.privacyOfficer}</p>
          </div>
          <div>
            <p>
              <span className="font-medium text-primary-800">문의</span>
            </p>
            <a href={`mailto:${FOOTER_INFO.email}`} className="block text-primary-600 hover:text-primary-800">
              {FOOTER_INFO.email}
            </a>
            <a href={`tel:${FOOTER_INFO.phone.replace(/-/g, '')}`} className="block text-primary-600 hover:text-primary-800">
              {FOOTER_INFO.phone}
            </a>
          </div>
        </div>

        {/* 링크 */}
        <div className="mb-8 flex flex-wrap gap-6">
          <Link
            href="/privacy"
            className="text-sm font-medium text-primary-600 transition-colors hover:text-primary-800"
          >
            개인정보처리방침
          </Link>
          <Link
            href="/terms"
            className="text-sm font-medium text-primary-600 transition-colors hover:text-primary-800"
          >
            이용약관
          </Link>
        </div>

        {/* 저작권 */}
        <p className="text-center text-sm text-primary-600/80">© 2026 지금 어때. All rights reserved.</p>
      </div>
    </footer>
  );
}
