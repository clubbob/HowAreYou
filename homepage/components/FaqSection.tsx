'use client';

import { useState } from 'react';
import { PRICING, formatPrice } from '@/lib/config/pricing';

const FAQ_ITEMS = [
  { q: '누가 결제하나요?', a: '보호자만 결제합니다. 보호대상자는 무료로 이용합니다.' },
  {
    q: '무료 체험은 어떻게 되나요?',
    a: `가입 후 1개월 동안 모든 기능을 무료로 이용할 수 있습니다. 이후 연 ${formatPrice(PRICING.baseYearly)}이 자동 결제됩니다.`,
  },
  {
    q: '보호대상자를 추가하면 얼마인가요?',
    a: `1명당 월 ${formatPrice(PRICING.extraMonthly)}(연 ${formatPrice(PRICING.extraYearly)})이 추가됩니다.`,
  },
  {
    q: '언제든 해지할 수 있나요?',
    a: '앱스토어에서 언제든 구독 해지가 가능합니다.',
  },
  {
    q: '위치 추적 기능이 있나요?',
    a: '위치 추적 기능은 제공하지 않습니다.',
  },
  {
    q: '알림은 몇 번 발송되나요?',
    a: '기록 시 보호자에게 알림이 발송되며, 3일간 기록이 없을 경우 1회 추가 알림이 발송됩니다.',
  },
  {
    q: '보호자는 어떤 기록을 볼 수 있나요?',
    a: '기본 화면에서는 최근 7일 기록이 우선 표시되며, 추가 조회를 통해 최대 30일까지 확인할 수 있습니다.',
  },
  {
    q: '탈퇴하면 데이터는 어떻게 되나요?',
    a: '회원 탈퇴 시 관련 데이터는 지체 없이 삭제됩니다.',
  },
];

export function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="bg-navy-50 px-6 py-20 md:py-24" style={{ paddingTop: '5rem', paddingBottom: '5rem' }}>
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          자주 묻는 질문
        </h2>

        <div className="space-y-3">
          {FAQ_ITEMS.map((item, i) => (
            <div
              key={i}
              data-mobile-faq-card
              className="group overflow-hidden rounded-[1rem] border border-navy-100 bg-white shadow-[0_2px_12px_rgba(0,0,0,0.04)] transition-all duration-300 ease-out hover:-translate-y-0.5 hover:border-primary-200/60 hover:shadow-[0_6px_24px_rgba(31,42,68,0.1)]"
            >
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="flex w-full cursor-pointer items-center justify-between px-6 py-5 text-left transition-colors hover:bg-navy-50/50 active:bg-navy-100/60"
              >
                <span className="text-[17px] font-semibold text-navy-900 transition-colors duration-300 group-hover:text-primary-600">
                  Q. {item.q}
                </span>
                <span
                  className={`ml-4 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-2xl font-light text-navy-500 transition-all duration-300 group-hover:scale-110 group-hover:bg-primary-50 group-hover:text-primary-500 ${
                    openIndex === i ? 'rotate-45' : ''
                  }`}
                >
                  +
                </span>
              </button>
              <div
                className={`overflow-hidden transition-all duration-200 ease-in-out ${
                  openIndex === i ? 'max-h-96' : 'max-h-0'
                }`}
              >
                <div className="border-t border-navy-100 px-6 py-5">
                  <p className="text-[17px] leading-[1.6] text-navy-700">A. {item.a}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
