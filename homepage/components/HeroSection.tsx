'use client';

import Image from 'next/image';
import { useState } from 'react';
import { StartModal } from './StartModal';

export function HeroSection() {
  const [showStartModal, setShowStartModal] = useState(false);

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
        <p className="mb-2 text-[13px] text-navy-500 sm:text-[14px]">떨어져 사는 가족을 위한 안심 루틴 앱</p>
        <h1 className="mb-4 text-[1.5rem] font-bold leading-[1.3] tracking-tight text-navy-900 sm:mb-5 sm:text-[2rem] md:text-[2.5rem]">
          전화 대신, 하루 한 번 3초 안부.
        </h1>
        <p className="mb-4 text-base font-medium leading-[1.65] text-primary-400 sm:text-lg md:text-xl">
          버튼 한 번이면 오늘의 안부는 끝납니다.
          <br className="hidden sm:block" />
          <span className="sm:ml-1">연락이 없을 때 괜히 더 걱정되는 가족을 위해.</span>
        </p>
        <div className="mt-8 flex w-full max-w-sm flex-col items-center gap-4 sm:max-w-md sm:gap-5">
          <button
            type="button"
            onClick={() => setShowStartModal(true)}
            className="flex h-14 w-full items-center justify-center rounded-[16px] bg-primary-400 px-10 text-[18px] font-bold text-white shadow-[0_4px_20px_rgba(74,144,226,0.35)] transition-all hover:bg-primary-500 hover:shadow-[0_6px_24px_rgba(74,144,226,0.4)] active:scale-[0.98] sm:h-16 sm:text-[20px]"
          >
            무료로 안심 시작하기
          </button>
        </div>
      </div>

      <StartModal open={showStartModal} onClose={() => setShowStartModal(false)} />
    </section>
  );
}
