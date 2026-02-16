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
    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReduceMotion(prefersReduced.matches);

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setVisible(true);
          }
        });
      },
      {
        root: null,
        rootMargin,
        threshold,
      }
    );

    const el = ref.current;
    if (el) observer.observe(el);
    return () => {
      if (el) observer.unobserve(el);
    };
  }, [rootMargin, threshold]);

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
