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
  const [presetEmail, setPresetEmail] = useState('');

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
            onSuccess={(email) => {
              setPresetEmail(email);
              setActiveTab('check');
            }}
          />
        ) : (
          <InquiryCheckTab presetEmail={presetEmail} />
        )}
      </div>
    </main>
  );
}

function InquiryCheckTab({ presetEmail }: { presetEmail: string }) {
  const [email, setEmail] = useState(presetEmail);
  const [loading, setLoading] = useState(false);
  const [list, setList] = useState<InquiryItem[] | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (presetEmail) setEmail(presetEmail);
  }, [presetEmail]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim()) return;

    setLoading(true);
    setError('');
    setList(null);

    try {
      const res = await fetch(`/api/inquiry/check?email=${encodeURIComponent(email.trim())}`);
      const data = await res.json().catch(() => ({}));

      if (!res.ok) {
        setError(data.error || '조회에 실패했습니다.');
        return;
      }

      setList(Array.isArray(data) ? data : []);
    } catch {
      setError('조회에 실패했습니다.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="mb-8 text-[17px] text-navy-600">
        문의 등록 시 입력한 이메일로 답변 확인이 가능합니다.
      </p>

      <form onSubmit={handleSubmit} className="mb-10">
        <div className="flex gap-3">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="이메일 주소"
            required
            className="flex-1 rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
          />
          <button
            type="submit"
            disabled={loading}
            className="flex h-[52px] shrink-0 items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500 disabled:opacity-50"
          >
            {loading ? '조회 중...' : '확인'}
          </button>
        </div>
      </form>

      {error && (
        <div className="mb-8 rounded-[14px] bg-red-50 border border-red-200 p-6 text-red-800">
          {error}
        </div>
      )}

      {list !== null && list.length === 0 && (
        <div className="rounded-[14px] bg-slate-50 border border-slate-200 p-8 text-center text-navy-600">
          해당 이메일로 등록된 문의가 없습니다.
        </div>
      )}

      {list !== null && list.length > 0 && (
        <div className="space-y-6">
          {list.map((item) => (
            <div
              key={item.id}
              className="rounded-[14px] border border-navy-200 bg-white p-6 shadow-sm"
            >
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
            </div>
          ))}
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

function InquiryFormTab({ onSuccess }: { onSuccess: (email: string) => void }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [message, setMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState('');

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
          name: name.trim() || undefined,
          email: email.trim() || undefined,
          phone: phone.trim() || undefined,
          message: message.trim(),
        }),
      });

      const data = await res.json().catch(() => ({}));

      if (!res.ok) {
        setStatus('error');
        setErrorMsg(data.error || '문의 등록에 실패했습니다.');
        return;
      }

      setStatus('success');
      const submittedEmail = email.trim();
      setName('');
      setEmail('');
      setPhone('');
      setMessage('');
      if (submittedEmail) onSuccess(submittedEmail);
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
        <p className="mt-4 text-[15px] text-green-600">
          이메일을 입력하셨다면 <strong>문의 확인</strong> 탭에서 답변을 확인할 수 있습니다.
        </p>
        <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <Link
            href="/"
            className="flex h-[52px] items-center justify-center rounded-[14px] bg-primary-400 px-8 text-[17px] font-semibold text-white transition-colors hover:bg-primary-500"
          >
            홈으로
          </Link>
          <button
            type="button"
            onClick={() => {
              setStatus('idle');
            }}
            className="flex h-[52px] items-center justify-center rounded-[14px] border-2 border-primary-400 bg-white px-8 text-[17px] font-semibold text-primary-400 transition-colors hover:bg-primary-50"
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
          <label htmlFor="name" className="mb-2 block text-[15px] font-medium text-navy-700">
            이름/닉네임 (선택)
          </label>
          <input
            id="name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="홍길동"
            className="w-full rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
          />
        </div>

        <div>
          <label htmlFor="email" className="mb-2 block text-[15px] font-medium text-navy-700">
            이메일 (선택)
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="example@email.com"
            className="w-full rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
          />
          <p className="mt-1 text-[13px] text-navy-500">답변 확인 시 필요합니다</p>
        </div>

        <div>
          <label htmlFor="phone" className="mb-2 block text-[15px] font-medium text-navy-700">
            연락처 (선택)
          </label>
          <input
            id="phone"
            type="tel"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="010-1234-5678"
            className="w-full rounded-[12px] border border-navy-200 bg-white px-4 py-3 text-[17px] text-navy-900 placeholder:text-navy-400 focus:border-primary-400 focus:outline-none focus:ring-2 focus:ring-primary-400/20"
          />
        </div>

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

        <button
          type="submit"
          disabled={submitting || !message.trim()}
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
