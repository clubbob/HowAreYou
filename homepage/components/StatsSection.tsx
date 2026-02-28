'use client';

import { useEffect, useRef, useState } from 'react';

const ITEMS = [
  { value: '350만+', label: '혼자 사는 노인', accent: 'border-l-primary-500' },
  { value: '700만+', label: '1인 가구', accent: 'border-l-primary-600' },
  { value: '50만+', label: '자취·기숙 학생, 유학생', accent: 'border-l-primary-500' },
];

export function StatsSection() {
  const ref = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReduceMotion(prefersReduced.matches);

    const show = () => setVisible(true);

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) show();
        });
      },
      { root: null, rootMargin: '0px 0px -30px 0px', threshold: 0 }
    );

    observer.observe(el);

    const checkViewport = () => {
      const rect = el.getBoundingClientRect();
      const vh = typeof window !== 'undefined' ? window.innerHeight : 0;
      if (rect.top < vh && rect.bottom > 0) show();
    };

    checkViewport();
    const t1 = setTimeout(checkViewport, 300);
    const t2 = setTimeout(checkViewport, 800);

    let scrollTimeout: ReturnType<typeof setTimeout>;
    const onScroll = () => {
      clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(checkViewport, 50);
    };
    window.addEventListener('scroll', onScroll, { passive: true });

    return () => {
      observer.unobserve(el);
      clearTimeout(t1);
      clearTimeout(t2);
      clearTimeout(scrollTimeout);
      window.removeEventListener('scroll', onScroll);
    };
  }, []);

  const animate = visible || reduceMotion;

  return (
    <section ref={ref} className="bg-white px-4 py-12 sm:px-6 sm:py-14 md:py-20">
      <div className="mx-auto max-w-4xl">
        <h2
          className="mb-10 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:mb-12 sm:text-[1.75rem]"
          style={{
            opacity: animate ? 1 : 0,
            transform: reduceMotion ? 'none' : animate ? 'translateY(0)' : 'translateY(12px)',
            transition: reduceMotion ? 'none' : 'opacity 0.5s ease-out, transform 0.5s ease-out',
          }}
        >
          우리는 점점 혼자 살고 있습니다.
          <br />
          그래서, 걱정은 더 잦아졌습니다.
        </h2>

        <div className="grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-3 md:gap-6">
          {ITEMS.map((item, i) => (
            <div
              key={i}
              style={{
                opacity: animate ? 1 : 0,
                transform: reduceMotion ? 'none' : animate ? 'translateY(0)' : 'translateY(20px)',
                transition: reduceMotion
                  ? 'none'
                  : `opacity 0.5s ease-out ${0.12 * (i + 1)}s, transform 0.5s ease-out ${0.12 * (i + 1)}s`,
              }}
            >
              <div
                data-mobile-hover-card
                className={`group relative overflow-hidden rounded-2xl border border-navy-100/80 border-l-[6px] ${item.accent} bg-gradient-to-b from-white to-navy-50/30 px-6 py-5 text-center shadow-[0_2px_16px_rgba(31,42,68,0.06)] transition-all duration-300 hover:-translate-y-0.5 hover:border-primary-200/60 hover:border-l-primary-600 hover:shadow-[0_8px_28px_rgba(74,144,226,0.12)] active:translate-y-0 active:scale-[0.99]`}
              >
                <div
                  data-mobile-hover-blur
                  className="absolute right-0 top-0 h-20 w-20 translate-x-4 -translate-y-4 rounded-full bg-primary-50/50 blur-2xl transition-opacity group-hover:opacity-80"
                />
                <div className="relative">
                  <p className="text-[1.25rem] font-semibold text-navy-800 transition-colors duration-300 group-hover:text-primary-600 sm:text-[1.375rem]">
                    {item.value}
                  </p>
                  <p className="mt-1.5 text-[15px] font-medium text-navy-600">{item.label}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        <p
          className="mt-10 text-center text-[1.0625rem] leading-[1.7] text-navy-700 sm:mt-12 sm:text-[1.125rem] md:text-[1.1875rem]"
          style={{
            opacity: animate ? 1 : 0,
            transition: reduceMotion ? 'none' : `opacity 0.5s ease-out 0.5s`,
          }}
        >
          그래서, 안부를 전하는 방식은 바뀌어야 합니다.
        </p>

        <p className="mt-4 text-center text-[12px] text-navy-400">
          최근 통계청 발표 기준
        </p>
      </div>
    </section>
  );
}
