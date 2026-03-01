'use client';

import { useState } from 'react';
import Link from 'next/link';

const FAQ_ITEMS = [
  {
    q: '무료로 이용할 수 있나요?',
    a: `기본 안부 기능은 무료로 이용할 수 있습니다.
하루 한 번 안부 기록, 자동 알림, 3일 이상 미기록 안내 기능이 포함됩니다.

보호대상자 2명까지는 무료로 등록할 수 있습니다.
3명 이상 추가하거나 추가 안심 기능을 이용하려면 선택형 프리미엄이 필요합니다.`,
  },
  {
    q: '위치 추적을 하나요?',
    a: `기본 안부 기능에는 위치 추적 기능이 포함되어 있지 않습니다.

프리미엄 기능을 선택한 경우에 한해, 보호대상자의 동의 하에 안심 이동 확인 기능을 사용할 수 있습니다.
상시 감시 목적이 아닌, 안심을 돕기 위한 기능입니다.`,
  },
  {
    q: '알림은 어떻게 작동하나요?',
    a: `보호대상자가 안부를 기록하면 보호자에게 알림이 전달됩니다.
기록이 없는 경우 하루 한 번만 안내 알림이 전달됩니다.
3일 이상 기록이 없으면 보호자에게 추가 안내가 전달됩니다.

불필요한 알림은 보내지 않습니다.`,
  },
  {
    q: '보호자는 어떤 정보를 볼 수 있나요?',
    a: `보호자는 보호대상자가 남긴 안부 기록과 기록 시간만 확인할 수 있습니다.

기본 기능에서는 위치를 자동으로 기록하거나 일상을 감시하지 않습니다.
프리미엄 기능을 이용하는 경우에만, 동의된 추가 정보가 제공됩니다.`,
  },
  {
    q: '보호자와 보호대상자는 각각 어떤 역할인가요?',
    a: `보호대상자는 하루 한 번 간단히 안부를 남깁니다.
보호자는 기록 여부를 확인하고, 필요한 경우 안내 알림을 받습니다.

복잡한 설정 없이 누구나 쉽게 사용할 수 있습니다.`,
  },
  {
    q: '탈퇴하면 데이터는 어떻게 되나요?',
    a: `회원 탈퇴 시 안부 기록 및 관련 정보는 삭제되며 복구할 수 없습니다.
자세한 내용은 개인정보처리방침을 참고해주세요.`,
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
