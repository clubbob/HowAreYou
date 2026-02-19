'use client';

import { useEffect, useRef, useState } from 'react';

const STEPS = [
  { title: '간단하게 남깁니다', subtitle: '버튼 한 번으로 오늘의 안부를 기록합니다. 길게 쓰지 않아도 괜찮습니다.' },
  {
    title: '필요한 순간에만 안내합니다',
    subtitle:
      '기록을 하면 보호자에게 알림이 전달됩니다. 기록이 없을 때는 당일 저녁 7시(보호대상자 기록 요청), 8시(보호자 안내)에만 발송됩니다. 불필요한 알림은 보내지 않습니다.',
  },
  {
    title: '3일 이상 신호가 없을 때',
    subtitle:
      '3일 연속 기록이 없으면 보호자에게 추가 안내가 전달됩니다. 조용하지만 놓치지 않는 구조입니다.',
  },
];

export function ServiceSection() {
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
    <section
      ref={ref}
      className="bg-primary-50 px-6 py-20 md:py-24"
      style={{ paddingTop: '5rem', paddingBottom: '5rem' }}
    >
      <div className="mx-auto max-w-3xl">
        <h2
          className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900"
          style={{
            opacity: animate ? 1 : 0,
            transform: reduceMotion ? 'none' : animate ? 'translateY(0)' : 'translateY(12px)',
            transition: reduceMotion ? 'none' : 'opacity 0.5s ease-out, transform 0.5s ease-out',
          }}
        >
          이렇게 안부를 전합니다
        </h2>

        <div className="space-y-5">
          {STEPS.map((s, i) => (
            <div
              key={`step-${i}`}
              style={{
                opacity: animate ? 1 : 0,
                transform: reduceMotion ? 'none' : animate ? 'translateY(0)' : 'translateY(20px)',
                transition: reduceMotion
                  ? 'none'
                  : `opacity 0.5s ease-out ${0.15 * (i + 1)}s, transform 0.5s ease-out ${0.15 * (i + 1)}s`,
              }}
            >
              <div
                data-mobile-service-card
                className="group flex cursor-default items-center gap-6 rounded-[1rem] border border-primary-100 bg-white p-6 shadow-[0_2px_12px_rgba(0,0,0,0.04)] transition-all duration-300 ease-out hover:-translate-y-1 hover:border-primary-300/60 hover:shadow-[0_8px_28px_rgba(74,144,226,0.14)] active:translate-y-0 active:scale-[0.99]"
              >
                <span
                  className="inline-flex"
                  style={{
                    opacity: animate ? 1 : 0,
                    transform: reduceMotion ? 'none' : animate ? 'scale(1)' : 'scale(0.8)',
                    transition: reduceMotion
                      ? 'none'
                      : `opacity 0.4s ease-out ${0.2 + 0.15 * i}s, transform 0.4s ease-out ${0.2 + 0.15 * i}s`,
                  }}
                >
                  <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-[14px] bg-primary-400 text-xl font-bold text-white transition-all duration-300 group-hover:scale-110 group-hover:bg-primary-500">
                    {i + 1}
                  </span>
                </span>
                <span className="flex flex-col gap-1 transition-colors duration-300 group-hover:text-primary-600">
                  <span className="text-[18px] font-medium text-navy-800">{s.title}</span>
                  <span className="text-[16px] text-navy-600">{s.subtitle}</span>
                </span>
              </div>
            </div>
          ))}
        </div>

        <p
          className="mt-10 text-center text-sm leading-relaxed text-navy-600"
          style={{
            opacity: animate ? 1 : 0,
            transition: reduceMotion ? 'none' : `opacity 0.5s ease-out 0.7s`,
          }}
        >
          ※ 본 서비스는 의료·응급 구조 서비스가 아닙니다.
          <br />
          네트워크 및 기기 환경에 따라 알림이 지연될 수 있습니다.
        </p>
      </div>
    </section>
  );
}
