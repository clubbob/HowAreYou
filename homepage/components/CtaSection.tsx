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
        <h2 className="mb-4 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:text-[1.75rem]">
          지금 어때 시작하기
        </h2>
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
          <>
            <p className="mb-8 whitespace-nowrap text-center text-[15px] text-navy-600 sm:text-[17px]">
              {BETA.cohortName} 선착순 {BETA.limit}명 · 출시 최우선 안내 · 1년 무료 이용
            </p>
            <button
              type="button"
              onClick={() => setShowModal(true)}
              className="flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-10 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600"
            >
              {BETA.cohortName} 참여하기
            </button>
          </>
        )}
      </div>
      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
