'use client';

import { PRICING, formatPrice } from '@/lib/config/pricing';

const FEATURES = [
  '보호대상자 무제한 추가',
  '매일 안부 알림',
  '3일 무응답 통지',
  '1개월 무료 체험 (계정 생성일 기준)',
];

export function PricingSection() {
  const scrollToCta = () => {
    document.getElementById('cta')?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <section
      id="pricing"
      className="scroll-mt-20 bg-navy-50 px-6 py-20 md:py-24"
      style={{ paddingTop: '5rem', paddingBottom: '5rem' }}
    >
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-3 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          요금 안내
        </h2>
        <p className="mb-12 text-center text-[17px] leading-[1.6] text-navy-600">
          1개월 무료 체험 후 연 결제됩니다.
          <br />
          결제는 보호자만 진행합니다.
        </p>

        <div className="rounded-2xl border border-navy-100 bg-white p-6 shadow-[0_2px_16px_rgba(31,42,68,0.06)] md:p-8">
          <div className="mb-6 flex items-baseline justify-center gap-2">
            <span className="text-[2rem] font-bold text-primary-600 md:text-[2.5rem]">
              연 {formatPrice(PRICING.yearly)}
            </span>
          </div>

          <ul className="mb-6 space-y-3">
            {FEATURES.map((f) => (
              <li key={f} className="flex items-center gap-3 text-[17px] text-navy-800">
                <span className="inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-primary-100 text-primary-600">
                  <svg className="h-3 w-3" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </span>
                {f}
              </li>
            ))}
          </ul>

          <div className="mb-8 space-y-1 text-center text-[14px] text-navy-500">
            <p>결제는 보호자만 진행합니다.</p>
            <p>언제든지 앱 내 &apos;구독 관리&apos; 메뉴에서 해지할 수 있습니다.</p>
          </div>

          <button
            type="button"
            onClick={scrollToCta}
            className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600"
          >
            1개월 무료로 시작하기
          </button>
        </div>
      </div>
    </section>
  );
}
