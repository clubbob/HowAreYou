'use client';

import { useEffect, useState } from 'react';

type WaitlistItem = { id: string; phone: string; name: string; createdAt: string; loggedIn: boolean; appInstalled: boolean; lastFcmSentAt: string | null; lastFcmOpenedAt: string | null };

export default function AdminWaitlistPage() {
  const [list, setList] = useState<WaitlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [deleting, setDeleting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editPhone, setEditPhone] = useState('');
  const [editingNameId, setEditingNameId] = useState<string | null>(null);
  const [editName, setEditName] = useState('');
  const [showFcmModal, setShowFcmModal] = useState(false);
  const [fcmTitle, setFcmTitle] = useState('');
  const [fcmBody, setFcmBody] = useState('');
  const [fcmSending, setFcmSending] = useState(false);

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
        const q = search.trim().replace(/\s/g, '');
        return (i.phone ?? '').replace(/\s/g, '').includes(q);
      })
    : list;

  async function handleCopyPhones() {
    const phones = filtered.map((i) => i.phone).filter(Boolean);
    const text = phones.join('\n');
    if (!text) {
      alert('복사할 휴대폰 번호가 없습니다.');
      return;
    }
    try {
      await navigator.clipboard.writeText(text);
      alert(`${phones.length}개 휴대폰 번호가 클립보드에 복사되었습니다.`);
    } catch {
      alert('복사에 실패했습니다.');
    }
  }

  const allFilteredSelected = filtered.length > 0 && filtered.every((i) => selectedIds.has(i.id));

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
      alert('휴대폰 번호를 입력해 주세요.');
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
      alert('휴대폰 번호 수정에 실패했습니다.');
    }
  }

  function startEdit(item: WaitlistItem) {
    setEditingId(item.id);
    setEditPhone(item.phone || '');
  }

  function startEditName(item: WaitlistItem) {
    setEditingNameId(item.id);
    setEditName(item.name || '');
  }

  async function handleSaveName(id: string) {
    try {
      const res = await fetch(`/api/admin/waitlist/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: editName.trim() }),
      });
      if (!res.ok) throw new Error('수정 실패');
      setEditingNameId(null);
      setEditName('');
      load();
    } catch (e) {
      alert('참여자 이름 수정에 실패했습니다.');
    }
  }

  async function handleSendFcm() {
    if (!fcmTitle.trim() || !fcmBody.trim()) {
      alert('제목과 내용을 모두 입력해 주세요.');
      return;
    }
    setFcmSending(true);
    try {
      const res = await fetch('/api/admin/waitlist/send-fcm', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          selectedIds: [...selectedIds],
          title: fcmTitle.trim(),
          body: fcmBody.trim(),
        }),
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || data.detail || '발송 실패');
      }
      const msg = data.message
        || (data.sentCount > 0
          ? `발송 완료: ${data.sentCount}건${data.noTokenCount > 0 ? ` (앱 미설치/비로그인 ${data.noTokenCount}명 제외)` : ''}`
          : '발송할 대상이 없습니다.');
      alert(msg);
      setShowFcmModal(false);
      setFcmTitle('');
      setFcmBody('');
      setSelectedIds(new Set());
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'FCM 발송에 실패했습니다.');
    } finally {
      setFcmSending(false);
    }
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
        <h1 className="text-2xl font-bold text-slate-800">베타 1기 참여 리스트</h1>
        <div className="flex gap-2">
          <input
            type="text"
            placeholder="휴대폰 번호 검색"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="px-4 py-2 border border-slate-300 rounded-lg w-64"
          />
          <button
            onClick={handleCopyPhones}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            휴대폰 번호 복사
          </button>
          <button
            onClick={() => setShowFcmModal(true)}
            disabled={selectedIds.size === 0}
            className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
          >
            FCM 발송 ({selectedIds.size})
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
        총 {filtered.length}명 / {list.length}명 (베타 1기 선착순 100명 한정)
      </p>

      <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-slate-50">
            <tr>
              <th className="w-12 py-3 px-4">
                <input
                  type="checkbox"
                  checked={filtered.length > 0 && allFilteredSelected}
                  onChange={toggleSelectAll}
                  className="rounded border-slate-300"
                />
              </th>
              <th className="w-16 min-w-[4rem] py-3 px-4 text-left text-sm font-medium text-slate-600 whitespace-nowrap">번호</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">휴대폰 번호</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">참여자 이름</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">신청일시</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">앱 설치</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">로그인</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">마지막 FCM 발송</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">마지막 FCM 열람</th>
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
                <td className="w-16 min-w-[4rem] py-3 px-4 text-sm text-slate-600">{filtered.length - idx}</td>
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
                        className="px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700"
                      >
                        저장
                      </button>
                      <button
                        onClick={() => { setEditingId(null); setEditPhone(''); }}
                        className="px-3 py-1.5 text-sm font-medium text-slate-600 bg-slate-100 rounded-lg hover:bg-slate-200"
                      >
                        취소
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      className={`block w-full min-h-[2.25rem] text-left px-3 py-2 rounded border border-dashed border-slate-300 hover:bg-slate-50 hover:border-slate-400 text-sm ${!i.phone ? 'text-amber-600' : 'text-slate-600'}`}
                      onClick={() => startEdit(i)}
                      title={i.phone ? '클릭하여 수정' : '휴대폰 번호 없음 - 클릭하여 추가'}
                    >
                      {i.phone || '클릭하여 입력'}
                    </button>
                  )}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {editingNameId === i.id ? (
                    <div className="flex items-center gap-2">
                      <input
                        type="text"
                        value={editName}
                        onChange={(e) => setEditName(e.target.value)}
                        placeholder="참여자 이름"
                        className="w-28 rounded border border-slate-300 px-2 py-1 text-sm"
                        autoFocus
                      />
                      <button
                        onClick={() => handleSaveName(i.id)}
                        className="px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700"
                      >
                        저장
                      </button>
                      <button
                        onClick={() => { setEditingNameId(null); setEditName(''); }}
                        className="px-3 py-1.5 text-sm font-medium text-slate-600 bg-slate-100 rounded-lg hover:bg-slate-200"
                      >
                        취소
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      className="block w-full min-h-[2.25rem] text-left px-3 py-2 rounded border border-dashed border-slate-300 hover:bg-slate-50 hover:border-slate-400 text-sm text-slate-600"
                      onClick={() => startEditName(i)}
                      title="클릭하여 수정"
                    >
                      {i.name || '클릭하여 입력'}
                    </button>
                  )}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {new Date(i.createdAt).toLocaleString('ko-KR')}
                </td>
                <td className="py-3 px-4 text-sm">
                  {i.appInstalled ? (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-emerald-100 text-emerald-800">설치됨</span>
                  ) : (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-600">미설치</span>
                  )}
                </td>
                <td className="py-3 px-4 text-sm">
                  {i.loggedIn ? (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">로그인</span>
                  ) : (
                    <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-600">미로그인</span>
                  )}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {i.lastFcmSentAt ? new Date(i.lastFcmSentAt).toLocaleString('ko-KR') : '-'}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {i.lastFcmOpenedAt ? new Date(i.lastFcmOpenedAt).toLocaleString('ko-KR') : '-'}
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

      {showFcmModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md mx-4">
            <h2 className="text-lg font-bold text-slate-800 mb-4">FCM 푸시 발송</h2>
            <p className="text-sm text-slate-500 mb-4">
              선택한 {selectedIds.size}명 중 앱을 설치하고 로그인한 사용자에게만 발송됩니다.
            </p>
            <div className="space-y-3 mb-6">
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">제목</label>
                <input
                  type="text"
                  value={fcmTitle}
                  onChange={(e) => setFcmTitle(e.target.value)}
                  placeholder="알림 제목"
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-600 mb-1">내용</label>
                <textarea
                  value={fcmBody}
                  onChange={(e) => setFcmBody(e.target.value)}
                  placeholder="알림 내용"
                  rows={3}
                  className="w-full px-4 py-2 border border-slate-300 rounded-lg resize-none"
                />
              </div>
            </div>
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => { setShowFcmModal(false); setFcmTitle(''); setFcmBody(''); }}
                disabled={fcmSending}
                className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg disabled:opacity-50"
              >
                취소
              </button>
              <button
                onClick={handleSendFcm}
                disabled={fcmSending || !fcmTitle.trim() || !fcmBody.trim()}
                className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {fcmSending ? '발송 중...' : '발송'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
