'use client';

import { useState, useEffect } from 'react';
import { BetaModal } from './BetaModal';
import { BETA } from '@/lib/config/beta';

export function CtaSection() {
  const [showModal, setShowModal] = useState(false);
  const [isFull, setIsFull] = useState<boolean | null>(null);

  useEffect(() => {
    fetch('/api/waitlist')
      .then((res) => res.ok ? res.json() : null)
      .then((data) => data?.full === true && setIsFull(true))
      .catch(() => {});
  }, []);

  return (
    <section id="cta" className="bg-primary-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto flex max-w-3xl flex-col items-center">
        <h2 className="mb-2 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:text-[1.75rem]">
          오늘 어때 시작하기
        </h2>
        <p className="mb-4 text-center text-[14px] text-navy-500 sm:text-[15px]">Android에서 먼저 시작합니다.</p>
        {isFull ? (
          <div className="flex flex-col items-center gap-4">
            <p className="text-center text-[17px] font-medium text-navy-600">
              {BETA.cohortName} 선착순 {BETA.limit}명이 마감되었습니다.
            </p>
            <p className="text-center text-[15px] text-navy-500">
              관심 가져 주셔서 감사합니다. 다음 기수를 기다려 주세요.
            </p>
            <div className="flex h-[52px] items-center justify-center rounded-[14px] bg-navy-200 px-10 text-[17px] font-medium text-navy-700">
              마감
            </div>
          </div>
        ) : (
          <div className="flex w-full max-w-sm flex-col items-center gap-4 sm:max-w-md sm:gap-5">
            <button
              type="button"
              onClick={() => setShowModal(true)}
              className="flex h-14 w-full items-center justify-center rounded-[16px] bg-primary-400 px-10 text-[18px] font-bold text-white shadow-[0_4px_20px_rgba(74,144,226,0.35)] transition-all hover:bg-primary-500 hover:shadow-[0_6px_24px_rgba(74,144,226,0.4)] active:scale-[0.98] sm:h-16 sm:text-[20px]"
            >
              {BETA.cohortName} {BETA.cohortActionLabel}
            </button>
            <p className="rounded-xl bg-primary-50/80 px-5 py-3 text-center text-[13px] font-bold text-primary-600 sm:px-6 sm:py-4 sm:text-[15px] md:text-[17px]">
              {BETA.cohortName} 선착순 {BETA.limit}명 · 출시 최우선 안내 · 1년 무료 이용
            </p>
          </div>
        )}
      </div>
      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
