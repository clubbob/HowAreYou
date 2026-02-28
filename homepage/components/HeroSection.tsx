'use client';

import Image from 'next/image';
import { useState } from 'react';
import { StartModal } from './StartModal';
import { BetaModal } from './BetaModal';

export function HeroSection() {
  const [showStartModal, setShowStartModal] = useState(false);
  const [showBetaModal, setShowBetaModal] = useState(false);

  return (
    <section className="relative overflow-hidden bg-[#F7F8FA] px-4 py-16 sm:px-6 sm:py-20 md:py-28">
      <div className="mx-auto flex max-w-2xl flex-col items-center text-center">
        <div className="mb-6 flex items-center justify-center gap-4 sm:mb-8">
          <Image
            src="/logo.png"
            alt="오늘 어때"
            width={80}
            height={80}
            priority
            unoptimized
            className="h-16 w-16 shrink-0 sm:h-20 sm:w-20"
          />
          <span className="text-2xl font-bold text-navy-900 sm:text-3xl">오늘 어때?</span>
        </div>
        <h1 className="mb-4 text-[1.5rem] font-bold leading-[1.3] tracking-tight text-navy-900 sm:mb-5 sm:text-[2rem] md:text-[2.5rem]">
          소중한 사람과 안부를 나누는 앱
        </h1>
        <p className="mb-8 text-base font-medium leading-[1.65] text-primary-400 sm:text-lg md:text-xl">
          매일 전화하지 않아도, 안부는 전해집니다.
          <br className="hidden sm:block" />
          <span className="sm:ml-1">작은 기록 하나로 서로의 안심을 확인하세요.</span>
        </p>
        <p className="mb-8 text-[14px] text-navy-500 sm:text-[15px]">Android에서 먼저 시작합니다.</p>

        <div className="flex w-full max-w-sm flex-col items-center gap-4 sm:max-w-md sm:gap-5">
          <button
            type="button"
            onClick={() => setShowStartModal(true)}
            className="flex h-14 w-full items-center justify-center rounded-[16px] bg-primary-400 px-10 text-[18px] font-bold text-white shadow-[0_4px_20px_rgba(74,144,226,0.35)] transition-all hover:bg-primary-500 hover:shadow-[0_6px_24px_rgba(74,144,226,0.4)] active:scale-[0.98] sm:h-16 sm:text-[20px]"
          >
            1개월 무료로 안심 시작하기
          </button>
          <p className="whitespace-nowrap overflow-x-auto rounded-xl bg-primary-50/80 px-5 py-3 text-center text-[11px] font-bold text-primary-600 sm:px-6 sm:py-4 sm:text-[13px] md:text-[15px]">
            베타 1기 선착순 100명 · 1년 무료 혜택 신청 가능
          </p>
        </div>
      </div>

      <StartModal
        open={showStartModal}
        onClose={() => setShowStartModal(false)}
        onWaitlistClick={() => {
          setShowStartModal(false);
          setTimeout(() => setShowBetaModal(true), 150);
        }}
      />
      <BetaModal open={showBetaModal} onClose={() => setShowBetaModal(false)} />
    </section>
  );
}
