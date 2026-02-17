'use client';

import { useEffect, useState } from 'react';

type Reply = { message: string; createdAt: string };
type Inquiry = {
  id: string;
  userId: string;
  userPhone: string;
  userDisplayName: string | null;
  role: string;
  message: string;
  createdAt: string;
  replies: Reply[];
};

export default function AdminInquiriesPage() {
  const [list, setList] = useState<Inquiry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selected, setSelected] = useState<Inquiry | null>(null);
  const [replyText, setReplyText] = useState('');
  const [submitting, setSubmitting] = useState(false);

  function load() {
    setLoading(true);
    fetch('/api/admin/inquiries')
      .then((res) => {
        if (!res.ok) throw new Error('조회 실패');
        return res.json();
      })
      .then(setList)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  async function handleReply() {
    if (!selected || !replyText.trim()) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/admin/inquiries/${selected.id}/reply`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: replyText.trim() }),
      });
      if (!res.ok) throw new Error('답변 등록 실패');
      setReplyText('');
      setSelected(null);
      load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setSubmitting(false);
    }
  }

  if (loading && list.length === 0) return <div className="text-slate-500">로딩 중...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-800 mb-6">1:1 문의</h1>
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
          <div className="p-4 border-b border-slate-100 font-medium text-slate-700">문의 목록</div>
          <div className="max-h-[500px] overflow-y-auto">
            {list.map((i) => (
              <div
                key={i.id}
                onClick={() => setSelected(i)}
                className={`p-4 border-b border-slate-100 cursor-pointer hover:bg-slate-50 ${
                  selected?.id === i.id ? 'bg-blue-50' : ''
                }`}
              >
                <p className="text-sm text-slate-600 truncate">{i.message}</p>
                <p className="text-xs text-slate-400 mt-1">
                  {i.userPhone} · {new Date(i.createdAt).toLocaleString('ko-KR')}
                  {i.replies.length > 0 && ` · 답변 ${i.replies.length}건`}
                </p>
              </div>
            ))}
            {list.length === 0 && (
              <div className="py-12 text-center text-slate-500">문의가 없습니다.</div>
            )}
          </div>
        </div>
        <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
          {selected ? (
            <div className="p-6">
              <div className="text-sm text-slate-500 mb-2">
                {selected.userPhone} · {selected.userDisplayName ?? '-'} · {selected.role}
              </div>
              <p className="text-slate-800 whitespace-pre-wrap mb-6">{selected.message}</p>
              {selected.replies.length > 0 && (
                <div className="space-y-3 mb-6">
                  <div className="font-medium text-slate-700">답변</div>
                  {selected.replies.map((r, idx) => (
                    <div key={idx} className="p-3 bg-green-50 rounded-lg text-sm">
                      <div className="text-xs text-slate-500 mb-1">
                        {new Date(r.createdAt).toLocaleString('ko-KR')}
                      </div>
                      {r.message}
                    </div>
                  ))}
                </div>
              )}
              <textarea
                value={replyText}
                onChange={(e) => setReplyText(e.target.value)}
                placeholder="답변을 입력하세요"
                className="w-full px-4 py-3 border border-slate-300 rounded-lg mb-4 min-h-[100px]"
                rows={4}
              />
              <button
                onClick={handleReply}
                disabled={!replyText.trim() || submitting}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              >
                {submitting ? '등록 중...' : '답변 등록'}
              </button>
            </div>
          ) : (
            <div className="p-12 text-center text-slate-500">문의를 선택하세요.</div>
          )}
        </div>
      </div>
    </div>
  );
}
