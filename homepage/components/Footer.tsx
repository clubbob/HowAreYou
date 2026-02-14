import Link from 'next/link';

const EMAIL = 'clubbob@naver.com';

export function Footer() {
  return (
    <footer className="border-t border-gray-200 bg-gray-50 px-6 py-10">
      <div className="mx-auto flex max-w-3xl flex-col items-center gap-4 text-center text-sm text-gray-600">
        <p>© 2026 지금 어때</p>
        <div className="flex flex-wrap justify-center gap-4">
          <Link href="/privacy" className="text-primary-600 hover:underline">
            개인정보처리방침
          </Link>
          <a href={`mailto:${EMAIL}`} className="text-primary-600 hover:underline">
            문의: {EMAIL}
          </a>
        </div>
      </div>
    </footer>
  );
}
