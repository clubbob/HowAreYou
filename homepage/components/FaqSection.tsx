'use client';

import { useState } from 'react';
import Link from 'next/link';
import { PRICING, formatPrice } from '@/lib/config/pricing';

const FAQ_ITEMS = [
  { q: '누가 결제하나요?', a: '보호자만 결제합니다. 보호대상자는 무료로 이용합니다.' },
  {
    q: '무료 체험은 어떻게 되나요?',
    a: `계정 생성일 기준 1개월 무료입니다. 이후 연 ${formatPrice(PRICING.yearly)}이 자동 결제됩니다. 만료 후 7일 유예가 있으며, 결제 전에는 알림·기록 열람이 제한됩니다.`,
  },
  {
    q: '언제든 해지할 수 있나요?',
    a: "앱 설정에서 스토어(구글 플레이·앱스토어)로 이동해 연 결제를 취소할 수 있습니다. 취소하면 다음 결제일부터 과금되지 않습니다. 위약금·숨은 비용 없습니다.",
  },
  {
    q: '위치 추적 기능이 있나요?',
    a: '위치 추적 기능은 제공하지 않습니다.',
  },
  {
    q: '알림은 어떻게 발송되나요?',
    a: '보호대상자에게는 당일 기록이 없을 때만 매일 저녁 7시에 기록 안내 알림이 발송됩니다. 보호자에게는 보호대상자가 기록했을 때 실시간으로 알림이 전달되고, 3일 연속 기록이 없을 때 추가로 1회 안내됩니다.',
  },
  {
    q: '보호자는 어떤 기록을 볼 수 있나요?',
    a: '보호대상자가 오늘 기록을 했는지 여부만 확인할 수 있습니다. 컨디션 선택 내용이나 메모 내용은 확인할 수 없으며, 위치 추적이나 상세 건강 정보도 제공하지 않습니다.',
  },
  {
    q: '탈퇴하면 데이터와 과금은 어떻게 되나요?',
    a: '탈퇴하면 데이터는 삭제됩니다. 연 결제(12,000원)는 스토어에서 자동 갱신되므로, 탈퇴만 하면 과금이 계속됩니다. 과금 멈추려면 앱 설정에서 스토어로 이동해 직접 취소하세요. 이미 낸 돈은 환불되지 않습니다.',
  },
];

export function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="bg-navy-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24">
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
                className="flex w-full cursor-pointer items-center justify-between gap-3 px-4 py-4 text-left transition-colors hover:bg-navy-50/50 active:bg-navy-100/60 sm:px-6 sm:py-5"
              >
                <span className="min-w-0 flex-1 text-[15px] font-semibold leading-[1.4] text-navy-900 transition-colors duration-300 group-hover:text-primary-600 sm:text-[17px]">
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
                <div className="border-t border-navy-100 px-4 py-4 sm:px-6 sm:py-5">
                  <p className="text-[15px] leading-[1.6] text-navy-700 sm:text-[17px]">A. {item.a}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        <p className="mt-10 text-center text-[17px] text-navy-600">
          답을 찾지 못하셨나요?{' '}
          <Link href="/inquiry" className="font-semibold text-primary-400 hover:text-primary-500 hover:underline">
            1:1 문의하기
          </Link>
        </p>
      </div>
    </section>
  );
}
