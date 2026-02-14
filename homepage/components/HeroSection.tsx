'use client';

import Image from 'next/image';
import { BetaModal } from './BetaModal';
import { useState } from 'react';

export function HeroSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section className="relative bg-gradient-to-b from-primary-50 to-white px-6 py-16 md:py-24">
      <div className="mx-auto max-w-3xl text-center">
        <div className="mb-8 flex justify-center">
          <Image
            src="/logo.png"
            alt="지금 어때"
            width={80}
            height={80}
            priority
            unoptimized
            className="h-20 w-20 object-contain md:h-24 md:w-24"
          />
        </div>
        <h1 className="mb-4 text-2xl font-bold leading-tight text-gray-900 md:text-4xl">
          하루 한 번, 안부를 남기세요.
        </h1>
        <p className="mb-10 text-base leading-relaxed text-gray-600 md:text-lg">
          갑작스러운 사고나 무응답 상황을 대비하는
          <br />
          가장 간단한 일상 기록 앱
        </p>
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
