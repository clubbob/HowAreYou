'use client';

import { useState } from 'react';

const FAQ_ITEMS = [
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
              className="overflow-hidden rounded-[1rem] border border-navy-100 bg-white shadow-[0_2px_12px_rgba(0,0,0,0.04)]"
            >
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="flex w-full items-center justify-between px-6 py-5 text-left transition-colors hover:bg-navy-50/50 active:bg-navy-100/60"
              >
                <span className="text-[17px] font-semibold text-navy-900">Q. {item.q}</span>
                <span
                  className={`ml-4 shrink-0 text-2xl font-light text-navy-500 transition-transform duration-200 ${
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
