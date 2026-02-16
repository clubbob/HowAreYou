'use client';

import { useEffect, useRef, useState } from 'react';

type FadeInSectionProps = {
  children: React.ReactNode;
  className?: string;
  /** 모바일 viewport에서도 안정적으로 트리거되도록 rootMargin 조정 */
  rootMargin?: string;
  threshold?: number;
};

export function FadeInSection({
  children,
  className = '',
  rootMargin = '0px 0px -30px 0px',
  threshold = 0.1,
}: FadeInSectionProps) {
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
      {
        root: null,
        rootMargin: '0px 0px -30px 0px',
        threshold: 0,
      }
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

  const shouldAnimate = visible || reduceMotion;
  const opacity = reduceMotion ? 1 : shouldAnimate ? 1 : 0;
  const transform = reduceMotion ? 'none' : shouldAnimate ? 'translateY(0)' : 'translateY(16px)';

  return (
    <div
      ref={ref}
      className={className}
      style={{
        opacity,
        transform,
        transition: reduceMotion ? 'none' : 'opacity 0.5s ease-out, transform 0.5s ease-out',
      }}
    >
      {children}
    </div>
  );
}
