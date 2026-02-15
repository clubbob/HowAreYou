'use client';

import Image from 'next/image';
import { BetaModal } from './BetaModal';
import { useState } from 'react';

export function HeroSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-primary-50/80 via-cream-50 to-cream-50 px-6 pt-20 pb-28 md:pt-28 md:pb-36">
      {/* 배경 장식 */}
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-primary-100/40 blur-3xl" />
        <div className="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-primary-50/60 blur-3xl" />
      </div>

      <div className="relative mx-auto max-w-2xl text-center">
        <div className="mb-10 flex justify-center">
          <div className="relative">
            <Image
              src="/logo.png"
              alt="지금 어때"
              width={96}
              height={96}
              priority
              unoptimized
              className="h-20 w-20 md:h-24 md:w-24"
            />
            <div className="absolute -inset-2 -z-10 rounded-full bg-primary-100/30 blur-xl" />
          </div>
        </div>

        <h1 className="mb-5 text-3xl font-bold leading-tight tracking-tight text-primary-900 md:text-4xl lg:text-5xl">
          하루 한 번, 안부를 남기세요.
        </h1>

        <p className="mb-12 max-w-lg mx-auto text-base leading-relaxed text-primary-800/80 md:text-lg">
          갑작스러운 사고나 무응답 상황을 대비하는
          <br className="hidden sm:block" />
          가장 간단한 일상 기록 앱
        </p>

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
