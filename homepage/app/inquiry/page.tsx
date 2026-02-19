'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';

type InquiryItem = {
  id: string;
  message: string;
  createdAt: string;
  replies: { message: string; createdAt: string }[];
};

type Tab = 'form' | 'check';

export default function InquiryPage() {
  const searchParams = useSearchParams();
  const [activeTab, setActiveTab] = useState<Tab>('form');
  const [presetCheck, setPresetCheck] = useState<{ code: string; password: string } | null>(null);

  useEffect(() => {
    if (searchParams.get('tab') === 'check') setActiveTab('check');
  }, [searchParams]);

  return (
    <main className="min-h-screen bg-[#F7F8FA]">
      <div className="mx-auto max-w-2xl px-6 py-20">
        <Link
          href="/"
          className="mb-10 inline-flex items-center gap-1 text-[17px] font-medium text-primary-400 transition-colors hover:text-primary-500"
        >
          ← 홈으로
        </Link>

        <h1 className="mb-6 text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          1:1 문의
        </h1>

        <div className="mb-8 flex gap-1 rounded-[12px] bg-navy-100 p-1">
          <button
            type="button"
            onClick={() => setActiveTab('form')}
            className={`flex-1 rounded-[10px] py-3 text-[16px] font-semibold transition-colors ${
              activeTab === 'form'
                ? 'bg-white text-navy-900 shadow-sm'
                : 'text-navy-600 hover:text-navy-800'
            }`}
          >
            문의 하기
          </button>
          <button
            type="button"
            onClick={() => setActiveTab('check')}
            className={`flex-1 rounded-[10px] py-3 text-[16px] font-semibold transition-colors ${
              activeTab === 'check'
                ? 'bg-white text-navy-900 shadow-sm'
                : 'text-navy-600 hover:text-navy-800'
            }`}
          >
            문의 확인
          </button>
        </div>

        {activeTab === 'form' ? (
          <InquiryFormTab
            onSuccess={(code, password) => {
              setPresetCheck({ code, password });
            }}
            onGoToCheck={() => setActiveTab('check')}
          />
        ) : (
          <InquiryCheckTab preset={presetCheck} />
        )}
      </div>
    </main>
  );
}

