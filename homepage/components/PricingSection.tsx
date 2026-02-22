'use client';

import { PRICING, formatPrice } from '@/lib/config/pricing';

const FEATURES = [
  '매일 안부 확인',
  '3일 기록 없을 시 즉시 통지',
  '보호자와 보호대상자를 자유롭게 연결',
  '1개월 무료 체험',
];

export function PricingSection() {
  const scrollToCta = () => {
    document.getElementById('cta')?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <section
      id="pricing"
      className="scroll-mt-20 bg-navy-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24"
    >
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-3 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:text-[1.75rem]">
          매일의 안부, 1년의 안심
        </h2>
        <p className="mb-8 text-center text-[15px] leading-[1.65] text-navy-600 sm:mb-12 sm:text-[17px]">
          <span className="block">1개월 무료로 충분히 사용해보세요.</span>
          <span className="block">계속 사용하실 경우에만 연 12,000원이 결제됩니다.</span>
          <span className="block">결제는 보호자만 진행합니다.</span>
        </p>

        <div className="rounded-2xl border border-navy-100 bg-white p-5 shadow-[0_2px_16px_rgba(31,42,68,0.06)] sm:p-6 md:p-8">
          <div className="mb-6 flex flex-col items-center">
            <span className="text-[2rem] font-bold text-primary-600 md:text-[2.5rem]">
              연 {formatPrice(PRICING.yearly)}
            </span>
            <span className="mt-1 text-[15px] text-navy-500">(한달 1,000원)</span>
          </div>

          <ul className="mb-6 space-y-2.5 sm:space-y-3">
            {FEATURES.map((f) => (
              <li key={f} className="flex items-start gap-3 text-[15px] leading-[1.5] text-navy-800 sm:text-[17px]">
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
            <p>언제든지 스토어에서 구독을 해지할 수 있습니다.</p>
            <p className="font-medium text-navy-600">부담 없이 시작하세요.</p>
          </div>

          <button
            type="button"
            onClick={scrollToCta}
            className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600"
          >
            1개월 무료로 안심 시작하기
          </button>
        </div>
      </div>
    </section>
  );
}
