'use client';

import { useState } from 'react';
import Link from 'next/link';

const SATISFACTION_OPTIONS = [
  { value: 5, label: '매우 만족' },
  { value: 4, label: '만족' },
  { value: 3, label: '보통' },
  { value: 2, label: '아쉬움' },
  { value: 1, label: '많이 불편함' },
] as const;

const CONTINUE_INTENTS = [
  '계속 사용할 예정입니다',
  '고민 중입니다',
  '사용하지 않을 것 같습니다',
] as const;

export default function ServiceImprovementPage() {
  const [satisfaction, setSatisfaction] = useState<number | null>(null);
  const [inconvenience, setInconvenience] = useState('');
  const [improvementIdea, setImprovementIdea] = useState('');
  const [continueIntent, setContinueIntent] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (submitting || satisfaction === null) return;

    setSubmitting(true);
    setStatus('idle');
    setErrorMsg('');

    try {
      const res = await fetch('/api/service-feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          satisfaction,
          inconvenience: inconvenience.trim() || undefined,
          improvementIdea: improvementIdea.trim() || undefined,
          continueIntent: continueIntent || undefined,
        }),
      });

      const data = await res.json().catch(() => ({}));

      if (!res.ok) {
        setStatus('error');
        setErrorMsg(data.error || '의견 전송에 실패했습니다.');
        return;
      }

      setStatus('success');
      setSatisfaction(null);
      setInconvenience('');
      setImprovementIdea('');
      setContinueIntent(null);
    } catch {
      setStatus('error');
      setErrorMsg('의견 전송에 실패했습니다.');
    } finally {
      setSubmitting(false);
    }
  }

  if (status === 'success') {
    return (
      <main className="min-h-screen bg-[#F7F8FA]">
        <div className="mx-auto max-w-2xl px-6 py-20">
          <Link
            href="/"
            className="mb-10 inline-flex items-center gap-1 text-[17px] font-medium text-primary-400 transition-colors hover:text-primary-500"
          >
            ← 홈으로
          </Link>

          <div className="rounded-[14px] bg-green-50 border border-green-200 p-10 text-center">
            <div className="mb-4 flex justify-center">
              <span className="flex h-16 w-16 items-center justify-center rounded-full bg-green-200 text-3xl text-green-700">
                ✓
              </span>
            </div>
            <p className="text-[1.25rem] font-bold text-green-800">소중한 의견 감사합니다.</p>
            <p className="mt-2 text-[17px] text-green-700">
              더 나은 서비스를 위해 반영하겠습니다.
            </p>
            <div className="mt-8">
              <Link
                href="/"
                className="inline-flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500"
              >
                홈으로
              </Link>
            </div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-[#F7F8FA]">
      <div className="mx-auto max-w-2xl px-6 py-20">
        <Link
          href="/"
          className="mb-10 inline-flex items-center gap-1 text-[17px] font-medium text-primary-400 transition-colors hover:text-primary-500"
        >
          ← 홈으로
        </Link>

        <h1 className="mb-2 text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          서비스 개선
        </h1>
        <p className="mb-8 text-[17px] text-navy-600">
          오늘 어때를 더 좋게 만들기 위해 여러분의 의견을 듣고 있습니다.
        </p>

        {status === 'error' && (
          <div className="mb-8 rounded-[14px] bg-red-50 border border-red-200 p-6 text-red-800">
            <p className="font-semibold">{errorMsg}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* 1. 만족도 (필수) */}
          <div>
            <label className="mb-3 block text-[15px] font-medium text-navy-700">
              1. 만족도 평가 <span className="text-red-500">*</span>
            </label>
            <div className="space-y-2">
              {SATISFACTION_OPTIONS.map((opt) => (
                <label
                  key={opt.value}
                  className={`flex cursor-pointer items-center gap-3 rounded-[12px] border px-4 py-3 transition-colors ${
                    satisfaction === opt.value
                      ? 'border-primary-400 bg-primary-50'
                      : 'border-navy-200 bg-white hover:border-navy-300'
                  }`}
                >
                  <input
                    type="radio"
                    name="satisfaction"
                    value={opt.value}
                    checked={satisfaction === opt.value}
                    onChange={() => setSatisfaction(opt.value)}
                    className="h-4 w-4 text-primary-400"
                  />
                  <span className="text-[17px] text-navy-800">{opt.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* 2. 불편했던 점 */}
          <div>
            <label htmlFor="inconvenience" className="mb-2 block text-[15px] font-medium text-navy-700">
              2. 불편했던 점
            </label>
            <textarea
              id="inconvenience"
              value={inconvenience}
              onChange={(e) => setInconvenience(e.target.value)}
              placeholder="사용 중 불편했던 점이 있다면 적어주세요."
              rows={4}
              maxLength={1000}
              className="w-full resize-none rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
            />
            <p className="mt-1 text-[13px] text-navy-500">{inconvenience.length} / 1000자</p>
          </div>

          {/* 3. 개선 아이디어 */}
          <div>
            <label htmlFor="improvementIdea" className="mb-2 block text-[15px] font-medium text-navy-700">
              3. 개선 아이디어
            </label>
            <textarea
              id="improvementIdea"
              value={improvementIdea}
              onChange={(e) => setImprovementIdea(e.target.value)}
              placeholder="이런 기능이 추가되면 좋겠어요."
              rows={4}
              maxLength={1000}
              className="w-full resize-none rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
            />
            <p className="mt-1 text-[13px] text-navy-500">{improvementIdea.length} / 1000자</p>
          </div>

          {/* 4. 계속 사용 의향 */}
          <div>
            <label className="mb-3 block text-[15px] font-medium text-navy-700">
              4. 계속 사용 의향
            </label>
            <div className="space-y-2">
              {CONTINUE_INTENTS.map((intent) => (
                <label
                  key={intent}
                  className={`flex cursor-pointer items-center gap-3 rounded-[12px] border px-4 py-3 transition-colors ${
                    continueIntent === intent
                      ? 'border-primary-400 bg-primary-50'
                      : 'border-navy-200 bg-white hover:border-navy-300'
                  }`}
                >
                  <input
                    type="radio"
                    name="continueIntent"
                    value={intent}
                    checked={continueIntent === intent}
                    onChange={() => setContinueIntent(intent)}
                    className="h-4 w-4 text-primary-400"
                  />
                  <span className="text-[17px] text-navy-800">{intent}</span>
                </label>
              ))}
            </div>
          </div>

          <button
            type="submit"
            disabled={submitting || satisfaction === null}
            className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {submitting ? '전송 중...' : '의견 보내기'}
          </button>
        </form>
      </div>
    </main>
  );
}
