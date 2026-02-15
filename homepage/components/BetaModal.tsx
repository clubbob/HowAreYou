'use client';

import { useState } from 'react';
import { addToWaitlist } from '@/lib/waitlist';

type Props = {
  open: boolean;
  onClose: () => void;
};

export function BetaModal({ open, onClose }: Props) {
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setStatus('loading');
    setErrorMsg('');
    try {
      await addToWaitlist(email.trim());
      setStatus('success');
      setEmail('');
    } catch (err) {
      setStatus('error');
      setErrorMsg(err instanceof Error ? err.message : '등록에 실패했습니다. 다시 시도해 주세요.');
    }
  };

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-navy-900/40 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-[1rem] border border-navy-100 bg-white p-6 shadow-[0_8px_32px_rgba(0,0,0,0.12)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-xl font-bold text-navy-900">베타 참여하기</h2>
          <button
            onClick={onClose}
            className="rounded-xl p-2 text-navy-600 transition-colors hover:bg-navy-50"
            aria-label="닫기"
          >
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {status === 'success' ? (
          <div className="py-8 text-center">
            <div className="mb-5 inline-flex h-16 w-16 items-center justify-center rounded-[1rem] bg-primary-50">
              <svg className="h-8 w-8 text-primary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <p className="text-lg font-semibold text-navy-900">등록되었습니다.</p>
            <p className="mt-1 text-[17px] text-navy-600">빠른 시일 내에 연락드리겠습니다.</p>
            <button
              onClick={onClose}
              className="mt-6 flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-medium text-white transition-colors hover:bg-primary-500"
            >
              확인
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <p className="mb-4 text-[17px] leading-[1.6] text-navy-700">
              베타 참여를 위한 이메일을 입력해 주세요. 출시 시 안내해 드립니다.
            </p>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@email.com"
              required
              disabled={status === 'loading'}
              className="w-full rounded-[14px] border border-navy-200 px-4 py-4 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20 disabled:bg-navy-50 disabled:opacity-70"
            />
            {errorMsg && <p className="mt-2 text-sm font-medium text-red-600">{errorMsg}</p>}
            <div className="mt-6 flex gap-3">
              <button
                type="button"
                onClick={onClose}
                className="flex flex-1 items-center justify-center rounded-[14px] border border-navy-200 py-4 text-[17px] font-medium text-navy-700 transition-colors hover:bg-navy-50"
              >
                취소
              </button>
              <button
                type="submit"
                disabled={status === 'loading'}
                className="flex flex-1 items-center justify-center rounded-[14px] bg-primary-400 py-4 text-[17px] font-medium text-white transition-colors hover:bg-primary-500 disabled:opacity-60"
              >
                {status === 'loading' ? '등록 중...' : '참여 신청'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
