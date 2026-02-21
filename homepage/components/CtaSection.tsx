'use client';

import { useState } from 'react';
import { BetaModal } from './BetaModal';

export function CtaSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section id="cta" className="bg-primary-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto flex max-w-3xl flex-col items-center">
        <h2 className="mb-4 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:text-[1.75rem]">
          지금 어때 시작하기
        </h2>
        <p className="mb-8 text-center text-[17px] text-navy-600">
          선착순 100명 · 출시 최우선 안내 · 1년 무료 이용
        </p>
        <button
          type="button"
          onClick={() => setShowModal(true)}
          className="flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-10 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600"
        >
          베타 참여하기
        </button>
      </div>
      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
