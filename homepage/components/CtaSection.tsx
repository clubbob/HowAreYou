'use client';

import { useState } from 'react';
import { BetaModal } from './BetaModal';

export function CtaSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section className="px-6 py-20 md:py-24" style={{ paddingTop: '5rem', paddingBottom: '5rem' }}>
      <div className="mx-auto max-w-3xl text-center">
        <h2 className="mb-10 text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          지금 어때 시작하기
        </h2>
        <button
          onClick={() => setShowModal(true)}
          className="flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-10 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500"
        >
          베타 참여하기
        </button>
      </div>
      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
