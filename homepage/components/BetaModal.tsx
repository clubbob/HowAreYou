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
      className="fixed inset-0 z-50 flex items-center justify-center bg-primary-950/40 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md rounded-2xl border border-primary-100/80 bg-white p-6 shadow-elevated"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-xl font-bold text-primary-900">베타 테스트 참여하기</h2>
          <button
            onClick={onClose}
            className="rounded-xl p-2 text-primary-600 transition-colors hover:bg-primary-50"
            aria-label="닫기"
          >
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {status === 'success' ? (
          <div className="py-8 text-center">
            <div className="mb-5 inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-primary-100">
              <svg className="h-8 w-8 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <p className="text-lg font-semibold text-primary-900">등록되었습니다.</p>
            <p className="mt-1 text-sm text-primary-600">빠른 시일 내에 연락드리겠습니다.</p>
            <button
              onClick={onClose}
              className="mt-6 rounded-xl bg-primary-600 px-8 py-3 font-medium text-white transition-colors hover:bg-primary-700"
            >
              확인
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit}>
            <p className="mb-4 text-sm leading-relaxed text-primary-700">
              베타 테스트 참여를 위한 이메일을 입력해 주세요. 출시 시 안내해 드립니다.
            </p>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@email.com"
              required
              disabled={status === 'loading'}
              className="w-full rounded-xl border border-primary-200 px-4 py-3.5 text-base text-primary-900 placeholder:text-primary-400 focus:border-primary-500 focus:outline-none focus:ring-2 focus:ring-primary-500/20 disabled:bg-primary-50 disabled:opacity-70"
            />
            {errorMsg && <p className="mt-2 text-sm font-medium text-red-600">{errorMsg}</p>}
            <div className="mt-6 flex gap-3">
              <button
                type="button"
                onClick={onClose}
                className="flex-1 rounded-xl border border-primary-200 py-3 font-medium text-primary-700 transition-colors hover:bg-primary-50"
              >
                취소
              </button>
              <button
                type="submit"
                disabled={status === 'loading'}
                className="flex-1 rounded-xl bg-primary-600 py-3 font-medium text-white transition-colors hover:bg-primary-700 disabled:opacity-60"
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
