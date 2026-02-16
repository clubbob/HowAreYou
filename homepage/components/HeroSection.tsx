'use client';

import Image from 'next/image';
import { BetaModal } from './BetaModal';
import { useState } from 'react';

export function HeroSection() {
  const [showModal, setShowModal] = useState(false);

  return (
    <section className="relative overflow-hidden bg-[#F7F8FA] px-6 pt-20 pb-24 md:pt-28 md:pb-32">
      <div className="mx-auto grid max-w-5xl items-center gap-12 md:grid-cols-2 md:gap-16">
        {/* 좌측: 텍스트 */}
        <div>
          <div className="mb-6 flex items-center gap-4">
            <Image
              src="/logo.png"
              alt="지금 어때"
              width={72}
              height={72}
              priority
              unoptimized
              className="h-[4.5rem] w-[4.5rem] shrink-0"
            />
            <span className="text-2xl font-bold text-navy-900 md:text-3xl">여기 어때?</span>
          </div>
          <h1 className="mb-4 whitespace-nowrap text-[1.125rem] font-bold leading-[1.3] tracking-tight text-navy-900 sm:text-[1.5rem] md:text-[2rem] lg:text-[2.25rem]">
            하루 한 번, 안부를 확인합니다.
          </h1>
          <p className="mb-3 text-lg font-medium text-primary-400 md:text-xl">
            기록은 간단하게.
            <br />
            걱정은 줄어들게.
          </p>
          <p className="mb-10 text-[17px] leading-[1.6] text-navy-600">
            혼자 있는 가족의 하루를
            <br />
            가볍게 확인할 수 있는 안부 서비스입니다.
          </p>
          <div>
            <button
              type="button"
              onClick={() => setShowModal(true)}
              className="flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600"
            >
              베타 참여하기
            </button>
            <p className="mt-3 text-sm leading-relaxed text-navy-500">
              베타 신청은 1분 내 완료됩니다.
              <br />
              신청 시 이메일만 수집됩니다.
            </p>
          </div>
        </div>

        {/* 우측: 앱 목업 플레이스홀더 */}
        <div className="flex justify-center gap-4">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="flex h-[340px] w-[120px] flex-col overflow-hidden rounded-[2rem] border border-navy-200/60 bg-white shadow-[0_4px_20px_rgba(31,42,68,0.08)] md:w-[140px]"
              style={{ boxShadow: '0 4px 24px rgba(31,42,68,0.06)' }}
            >
              <div className="flex h-8 items-center justify-center border-b border-navy-100 bg-navy-50">
                <div className="h-2 w-2 rounded-full bg-navy-300" />
              </div>
              <div className="flex flex-1 flex-col items-center justify-center gap-3 p-4 text-center">
                <div className="h-12 w-12 rounded-xl bg-primary-100" />
                <div className="h-3 w-20 rounded bg-navy-200" />
                <div className="h-3 w-16 rounded bg-navy-100" />
              </div>
            </div>
          ))}
        </div>
      </div>

      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