function InquiryCheckTab({ preset }: { preset: { code: string; password: string } | null }) {
  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [item, setItem] = useState<InquiryItem | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (preset) {
      setCode(preset.code);
      setPassword(preset.password);
    }
  }, [preset]);

  async function fetchInquiry(codeToFetch: string, passwordToFetch: string) {
    if (!codeToFetch.trim() || !passwordToFetch) return;

    setLoading(true);
    setError('');
    setItem(null);

    try {
      const res = await fetch(
        `/api/inquiry/check?code=${encodeURIComponent(codeToFetch.trim().toUpperCase())}&password=${encodeURIComponent(passwordToFetch)}`
      );
      const data = await res.json().catch(() => ({}));

      if (!res.ok) {
        setError(data.error || '조회에 실패했습니다.');
        return;
      }

      setItem(data);
    } catch {
      setError('조회에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!preset?.code?.trim() || !preset.password) return;
    fetchInquiry(preset.code, preset.password);
  }, [preset?.code, preset?.password]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!code.trim() || !password) return;
    await fetchInquiry(code, password);
  }

  async function handleDelete() {
    if (!code.trim() || !password || deleting) return;
    if (!confirm('문의를 삭제하시겠습니까? 삭제하시면 문의 확인 화면에서는 더 이상 볼 수 없습니다.')) return;

    setDeleting(true);
    setError('');
    try {
      const res = await fetch('/api/inquiry/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: code.trim().toUpperCase(), password }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(data.error || '삭제에 실패했습니다.');
        return;
      }
      setItem(null);
      setError('');
    } catch {
      setError('삭제에 실패했습니다.');
    } finally {
      setDeleting(false);
    }
  }

  const cameViaPreset = !!(preset?.code?.trim() && preset?.password);

  return (
    <div>
      {!cameViaPreset && (
        <>
          <p className="mb-8 text-[17px] text-navy-600">
            문의 등록 시 안내된 문의 번호와 비밀번호로 답변 확인이 가능합니다.
          </p>

          <form onSubmit={handleSubmit} className="mb-10 space-y-4">
            <div>
              <label htmlFor="check-code" className="mb-1 block text-[15px] font-medium text-navy-700">
                문의 번호
              </label>
              <input
                id="check-code"
                type="text"
                autoComplete="off"
                value={code}
                onChange={(e) => setCode(e.target.value.toUpperCase())}
                placeholder="예: ABC123"
                maxLength={6}
                className="w-full rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20 uppercase"
              />
            </div>
            <div>
              <label htmlFor="check-password" className="mb-1 block text-[15px] font-medium text-navy-700">
                비밀번호
              </label>
              <input
                id="check-password"
                type="password"
                autoComplete="off"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="문의 등록 시 입력한 비밀번호"
                className="w-full rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 disabled:opacity-50"
            >
              {loading ? '조회 중...' : '확인'}
            </button>
          </form>
        </>
      )}

      {cameViaPreset && loading && (
        <p className="mb-10 text-[17px] text-navy-600">조회 중...</p>
      )}

      {error && (
        <div className={`mb-8 rounded-[14px] bg-red-50 border border-red-200 p-6 text-red-800 ${cameViaPreset && !loading ? 'mt-4' : ''}`}>
          {error}
        </div>
      )}

      {item && !loading && (
        <div className={`rounded-[14px] border border-navy-200 bg-white p-6 shadow-sm ${cameViaPreset ? 'mt-4' : ''}`}>
          <p className="text-[13px] text-navy-500">
            {new Date(item.createdAt).toLocaleString('ko-KR')}
          </p>
          <p className="mt-2 whitespace-pre-wrap text-[17px] text-navy-800">{item.message}</p>
          {item.replies.length > 0 ? (
            <div className="mt-6 space-y-4 border-t border-navy-100 pt-6">
              <p className="text-[15px] font-semibold text-primary-600">관리자 답변</p>
              {item.replies.map((r, i) => (
                <div key={i} className="rounded-lg bg-primary-50 p-4">
                  <p className="text-[13px] text-navy-500">
                    {new Date(r.createdAt).toLocaleString('ko-KR')}
                  </p>
                  <p className="mt-1 whitespace-pre-wrap text-[17px] text-navy-800">
                    {r.message}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <p className="mt-4 text-[15px] text-navy-500">답변 대기 중입니다.</p>
          )}
          <div className="mt-6 pt-4 border-t border-navy-100">
            <button
              type="button"
              onClick={handleDelete}
              disabled={deleting}
              className="text-[14px] text-red-600 hover:text-red-700 hover:underline disabled:opacity-50"
            >
              {deleting ? '삭제 중...' : '문의 삭제'}
            </button>
          </div>
        </div>
      )}

      <p className="mt-8 text-[14px] text-navy-500">
        급한 문의는{' '}
        <a href="mailto:clubbob@naver.com" className="text-primary-400 hover:underline">
          clubbob@naver.com
        </a>
        {' · '}
        <a href="tel:01063914520" className="text-primary-400 hover:underline">
          010-6391-4520
        </a>
        으로 연락해 주세요.
      </p>
    </div>
  );
}

function InquiryFormTab({
  onSuccess,
  onGoToCheck,
}: {
  onSuccess: (code: string, password: string) => void;
  onGoToCheck: () => void;
}) {
  const [message, setMessage] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');
  const [submittedCode, setSubmittedCode] = useState('');
  const [submittedPassword, setSubmittedPassword] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (submitting) return;

    setSubmitting(true);
    setStatus('idle');
    setErrorMsg('');

    try {
      const res = await fetch('/api/inquiry', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: message.trim(),
          password: password,
        }),
      });

      const data = await res.json().catch(() => ({}));

      if (!res.ok) {
        setStatus('error');
        setErrorMsg(data.error || '문의 등록에 실패했습니다.');
        return;
      }

      setStatus('success');
      const code = data.inquiryCode ?? '';
      setSubmittedCode(code);
      setSubmittedPassword(password);
      onSuccess(code, password);
      setMessage('');
      setPassword('');
    } catch {
      setStatus('error');
      setErrorMsg('문의 등록에 실패했습니다.');
    } finally {
      setSubmitting(false);
    }
  }

  if (status === 'success') {
    return (
      <div className="rounded-[14px] bg-green-50 border border-green-200 p-10 text-center">
        <div className="mb-4 flex justify-center">
          <span className="flex h-16 w-16 items-center justify-center rounded-full bg-green-200 text-3xl text-green-700">
            ✓
          </span>
        </div>
        <p className="text-[1.25rem] font-bold text-green-800">문의가 접수되었습니다.</p>
        <p className="mt-2 text-[17px] text-green-700">빠른 시일 내에 답변 드리겠습니다.</p>
        <div className="mt-6 rounded-xl bg-green-100 border-2 border-green-300 px-6 py-5">
          <div className="space-y-3">
            <div>
              <p className="text-[13px] font-medium text-green-700 mb-1">문의 번호</p>
              <p className="text-[1.5rem] font-bold font-mono text-green-900 tracking-wider">{submittedCode}</p>
            </div>
            <div>
              <p className="text-[13px] font-medium text-green-700 mb-1">비밀번호</p>
              <p className="text-[1.25rem] font-semibold text-green-900 break-all">{submittedPassword}</p>
            </div>
          </div>
        </div>
        <p className="mt-4 text-[15px] text-green-700">
          위 정보를 꼭 기억해 두세요. <strong>문의 확인</strong> 탭에서 답변을 확인할 수 있습니다.
        </p>
        <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center sm:flex-wrap">
          <button
            type="button"
            onClick={onGoToCheck}
            className="flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500"
          >
            답변 확인하기
          </button>
          <Link
            href="/"
            className="flex h-[52px] items-center justify-center rounded-[14px] border-2 border-primary-400 bg-white px-8 text-[17px] font-semibold text-primary-400 transition-colors hover:bg-primary-50"
          >
            홈으로
          </Link>
          <button
            type="button"
            onClick={() => {
              setStatus('idle');
              setSubmittedPassword('');
            }}
            className="flex h-[52px] items-center justify-center rounded-[14px] border-2 border-slate-300 bg-white px-8 text-[17px] font-semibold text-slate-600 transition-colors hover:bg-slate-50"
          >
            다른 문의하기
          </button>
        </div>
      </div>
    );
  }

  return (
    <>
      <p className="mb-8 text-[17px] text-navy-600">
        서비스 이용 중 궁금한 점이 있으시면 문의해 주세요. 영업일 기준 1~2일 내 답변 드립니다.
      </p>

      {status === 'error' && (
        <div className="mb-8 rounded-[14px] bg-red-50 border border-red-200 p-6 text-red-800">
          <p className="font-semibold">{errorMsg}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="message" className="mb-2 block text-[15px] font-medium text-navy-700">
            문의 내용 <span className="text-red-500">*</span>
          </label>
          <textarea
            id="message"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="문의 내용을 입력해 주세요."
            required
            rows={6}
            maxLength={2000}
            className="w-full resize-none rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
          />
          <p className="mt-1 text-[13px] text-navy-500">{message.length} / 2000자</p>
        </div>

        <div>
          <label htmlFor="password" className="mb-2 block text-[15px] font-medium text-navy-700">
            비밀번호 <span className="text-red-500">*</span>
          </label>
          <input
            id="password"
            type="password"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="답변 확인 시 사용할 비밀번호 (4자 이상)"
            required
            minLength={4}
            maxLength={50}
            className="w-full rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
          />
          <p className="mt-1 text-[13px] text-navy-500">문의 확인 시 입력한 비밀번호가 필요합니다.</p>
        </div>

        <button
          type="submit"
          disabled={submitting || !message.trim() || password.length < 4}
          className="flex h-[52px] w-full items-center justify-center rounded-[14px] bg-primary-400 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 active:bg-primary-600 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {submitting ? '등록 중...' : '문의 등록'}
        </button>
      </form>

      <p className="mt-8 text-[14px] text-navy-500">
        급한 문의는{' '}
        <a href="mailto:clubbob@naver.com" className="text-primary-400 hover:underline">
          clubbob@naver.com
        </a>
        {' · '}
        <a href="tel:01063914520" className="text-primary-400 hover:underline">
          010-6391-4520
        </a>
        으로 연락해 주세요.
      </p>
    </>
  );
}
