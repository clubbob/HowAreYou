'use client';

import { useState } from 'react';
import Link from 'next/link';

const FAQ_ITEMS = [
  {
    q: '무료인가요?',
    a: '지금은 모든 기능을 무료로 제공합니다.',
  },
  {
    q: '위치 추적 기능이 있나요?',
    a: '위치 추적 기능은 제공하지 않습니다.',
  },
  {
    q: '알림은 어떻게 작동하나요?',
    a: '보호대상자에게는 당일 기록이 없을 때만 매일 저녁 7시에 기록 안내 알림이 발송됩니다. 보호자에게는 보호대상자가 기록했을 때 실시간으로 알림이 전달되고, 3일 연속 기록이 없을 때 추가로 1회 안내됩니다.',
  },
  {
    q: '보호자는 어떤 기록을 볼 수 있나요?',
    a: '보호대상자가 오늘 기록을 했는지 여부만 확인할 수 있습니다. 보호대상자가 기록한 컨디션 내용이나 메모 내용은 확인할 수 없으며, 위치 추적이나 상세 건강 정보도 제공하지 않습니다.',
  },
  {
    q: '탈퇴하면 데이터는 어떻게 되나요?',
    a: '탈퇴하면 데이터는 삭제됩니다.',
  },
];

export function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <section className="bg-primary-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24">
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
