'use client';

import { useState } from 'react';
import { BetaModal } from './BetaModal';

export function CtaSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section className="px-6 py-16 md:py-20">
      <div className="mx-auto max-w-3xl text-center">
        <h2 className="mb-6 text-xl font-bold text-gray-900 md:text-2xl">
          지금 어때 시작하기
        </h2>
        <button
          onClick={() => setShowModal(true)}
          className="inline-flex h-14 items-center justify-center rounded-2xl bg-primary-500 px-10 text-lg font-semibold text-white shadow-lg transition hover:bg-primary-600 active:scale-[0.98] md:h-16 md:px-12 md:text-xl"
        >
          베타 테스트 참여하기
        </button>
      </div>
      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
