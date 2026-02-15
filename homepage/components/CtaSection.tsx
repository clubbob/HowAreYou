'use client';

import { useState } from 'react';
import { BetaModal } from './BetaModal';

export function CtaSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section className="relative px-6 py-20 md:py-28">
      <div className="mx-auto max-w-2xl text-center">
        <h2 className="mb-10 text-2xl font-bold tracking-tight text-primary-900 md:text-3xl">
          지금 어때 시작하기
        </h2>
        <button
          onClick={() => setShowModal(true)}
          className="inline-flex h-14 items-center justify-center rounded-2xl bg-primary-600 px-10 text-base font-semibold text-white shadow-card transition-all duration-200 hover:bg-primary-700 hover:shadow-elevated hover:-translate-y-0.5 active:scale-[0.98] md:h-16 md:px-12 md:text-lg"
        >
          베타 테스트 참여하기
        </button>
      </div>
      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
