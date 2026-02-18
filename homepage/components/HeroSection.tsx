'use client';

import Image from 'next/image';
import { useState } from 'react';
import { BetaModal } from './BetaModal';

const HERO_IMAGES = [
  { src: '/image 1.png', alt: '역할 선택' },
  { src: '/image2.png', alt: '컨디션 기록' },
  { src: '/image3.png', alt: '최근 컨디션' },
  { src: '/image4.png', alt: '전달된 안부' },
];

export function HeroSection() {
  const [slideIndex, setSlideIndex] = useState(0);
  const [showModal, setShowModal] = useState(false);

  const goPrev = () => setSlideIndex((i) => (i <= 0 ? HERO_IMAGES.length - 1 : i - 1));
  const goNext = () => setSlideIndex((i) => (i >= HERO_IMAGES.length - 1 ? 0 : i + 1));

  return (
    <section className="relative overflow-hidden bg-[#F7F8FA] px-6 py-12 md:py-16">
      <div className="mx-auto grid max-w-5xl items-center gap-8 md:grid-cols-2 md:gap-12">
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
          <h1 className="mb-4 text-[1.125rem] font-bold leading-[1.3] tracking-tight text-navy-900 sm:text-[1.5rem] md:text-[2rem] lg:text-[2.25rem]">
            안부로 안심을 전하는 가족 앱
          </h1>
          <p className="mb-3 text-lg font-medium text-primary-400 md:text-xl">
            매일 전화하지 않아도, 안부는 전해집니다.
            <br />
            작은 기록 하나로 서로의 안심을 확인하세요.
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
              선착순 100명 · 출시 최우선 안내 · 1년 무료 이용
            </p>
          </div>
        </div>

        {/* 우측: 앱 화면 캐러셀 */}
        <div className="flex flex-col items-center gap-3">
          <div className="flex items-center justify-center gap-2">
            <button
            type="button"
            onClick={goPrev}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-navy-200 bg-white text-navy-600 shadow-sm transition-colors hover:bg-navy-50 hover:text-navy-900"
            aria-label="이전"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M15 18l-6-6 6-6" />
            </svg>
          </button>
          <div className="flex h-[280px] w-[160px] flex-col overflow-hidden rounded-[1.5rem] border border-navy-200/60 bg-white shadow-[0_4px_20px_rgba(31,42,68,0.08)] md:h-[360px] md:w-[200px]" style={{ boxShadow: '0 4px 24px rgba(31,42,68,0.06)' }}>
            <div className="flex h-6 shrink-0 items-center justify-center border-b border-navy-100 bg-navy-50">
              <div className="h-1.5 w-1.5 rounded-full bg-navy-300" />
            </div>
            <div className="relative flex flex-1 min-h-0 overflow-hidden bg-navy-50">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                key={HERO_IMAGES[slideIndex].src}
                src={HERO_IMAGES[slideIndex].src}
                alt={HERO_IMAGES[slideIndex].alt}
                className="h-full w-full object-contain"
                onError={(e) => {
                  const t = e.target as HTMLImageElement;
                  if (!t.dataset.fallback) {
                    t.dataset.fallback = '1';
                    t.src = '/logo.png';
                  }
                }}
              />
            </div>
          </div>
          <button
            type="button"
            onClick={goNext}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-navy-200 bg-white text-navy-600 shadow-sm transition-colors hover:bg-navy-50 hover:text-navy-900"
            aria-label="다음"
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M9 18l6-6-6-6" />
            </svg>
          </button>
          </div>
          <div className="flex gap-2" aria-hidden="true">
            {HERO_IMAGES.map((_, i) => (
              <button
                key={i}
                type="button"
                onClick={() => setSlideIndex(i)}
                className={`h-2 rounded-full transition-colors ${
                  i === slideIndex ? 'w-4 bg-primary-400' : 'w-2 bg-navy-200 hover:bg-navy-300'
                }`}
                aria-label={`${i + 1}번째로 이동`}
              />
            ))}
          </div>
        </div>
      </div>

      <BetaModal open={showModal} onClose={() => setShowModal(false)} />
    </section>
  );
}
