'use client';

import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { BETA } from '@/lib/config/beta';

type Props = {
  open: boolean;
  onClose: () => void;
  onWaitlistClick?: () => void;
};

export function StartModal({ open, onClose, onWaitlistClick }: Props) {
  const closeBtnRef = useRef<HTMLButtonElement>(null);
  const overlayRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
      window.scrollTo(0, 0);
      closeBtnRef.current?.focus();
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [open]);

  useEffect(() => {
    if (open) overlayRef.current?.scrollTo({ top: 0 });
  }, [open]);

  const handleWaitlist = () => {
    onClose();
    setTimeout(() => onWaitlistClick?.(), 150);
  };

  if (!open) return null;

  const modalContent = (
    <div
      ref={overlayRef}
      className="fixed inset-0 z-50 flex min-h-[100dvh] items-center justify-center overflow-y-auto bg-navy-900/40 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
        <div
          className="w-full max-w-md rounded-[1rem] border border-navy-100 bg-white p-5 shadow-[0_8px_32px_rgba(0,0,0,0.12)] sm:p-6"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="mb-5 flex items-center justify-between">
            <h2 className="text-xl font-bold text-navy-900">안심 시작하기</h2>
            <button
              ref={closeBtnRef}
              type="button"
              onClick={onClose}
              className="rounded-xl p-2 text-navy-600 transition-colors hover:bg-navy-50 active:bg-navy-100"
              aria-label="닫기"
            >
              <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <p className="mb-6 text-[17px] leading-[1.6] text-navy-700">
            베타 1기 혜택 신청 시 1년 무료 이용이 적용됩니다.
          </p>

          <div className="space-y-3">
            <div>
              <p className="mb-2 text-[15px] font-medium text-navy-600">앱 설치하기</p>
              <a
                href={BETA.playStoreUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600"
              >
                Android 앱 설치하기
              </a>
            </div>
            <div>
              <button
                type="button"
                onClick={handleWaitlist}
                className="flex h-[52px] w-full items-center justify-center rounded-[14px] border border-navy-200 py-4 text-[17px] font-medium text-navy-700 transition-colors hover:bg-navy-50 active:bg-navy-100"
              >
                {BETA.cohortName} {BETA.cohortActionLabel}
              </button>
              <p className="mt-2 text-center text-[14px] text-navy-500">선착순 {BETA.limit}명</p>
            </div>
          </div>
        </div>
    </div>
  );

  return typeof document !== 'undefined' ? createPortal(modalContent, document.body) : null;
}
