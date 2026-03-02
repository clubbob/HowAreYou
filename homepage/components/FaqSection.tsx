'use client';

import { useState } from 'react';
import Link from 'next/link';

const FAQ_ITEMS = [
  {
    q: '무료로 이용할 수 있나요?',
    a: `네. 기본 안부 기능은 무료로 이용할 수 있습니다.
하루 한 번 안부 확인과 자동 알림 기능은 무료입니다.
더 많은 가족을 관리하거나 스마트 이상 감지를 이용하려면 프리미엄을 선택할 수 있습니다.`,
  },
  {
    q: '위치 추적을 하나요?',
    a: `위치 추적은 하지 않습니다.
오늘 어때는 위치 정보가 아닌 걸음 수 기반 활동 여부만 판단합니다.
실시간 위치 공유 없이도 안심할 수 있도록 설계되었습니다.`,
  },
  {
    q: '스마트 이상 감지는 어떻게 작동하나요?',
    a: `걸음 수 변화를 기반으로 활동 여부를 판단합니다.
움직임이 일정 조건 이상 감지되지 않으면 보호자에게 자동으로 알림을 보냅니다.
보호자가 계속 확인하지 않아도 시스템이 대신 감지합니다.`,
  },
  {
    q: '보호자는 어떤 정보를 볼 수 있나요?',
    a: `안부 상태와 활동 여부만 확인할 수 있습니다.
개인 메시지, 위치 정보, 세부 활동 기록은 제공되지 않습니다.
최소한의 정보로 안심을 제공합니다.`,
  },
  {
    q: '보호자와 보호대상자의 역할은 무엇인가요?',
    a: `보호대상자는 하루 한 번 안부를 전합니다.
보호자는 안부 상태와 이상 알림을 확인합니다.
보호자만 결제하며, 보호대상자는 무료입니다.`,
  },
  {
    q: '탈퇴하면 데이터는 어떻게 되나요?',
    a: `탈퇴 시 관련 데이터는 삭제됩니다.
계정 및 연결 정보는 즉시 비활성화되며, 일정 기간 후 완전히 삭제됩니다.`,
  },
  {
    q: '왜 스마트 이상 감지가 필요한가요?',
    a: `매일 연락하지 못하는 상황에서도 안심할 수 있기 때문입니다.
움직임이 멈춘 상황을 시스템이 대신 감지해 알려줍니다.`,
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
                  openIndex === i ? 'max-h-[600px]' : 'max-h-0'
                }`}
              >
                <div className="border-t border-navy-100 px-4 py-4 sm:px-6 sm:py-5">
                  <p className="whitespace-pre-line text-[15px] leading-[1.6] text-navy-700 sm:text-[17px]">A. {item.a}</p>
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
