'use client';

import { useState } from 'react';
import { StartModal } from './StartModal';

export function CtaSection() {
  const [showStartModal, setShowStartModal] = useState(false);

  return (
    <section id="cta" className="bg-primary-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto flex max-w-3xl flex-col items-center">
        <h2 className="mb-2 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:text-[1.75rem]">
          오늘부터 안심 시작하기
        </h2>
        <p className="mb-4 text-center text-[14px] text-navy-500 sm:text-[15px]">누구나 무료로 시작할 수 있습니다.</p>
        <div className="flex w-full max-w-sm flex-col items-center gap-4 sm:max-w-md sm:gap-5">
          <button
            type="button"
            onClick={() => setShowStartModal(true)}
            className="flex h-14 w-full items-center justify-center rounded-[16px] bg-primary-400 px-10 text-[18px] font-bold text-white shadow-[0_4px_20px_rgba(74,144,226,0.35)] transition-all hover:bg-primary-500 hover:shadow-[0_6px_24px_rgba(74,144,226,0.4)] active:scale-[0.98] sm:h-16 sm:text-[20px]"
          >
            무료로 시작하기
          </button>
          <p className="rounded-xl bg-primary-50/80 px-5 py-3 text-center text-[11px] font-bold leading-[1.5] text-primary-600 sm:px-6 sm:py-4 sm:text-[13px] md:text-[15px]">
            누구나 무료로 시작할 수 있습니다.
          </p>
        </div>
      </div>
      <StartModal open={showStartModal} onClose={() => setShowStartModal(false)} />
    </section>
  );
}
