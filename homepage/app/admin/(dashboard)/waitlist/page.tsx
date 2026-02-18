'use client';

import { useEffect, useState } from 'react';

type WaitlistItem = { id: string; email: string; createdAt: string };

export default function AdminWaitlistPage() {
  const [list, setList] = useState<WaitlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  function load() {
    setLoading(true);
    fetch('/api/admin/waitlist')
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

  const filtered = search.trim()
    ? list.filter((i) => i.email.toLowerCase().includes(search.trim().toLowerCase()))
    : list;

  function handleExport() {
    const headers = ['이메일', '신청일시'];
    const rows = filtered.map((i) => [
      i.email,
      new Date(i.createdAt).toLocaleString('ko-KR'),
    ]);
    const csv = [headers.join(','), ...rows.map((r) => r.map((c) => `"${c}"`).join(','))].join('\n');
    const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `베타대기_${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  async function handleCopyEmails() {
    const emails = filtered.map((i) => i.email).filter(Boolean);
    const text = emails.join('\n');
    if (!text) {
      alert('복사할 이메일이 없습니다.');
      return;
    }
    try {
      await navigator.clipboard.writeText(text);
      alert(`${emails.length}개 이메일이 클립보드에 복사되었습니다.`);
    } catch {
      alert('복사에 실패했습니다.');
    }
  }

  if (loading && list.length === 0) return <div className="text-slate-500">로딩 중...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-bold text-slate-800">베타 대기</h1>
        <div className="flex gap-2">
          <input
            type="text"
            placeholder="이메일 검색"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-4 py-2 border border-slate-300 rounded-lg w-64"
          />
          <button
            onClick={handleCopyEmails}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            이메일 일괄 복사
          </button>
          <button
            onClick={handleExport}
            className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200"
          >
            CSV 내보내기
          </button>
          <button
            onClick={load}
            disabled={loading}
            className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 text-sm"
          >
            새로고침
          </button>
        </div>
      </div>

      <p className="mb-4 text-sm text-slate-500">
        총 {filtered.length}명 / {list.length}명 (선착순 100명 한정)
      </p>

      <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-slate-50">
            <tr>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">이메일</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">신청일시</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((i) => (
              <tr key={i.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="py-3 px-4">{i.email}</td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {new Date(i.createdAt).toLocaleString('ko-KR')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="py-12 text-center text-slate-500">
            {list.length === 0 ? '대기자가 없습니다.' : '검색 결과가 없습니다.'}
          </div>
        )}
      </div>
    </div>
  );
}
