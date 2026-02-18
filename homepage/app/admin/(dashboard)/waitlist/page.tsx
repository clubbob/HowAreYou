'use client';

import { useEffect, useRef, useState } from 'react';

type WaitlistItem = { id: string; email: string; phone: string; createdAt: string };

export default function AdminWaitlistPage() {
  const [list, setList] = useState<WaitlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [deleting, setDeleting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editPhone, setEditPhone] = useState('');

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
    ? list.filter((i) => {
        const q = search.trim().toLowerCase();
        return (
          i.email.toLowerCase().includes(q) ||
          (i.phone && i.phone.replace(/\s/g, '').includes(q.replace(/\s/g, '')))
        );
      })
    : list;

  function handleExport() {
    const headers = ['이메일', '연락처', '신청일시'];
    const rows = filtered.map((i) => [
      i.email,
      i.phone || '-',
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

  const allFilteredSelected = filtered.length > 0 && filtered.every((i) => selectedIds.has(i.id));
  const selectedInFiltered = selectedIds.size > 0 && filtered.some((i) => selectedIds.has(i.id));
  const selectAllRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const el = selectAllRef.current;
    if (el) el.indeterminate = selectedInFiltered && !allFilteredSelected;
  }, [selectedInFiltered, allFilteredSelected]);

  function toggleSelectAll() {
    if (allFilteredSelected) {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        filtered.forEach((i) => next.delete(i.id));
        return next;
      });
    } else {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        filtered.forEach((i) => next.add(i.id));
        return next;
      });
    }
  }

  function toggleSelect(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function handleSavePhone(id: string) {
    const phone = editPhone.trim().replace(/\s/g, '');
    if (!phone) {
      alert('연락처를 입력해 주세요.');
      return;
    }
    try {
      const res = await fetch(`/api/admin/waitlist/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      });
      if (!res.ok) throw new Error('수정 실패');
      setEditingId(null);
      setEditPhone('');
      load();
    } catch (e) {
      alert('연락처 수정에 실패했습니다.');
    }
  }

  function startEdit(item: WaitlistItem) {
    setEditingId(item.id);
    setEditPhone(item.phone || '');
  }

  async function handleDeleteSelected() {
    if (selectedIds.size === 0) {
      alert('삭제할 항목을 선택해 주세요.');
      return;
    }
    if (!confirm(`선택한 ${selectedIds.size}명을 삭제하시겠습니까?`)) return;

    setDeleting(true);
    try {
      const ids = [...selectedIds];
      const results = await Promise.allSettled(
        ids.map((id) => fetch(`/api/admin/waitlist/${id}`, { method: 'DELETE' }))
      );
      const failed = results.filter((r) => r.status === 'rejected' || (r.status === 'fulfilled' && !r.value.ok));
      if (failed.length > 0) {
        alert(`${failed.length}건 삭제에 실패했습니다.`);
      }
      setSelectedIds(new Set());
      load();
    } catch (e) {
      alert('삭제 중 오류가 발생했습니다.');
    } finally {
      setDeleting(false);
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
            onClick={handleDeleteSelected}
            disabled={deleting || selectedIds.size === 0}
            className="px-4 py-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
          >
            {deleting ? '삭제 중...' : `선택 삭제 (${selectedIds.size})`}
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
              <th className="w-12 py-3 px-4">
                <input
                  type="checkbox"
                  ref={selectAllRef}
                  checked={filtered.length > 0 && allFilteredSelected}
                  onChange={toggleSelectAll}
                  className="rounded border-slate-300"
                />
              </th>
              <th className="w-16 min-w-[4rem] py-3 px-4 text-left text-sm font-medium text-slate-600 whitespace-nowrap">번호</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">이메일</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">연락처</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">신청일시</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((i, idx) => (
              <tr key={i.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="w-12 py-3 px-4">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(i.id)}
                    onChange={() => toggleSelect(i.id)}
                    className="rounded border-slate-300"
                  />
                </td>
                <td className="w-16 min-w-[4rem] py-3 px-4 text-sm text-slate-600">{idx + 1}</td>
                <td className="py-3 px-4">{i.email}</td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {editingId === i.id ? (
                    <div className="flex items-center gap-2">
                      <input
                        type="tel"
                        value={editPhone}
                        onChange={(e) => setEditPhone(e.target.value)}
                        placeholder="010-1234-5678"
                        className="w-36 rounded border border-slate-300 px-2 py-1 text-sm"
                        autoFocus
                      />
                      <button
                        onClick={() => handleSavePhone(i.id)}
                        className="text-xs text-blue-600 hover:underline"
                      >
                        저장
                      </button>
                      <button
                        onClick={() => { setEditingId(null); setEditPhone(''); }}
                        className="text-xs text-slate-500 hover:underline"
                      >
                        취소
                      </button>
                    </div>
                  ) : (
                    <span
                      className={`cursor-pointer ${!i.phone ? 'text-amber-600 hover:underline' : ''}`}
                      onClick={() => startEdit(i)}
                      title={i.phone ? '클릭하여 수정' : '연락처 없음 - 클릭하여 추가'}
                    >
                      {i.phone || '-'}
                    </span>
                  )}
                </td>
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
