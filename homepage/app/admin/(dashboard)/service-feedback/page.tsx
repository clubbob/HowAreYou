'use client';

import { useEffect, useState } from 'react';

type Feedback = {
  id: string;
  userId: string;
  userPhone: string | null;
  userDisplayName: string | null;
  source?: string;
  satisfaction: number;
  satisfactionLabel: string;
  reviewedAt: string | null;
  inconvenience: string | null;
  improvementIdea: string | null;
  continueIntent: string | null;
  createdAt: string;
};

type DateFilter = 'all' | '7d' | '30d';

export default function AdminServiceFeedbackPage() {
  const [list, setList] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selected, setSelected] = useState<Feedback | null>(null);
  const [dateFilter, setDateFilter] = useState<DateFilter>('all');
  const [phoneSearch, setPhoneSearch] = useState('');
  const [submitting, setSubmitting] = useState(false);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/admin/service-feedback', { credentials: 'include' });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(
          data.error || (res.status === 401 ? '로그인이 필요합니다.' : '조회에 실패했습니다.')
        );
      }
      setList(Array.isArray(data) ? data : []);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(
        msg === 'Failed to fetch'
          ? '서버에 연결할 수 없습니다. 개발 서버가 실행 중인지 확인해 주세요.'
          : msg
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function markAsReviewed(f: Feedback) {
    if (f.reviewedAt) return;
    try {
      const res = await fetch(`/api/admin/service-feedback/${f.id}`, {
        method: 'PATCH',
        credentials: 'include',
      });
      if (res.ok) {
        setList((prev) =>
          prev.map((x) => (x.id === f.id ? { ...x, reviewedAt: new Date().toISOString() } : x))
        );
        if (selected?.id === f.id) {
          setSelected((s) => (s?.id === f.id ? { ...s, reviewedAt: new Date().toISOString() } : s));
        }
      }
    } catch {
      // ignore
    }
  }

  async function handleDelete(f: Feedback) {
    if (!confirm(`이 피드백을 삭제하시겠습니까?\n\n${f.userPhone || f.userDisplayName || '-'}`)) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/admin/service-feedback/${f.id}`, {
        method: 'DELETE',
        credentials: 'include',
      });
      if (!res.ok) throw new Error('삭제 실패');
      if (selected?.id === f.id) setSelected(null);
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

  const dateFiltered =
    dateCutoff === 0 ? list : list.filter((f) => new Date(f.createdAt).getTime() >= dateCutoff);
  const phoneNorm = (s: string) => s.replace(/\D/g, '');
  const filteredList = phoneSearch.trim()
    ? dateFiltered.filter((f) => {
        const p = (f.userPhone ?? '').replace(/\D/g, '');
        const q = phoneNorm(phoneSearch);
        return p.includes(q) || q.includes(p);
      })
    : dateFiltered;

  if (loading && list.length === 0) return <div className="text-slate-500">로딩 중...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">서비스 개선 피드백</h1>
        <button
          onClick={load}
          disabled={loading}
          className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 text-sm"
        >
          새로고침
        </button>
      </div>

      <div className="mb-4 flex flex-wrap gap-4 items-center">
        <div className="flex items-center gap-2">
          <label htmlFor="phone-search" className="text-sm text-slate-500">
            전화번호:
          </label>
          <input
            id="phone-search"
            type="text"
            value={phoneSearch}
            onChange={(e) => setPhoneSearch(e.target.value)}
            placeholder="번호로 검색"
            className="px-3 py-1.5 border border-slate-300 rounded-lg text-sm w-40 focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div className="flex gap-2 items-center">
          <span className="text-sm text-slate-500">기간:</span>
          <button
          onClick={() => setDateFilter('all')}
          className={`px-3 py-1.5 rounded-lg text-sm ${
            dateFilter === 'all' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'
          }`}
        >
          전체 ({list.length})
        </button>
        <button
          onClick={() => setDateFilter('7d')}
          className={`px-3 py-1.5 rounded-lg text-sm ${
            dateFilter === '7d' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'
          }`}
        >
          최근 7일
        </button>
        <button
          onClick={() => setDateFilter('30d')}
          className={`px-3 py-1.5 rounded-lg text-sm ${
            dateFilter === '30d' ? 'bg-slate-600 text-white' : 'bg-slate-100 text-slate-600'
          }`}
        >
          최근 30일
        </button>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
          <div className="p-4 border-b border-slate-100 font-medium text-slate-700">피드백 목록</div>
          <div className="max-h-[500px] overflow-y-auto">
            {filteredList.map((f) => (
              <div
                key={f.id}
                onClick={() => {
                  setSelected(f);
                  markAsReviewed(f);
                }}
                className={`p-4 border-b border-slate-100 cursor-pointer hover:bg-slate-50 ${
                  selected?.id === f.id ? 'bg-blue-50' : ''
                } ${!f.reviewedAt ? 'border-l-4 border-l-amber-400' : ''}`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2 min-w-0">
                    {!f.reviewedAt && (
                      <span className="shrink-0 w-2 h-2 rounded-full bg-amber-500" title="미확인" />
                    )}
                    <span
                      className={`px-2 py-0.5 rounded text-xs font-medium shrink-0 ${
                        f.satisfaction >= 4 ? 'bg-green-100 text-green-700' : f.satisfaction >= 3 ? 'bg-slate-100 text-slate-600' : 'bg-amber-100 text-amber-700'
                      }`}
                    >
                      {f.satisfactionLabel}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    {f.reviewedAt && (
                      <span className="px-1.5 py-0.5 rounded text-xs text-slate-400 bg-slate-100">확인함</span>
                    )}
                    <span className="text-xs text-slate-400">
                      {new Date(f.createdAt).toLocaleString('ko-KR')}
                    </span>
                  </div>
                </div>
                <p className="text-xs text-slate-500 mt-1 truncate">
                  {f.userPhone || f.userDisplayName || f.userId || '-'}
                  {f.continueIntent && ` · ${f.continueIntent}`}
                </p>
              </div>
            ))}
            {filteredList.length === 0 && (
              <div className="py-12 text-center text-slate-500">
                {list.length === 0
                  ? '피드백이 없습니다.'
                  : phoneSearch.trim()
                    ? '해당 전화번호의 피드백이 없습니다.'
                    : '해당 기간의 피드백이 없습니다.'}
              </div>
            )}
          </div>
        </div>
        <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
          {selected ? (
            <div className="p-6">
              <div className="text-sm text-slate-500 mb-4">
                {selected.source === 'web' && (
                  <span className="inline-block px-2 py-0.5 rounded text-xs bg-slate-200 text-slate-600 mb-1">
                    홈페이지 제출
                  </span>
                )}
                <br />
                {selected.userPhone ?? '-'} · {selected.userDisplayName ?? '-'}
                <br />
                <span className="text-xs">
                  {selected.userId} · {new Date(selected.createdAt).toLocaleString('ko-KR')}
                </span>
              </div>

              <div className="space-y-4">
                <div>
                  <div className="text-xs font-medium text-slate-500 mb-1">만족도</div>
                  <div
                    className={`inline-block px-2 py-1 rounded text-sm font-medium ${
                      selected.satisfaction >= 4 ? 'bg-green-100 text-green-700' : selected.satisfaction >= 3 ? 'bg-slate-100 text-slate-600' : 'bg-amber-100 text-amber-700'
                    }`}
                  >
                    {selected.satisfactionLabel}
                  </div>
                </div>

                {selected.inconvenience && (
                  <div>
                    <div className="text-xs font-medium text-slate-500 mb-1">불편했던 점</div>
                    <p className="text-slate-800 whitespace-pre-wrap p-3 bg-slate-50 rounded-lg text-sm">
                      {selected.inconvenience}
                    </p>
                  </div>
                )}

                {selected.improvementIdea && (
                  <div>
                    <div className="text-xs font-medium text-slate-500 mb-1">개선 아이디어</div>
                    <p className="text-slate-800 whitespace-pre-wrap p-3 bg-slate-50 rounded-lg text-sm">
                      {selected.improvementIdea}
                    </p>
                  </div>
                )}

                {selected.continueIntent && (
                  <div>
                    <div className="text-xs font-medium text-slate-500 mb-1">계속 사용 의향</div>
                    <p className="text-slate-800 text-sm">{selected.continueIntent}</p>
                  </div>
                )}

                {!selected.inconvenience &&
                  !selected.improvementIdea &&
                  !selected.continueIntent && (
                    <p className="text-slate-500 text-sm">추가 의견 없음</p>
                  )}

                <div className="mt-6 pt-4 border-t border-slate-200">
                  <button
                    onClick={() => handleDelete(selected)}
                    disabled={submitting}
                    className="px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 disabled:opacity-50 text-sm"
                  >
                    {submitting ? '삭제 중...' : '피드백 삭제'}
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="p-12 text-center text-slate-500">피드백을 선택하세요.</div>
          )}
        </div>
      </div>
    </div>
  );
}
