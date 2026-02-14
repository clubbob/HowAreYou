import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: '개인정보처리방침 - 지금 어때',
  description: '지금 어때 서비스의 개인정보처리방침입니다.',
};

const EMAIL = 'clubbob@naver.com';

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-white">
      <div className="mx-auto max-w-3xl px-6 py-12 md:py-16">
        <div className="mb-8">
          <Link href="/" className="text-primary-600 hover:underline">
            ← 홈으로
          </Link>
        </div>
        <h1 className="mb-8 text-2xl font-bold text-gray-900">개인정보처리방침</h1>

        <div className="prose prose-gray max-w-none space-y-8">
          <section>
            <h2 className="text-lg font-semibold text-gray-900">1. 수집 항목</h2>
            <ul className="mt-2 list-inside list-disc space-y-1 text-gray-700">
              <li>이메일 (베타 신청 시)</li>
              <li>전화번호 (회원가입 시)</li>
              <li>상태 기록 데이터 (앱 사용 시)</li>
              <li>기기 정보 (푸시 알림용)</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-gray-900">2. 수집 목적</h2>
            <ul className="mt-2 list-inside list-disc space-y-1 text-gray-700">
              <li>안부 기록 저장 및 보호자 알림 제공</li>
              <li>베타 테스트·출시 안내 (이메일)</li>
              <li>서비스 운영 및 개선</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-gray-900">3. 보관 기간</h2>
            <p className="mt-2 text-gray-700">
              사용자 탈퇴 시 해당 정보를 삭제합니다. 법령에 따라 보존이 필요한 경우 해당 기간 동안 보관합니다.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-gray-900">4. 제3자 제공 여부</h2>
            <p className="mt-2 text-gray-700">
              개인정보를 제3자에게 제공하지 않습니다. (단, 법령에 의한 요청 시 예외)
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-gray-900">5. 이용자 권리 (열람·삭제)</h2>
            <p className="mt-2 text-gray-700">
              이용자는 본인의 개인정보에 대해 열람·정정·삭제를 요청할 수 있습니다. 문의처로 요청하시면 처리해 드립니다.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-gray-900">6. 문의처</h2>
            <p className="mt-2 text-gray-700">
              이메일: <a href={`mailto:${EMAIL}`} className="text-primary-600 hover:underline">{EMAIL}</a>
            </p>
          </section>

          <section>
            <h2 className="text-lg font-semibold text-gray-900">7. 시행일</h2>
            <p className="mt-2 text-gray-700">
              2026년 2월 15일
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
