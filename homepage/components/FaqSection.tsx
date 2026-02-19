'use client';

import { useState } from 'react';
import Link from 'next/link';
import { PRICING, formatPrice } from '@/lib/config/pricing';

const FAQ_ITEMS = [
  { q: '누가 결제하나요?', a: '보호자만 결제합니다. 보호대상자는 무료로 이용합니다.' },
  {
    q: '무료 체험은 어떻게 되나요?',
    a: `계정 생성일 기준 1개월 동안 모든 기능을 무료로 이용할 수 있습니다. 이후 연 ${formatPrice(PRICING.yearly)}이 자동 결제됩니다. 만료 후 7일 유예 기간이 있으며, 구독 갱신 전에는 알림 및 기록 열람이 제한됩니다.`,
  },
  {
    q: '언제든 해지할 수 있나요?',
    a: "앱 설정의 '구독 관리하기' 버튼을 누르면 구글 플레이 또는 애플 앱스토어의 구독 관리 페이지로 이동합니다. 언제든지 해지하실 수 있으며, 해지 후에는 다음 결제일부터 과금되지 않습니다. 위약금이나 숨은 비용은 없습니다.",
  },
  {
    q: '위치 추적 기능이 있나요?',
    a: '위치 추적 기능은 제공하지 않습니다.',
  },
  {
    q: '알림은 어떻게 발송되나요?',
    a: '보호대상자에게는 당일 기록이 없을 때만 매일 저녁 7시에 기록 안내 알림이 발송됩니다. 보호자에게는 보호대상자가 기록했을 때 실시간으로 알림이 전달되고, 당일 기록이 없을 때는 저녁 8시에 한 번, 3일 연속 기록이 없을 때는 추가로 1회 안내됩니다.',
  },
  {
    q: '보호자는 어떤 기록을 볼 수 있나요?',
    a: '보호대상자가 오늘 기록을 했는지 여부만 확인할 수 있습니다. 컨디션 선택 내용이나 메모 내용은 확인할 수 없으며, 위치 추적이나 상세 건강 정보도 제공하지 않습니다.',
  },
  {
    q: '탈퇴하면 데이터와 과금은 어떻게 되나요?',
    a: '회원 탈퇴 시 관련 데이터는 지체 없이 삭제됩니다. 구독도 함께 해지되며, 이미 결제한 기간은 환불되지 않습니다. 다음 결제일부터 과금되지 않습니다.',
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
