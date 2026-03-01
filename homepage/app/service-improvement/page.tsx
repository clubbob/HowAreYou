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

const NEEDS_REASON_INTENTS = ['고민 중입니다', '사용하지 않을 것 같습니다'];

export default function ServiceImprovementPage() {
  const [satisfaction, setSatisfaction] = useState<number | null>(null);
  const [complaint, setComplaint] = useState('');
  const [featureRequest, setFeatureRequest] = useState('');
  const [continueIntent, setContinueIntent] = useState<string | null>(null);
  const [retentionReason, setRetentionReason] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

  const needsComplaint = satisfaction !== null && (satisfaction === 1 || satisfaction === 2);
  const needsRetentionReason =
    continueIntent !== null && NEEDS_REASON_INTENTS.includes(continueIntent);

  function canSubmit() {
    if (satisfaction === null || continueIntent === null) return false;
    if (needsComplaint && !complaint.trim()) return false;
    if (needsRetentionReason && !retentionReason.trim()) return false;
    return true;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (submitting || !canSubmit()) return;

    setSubmitting(true);
    setStatus('idle');
    setErrorMsg('');

    try {
      const res = await fetch('/api/service-feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          satisfaction,
          inconvenience: complaint.trim() || undefined,
          improvementIdea: featureRequest.trim() || undefined,
          continueIntent: continueIntent || undefined,
          retentionReason:
            needsRetentionReason && retentionReason.trim() ? retentionReason.trim() : undefined,
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
      setComplaint('');
      setFeatureRequest('');
      setContinueIntent(null);
      setRetentionReason('');
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
              더 가벼운 안심 루틴을 만들겠습니다.
            </p>
            <div className="mt-8">
              <Link
                href="/"
                className="inline-flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500"
              >
                오늘도 안부 남기기
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
          더 나은 안심을 위해
        </h1>
        <p className="mb-2 text-[17px] text-navy-600">
          여러분의 의견이 &quot;오늘 어때&quot;를 더 단단하게 만듭니다.
        </p>
        <p className="mb-8 text-[17px] text-navy-600">
          사용하면서 느낀 점을 자유롭게 남겨주세요.
        </p>

        {status === 'error' && (
          <div className="mb-8 rounded-[14px] bg-red-50 border border-red-200 p-6 text-red-800">
            <p className="font-semibold">{errorMsg}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-8">
          {/* 1. 사용 경험 (필수) */}
          <div>
            <label className="mb-3 block text-[15px] font-medium text-navy-700">
              1. 사용 경험은 어떠셨나요? <span className="text-red-500">*</span>
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
            {needsComplaint && (
              <p className="mt-2 text-[13px] text-amber-600">
                ※ &quot;아쉬움 / 많이 불편함&quot; 선택 시 아래 문항 필수 표시
              </p>
            )}
          </div>

          {/* 2. 가장 아쉬웠던 점 */}
          <div>
            <label htmlFor="complaint" className="mb-2 block text-[15px] font-medium text-navy-700">
              2. 가장 아쉬웠던 점은 무엇인가요?
              {needsComplaint && <span className="ml-1 text-red-500">*</span>}
            </label>
            <textarea
              id="complaint"
              value={complaint}
              onChange={(e) => setComplaint(e.target.value)}
              placeholder="사용 중 불편했던 점을 자유롭게 적어주세요."
              rows={4}
              maxLength={1000}
              className="w-full resize-none rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
            />
            <p className="mt-1 text-[13px] text-navy-500">{complaint.length} / 1000자</p>
          </div>

          {/* 3. 이런 기능이 추가되면 좋겠어요 */}
          <div>
            <label htmlFor="featureRequest" className="mb-2 block text-[15px] font-medium text-navy-700">
              3. 이런 기능이 추가되면 좋겠어요
            </label>
            <textarea
              id="featureRequest"
              value={featureRequest}
              onChange={(e) => setFeatureRequest(e.target.value)}
              placeholder="추가되었으면 하는 기능이나 아이디어를 적어주세요."
              rows={4}
              maxLength={1000}
              className="w-full resize-none rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
            />
            <p className="mt-1 text-[13px] text-navy-500">{featureRequest.length} / 1000자</p>
          </div>

          {/* 4. 계속 사용 의향 (필수) */}
          <div>
            <label className="mb-3 block text-[15px] font-medium text-navy-700">
              4. 앞으로도 계속 사용하실 의향이 있으신가요? <span className="text-red-500">*</span>
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
            {needsRetentionReason && (
              <>
                <p className="mt-2 text-[13px] text-amber-600">
                  ※ &quot;고민 중 / 사용하지 않을 것 같습니다&quot; 선택 시 이유 입력 요청
                </p>
                <textarea
                  value={retentionReason}
                  onChange={(e) => setRetentionReason(e.target.value)}
                  placeholder="이유를 적어주세요."
                  rows={3}
                  maxLength={500}
                  className="mt-3 w-full resize-none rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
                />
              </>
            )}
          </div>

          <button
            type="submit"
            disabled={submitting || !canSubmit()}
            className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {submitting ? '전송 중...' : '의견 보내기'}
          </button>
        </form>
      </div>
    </main>
  );
}
