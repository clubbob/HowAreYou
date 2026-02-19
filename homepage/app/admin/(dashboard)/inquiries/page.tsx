'use client';

import { useEffect, useState } from 'react';

type Reply = { message: string; createdAt: string };

function roleLabel(role: string): string {
  switch (role) {
    case 'visitor':
      return '홈페이지 방문자';
    case 'subject':
      return '보호대상자';
    case 'guardian':
      return '보호자';
    case 'both':
      return '둘 다';
    default:
      return role;
  }
}
type StatusFilter = 'all' | 'unanswered' | 'answered';
type DateFilter = 'all' | '7d' | '30d';
type Inquiry = {
  id: string;
  userId: string;
  userPhone: string;
  userDisplayName: string | null;
  role: string;
  inquiryCode?: string | null;
  message: string;
  createdAt: string;
  deletedByUserAt: string | null;
  replies: Reply[];
};

export default function AdminInquiriesPage() {
  const [list, setList] = useState<Inquiry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selected, setSelected] = useState<Inquiry | null>(null);
  const [replyText, setReplyText] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [dateFilter, setDateFilter] = useState<DateFilter>('all');

  async function load() {
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/admin/inquiries', { credentials: 'include' });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(data.error || (res.status === 401 ? '로그인이 필요합니다.' : '조회에 실패했습니다.'));
      }
      setList(Array.isArray(data) ? data : []);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(msg === 'Failed to fetch'
        ? '서버에 연결할 수 없습니다. 개발 서버가 실행 중인지 확인해 주세요.'
        : msg);
    } finally {
      setLoading(false);
    }
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

  async function handleDelete(inquiry: Inquiry) {
    if (!confirm(`이 문의를 삭제하시겠습니까?\n\n"${inquiry.message.slice(0, 50)}..."`)) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/admin/inquiries/${inquiry.id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('삭제 실패');
      if (selected?.id === inquiry.id) setSelected(null);
      load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setSubmitting(false);
    }
  }

  const now = Date.now();
  const dateCutoff =
    dateFilter === '7d'
      ? now - 7 * 24 * 60 * 60 * 1000
      : dateFilter === '30d'
        ? now - 30 * 24 * 60 * 60 * 1000
        : 0;
  const filteredList = (statusFilter === 'unanswered'
    ? list.filter((i) => i.replies.length === 0)
    : statusFilter === 'answered'
      ? list.filter((i) => i.replies.length > 0)
      : list
  ).filter((i) => dateCutoff === 0 || new Date(i.createdAt).getTime() >= dateCutoff);

  if (loading && list.length === 0) return <div className="text-slate-500">로딩 중...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">1:1 문의</h1>
        <button
          onClick={load}
          disabled={loading}
          className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 text-sm"
        >
          새로고침
        </button>
      </div>

      <div className="mb-4 flex gap-2">
        <button
          onClick={() => setStatusFilter('all')}
          className={`px-3 py-1.5 rounded-lg text-sm font-medium ${
            statusFilter === 'all' ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-600'
          }`}
        >
          전체 ({list.length})
        </button>
        <button
          onClick={() => setStatusFilter('unanswered')}
          className={`px-3 py-1.5 rounded-lg text-sm font-medium ${
            statusFilter === 'unanswered' ? 'bg-amber-600 text-white' : 'bg-slate-100 text-slate-600'
          }`}
        >
          미답변 ({list.filter((i) => i.replies.length === 0).length})
        </button>
        <button
          onClick={() => setStatusFilter('answered')}
          className={`px-3 py-1.5 rounded-lg text-sm font-medium ${
            statusFilter === 'answered' ? 'bg-green-600 text-white' : 'bg-slate-100 text-slate-600'
          }`}
        >
          답변완료 ({list.filter((i) => i.replies.length > 0).length})
        </button>
        <div className="ml-4 flex gap-2 items-center">
          <span className="text-sm text-slate-500">기간:</span>
          <button
            onClick={() => setDateFilter('all')}
            className={`px-3 py-1.5 rounded-lg text-sm ${dateFilter === 'all' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'}`}
          >
            전체
          </button>
          <button
            onClick={() => setDateFilter('7d')}
            className={`px-3 py-1.5 rounded-lg text-sm ${dateFilter === '7d' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'}`}
          >
            최근 7일
          </button>
          <button
            onClick={() => setDateFilter('30d')}
            className={`px-3 py-1.5 rounded-lg text-sm ${dateFilter === '30d' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'}`}
          >
            최근 30일
          </button>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
          <div className="p-4 border-b border-slate-100 font-medium text-slate-700">문의 목록</div>
          <div className="max-h-[500px] overflow-y-auto">
            {filteredList.map((i) => (
              <div
                key={i.id}
                onClick={() => setSelected(i)}
                className={`p-4 border-b border-slate-100 cursor-pointer hover:bg-slate-50 ${
                  selected?.id === i.id ? 'bg-blue-50' : ''
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <p className="text-sm text-slate-600 truncate flex-1">{i.message}</p>
                  <div className="shrink-0 flex gap-1 flex-wrap justify-end">
                    {i.deletedByUserAt && (
                      <span className="px-2 py-0.5 rounded text-xs font-medium bg-slate-200 text-slate-600">
                        문의자 삭제
                      </span>
                    )}
                    <span
                      className={`px-2 py-0.5 rounded text-xs font-medium ${
                        i.replies.length > 0 ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                      }`}
                    >
                      {i.replies.length > 0 ? '답변완료' : '미답변'}
                    </span>
                  </div>
                </div>
                <p className="text-xs text-slate-400 mt-1">
                  {(i.role === 'visitor' && i.inquiryCode) ? `문의번호 ${i.inquiryCode}` : i.userPhone} · {new Date(i.createdAt).toLocaleString('ko-KR')}
                  {i.replies.length > 0 && ` · 답변 ${i.replies.length}건`}
                </p>
              </div>
            ))}
            {filteredList.length === 0 && (
              <div className="py-12 text-center text-slate-500">
                {list.length === 0 ? '문의가 없습니다.' : '해당 조건의 문의가 없습니다.'}
              </div>
            )}
          </div>
        </div>
        <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
          {selected ? (
            <div className="p-6">
              <div className="text-sm text-slate-500 mb-2">
                {(selected.role === 'visitor' && selected.inquiryCode) ? `문의번호 ${selected.inquiryCode}` : `${selected.userPhone ?? ''} · ${selected.userDisplayName ?? '-'}`} · {roleLabel(selected.role)}
                {selected.deletedByUserAt && (
                  <span className="ml-2 px-2 py-0.5 rounded text-xs font-medium bg-slate-200 text-slate-600">
                    문의자 삭제됨
                  </span>
                )}
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
              <div className="flex gap-2">
                <button
                  onClick={handleReply}
                  disabled={!replyText.trim() || submitting}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {submitting ? '등록 중...' : '답변 등록'}
                </button>
                <button
                  onClick={() => handleDelete(selected)}
                  disabled={submitting}
                  className="px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 disabled:opacity-50"
                >
                  문의 삭제
                </button>
              </div>
            </div>
          ) : (
            <div className="p-12 text-center text-slate-500">문의를 선택하세요.</div>
          )}
        </div>
      </div>
    </div>
  );
}
