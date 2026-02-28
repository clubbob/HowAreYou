'use client';

import { useEffect, useState, useMemo } from 'react';

type User = {
  id: string;
  phone: string;
  displayName: string | null;
  name: string | null;
  email: string | null;
  role: string;
  createdAt: string | null;
  lastFcmSentAt: string | null;
  lastFcmOpenedAt: string | null;
  guardianPhones: string[];
  wardPhones: string[];
};

type SortKey = 'createdAt-desc' | 'createdAt-asc' | 'name-asc' | 'name-desc';

export default function AdminMembersPage() {
  const [list, setList] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [sortKey, setSortKey] = useState<SortKey>('createdAt-desc');
  const [page, setPage] = useState(1);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [showFcmModal, setShowFcmModal] = useState(false);
  const [fcmTitle, setFcmTitle] = useState('');
  const [fcmBody, setFcmBody] = useState('');
  const [fcmSending, setFcmSending] = useState(false);

  function load() {
    setLoading(true);
    setError('');
    const ctrl = new AbortController();
    const timeout = setTimeout(() => ctrl.abort(), 30000);
    fetch('/api/admin/users', { signal: ctrl.signal })
      .then((res) => {
        if (!res.ok) throw new Error('조회 실패');
        return res.json();
      })
      .then(setList)
      .catch((e) => setError(e.name === 'AbortError' ? '요청 시간이 초과되었습니다. 새로고침해 주세요.' : e.message))
      .finally(() => {
        clearTimeout(timeout);
        setLoading(false);
      });
  }

  useEffect(() => {
    setPage(1);
  }, [search, roleFilter]);

  useEffect(() => {
    load();
  }, []);

  const filtered = useMemo(() => {
    let result = list.filter((u) => {
      const matchSearch =
        !search.trim() ||
        u.phone.includes(search.trim()) ||
        (u.displayName ?? '').toLowerCase().includes(search.trim().toLowerCase()) ||
        (u.name ?? '').toLowerCase().includes(search.trim().toLowerCase()) ||
        (u.email ?? '').toLowerCase().includes(search.trim().toLowerCase());
      const matchRole = !roleFilter || u.role === roleFilter;
      return matchSearch && matchRole;
    });
    result = [...result].sort((a, b) => {
      if (sortKey === 'createdAt-desc') {
        const ta = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const tb = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return tb - ta;
      }
      if (sortKey === 'createdAt-asc') {
        const ta = a.createdAt ? new Date(a.createdAt).getTime() : 0;
        const tb = b.createdAt ? new Date(b.createdAt).getTime() : 0;
        return ta - tb;
      }
      const na = (a.name ?? a.displayName ?? a.phone ?? '').toLowerCase();
      const nb = (b.name ?? b.displayName ?? b.phone ?? '').toLowerCase();
      if (sortKey === 'name-asc') return na.localeCompare(nb);
      return nb.localeCompare(na);
    });
    return result;
  }, [list, search, roleFilter, sortKey]);

  const roleSummary = useMemo(() => {
    const s = { subject: 0, guardian: 0, both: 0 };
    list.forEach((u) => {
      if (u.role === 'subject') s.subject++;
      else if (u.role === 'guardian') s.guardian++;
      else s.both++;
    });
    return s;
  }, [list]);

  const allFilteredSelected = filtered.length > 0 && filtered.every((u) => selectedIds.has(u.id));
  function toggleSelectAll() {
    if (allFilteredSelected) {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        filtered.forEach((u) => next.delete(u.id));
        return next;
      });
    } else {
      setSelectedIds((prev) => {
        const next = new Set(prev);
        filtered.forEach((u) => next.add(u.id));
        return next;
      });
    }
  }
  function toggleSelect(id: string, e: React.MouseEvent) {
    e.stopPropagation();
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }
  async function handleSendFcm() {
    if (!fcmTitle.trim() || !fcmBody.trim()) {
      alert('제목과 내용을 모두 입력해 주세요.');
      return;
    }
    setFcmSending(true);
    try {
      const res = await fetch('/api/admin/users/send-fcm', {
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
          ? `발송 완료: ${data.sentCount}건${data.noTokenCount > 0 ? ` (FCM 토큰 없음 ${data.noTokenCount}명 제외)` : ''}`
          : '발송할 대상이 없습니다.');
      alert(msg);
      setShowFcmModal(false);
      setFcmTitle('');
      setFcmBody('');
      setSelectedIds(new Set());
    } catch (e) {
      alert(e instanceof Error ? e.message : 'FCM 발송에 실패했습니다.');
    } finally {
      setFcmSending(false);
    }
  }

  const PAGE_SIZE = 20;
  const paginated = useMemo(() => {
    const start = (page - 1) * PAGE_SIZE;
    return filtered.slice(start, start + PAGE_SIZE);
  }, [filtered, page]);
  const totalPages = Math.ceil(filtered.length / PAGE_SIZE) || 1;

  if (loading) return <div className="text-slate-500">로딩 중...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-800 mb-6">회원관리</h1>

      <div className="mb-4 p-4 bg-slate-50 rounded-xl flex flex-wrap gap-6 text-sm">
        <span className="text-slate-600">
          <strong className="text-slate-800">보호대상자</strong> {roleSummary.subject}명
        </span>
        <span className="text-slate-600">
          <strong className="text-slate-800">보호자</strong> {roleSummary.guardian}명
        </span>
        <span className="text-slate-600">
          <strong className="text-slate-800">둘 다</strong> {roleSummary.both}명
        </span>
      </div>

      <div className="mb-6 flex flex-wrap gap-4 items-center">
        <input
          type="text"
          placeholder="전화번호, 이름, 이메일 검색"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-4 py-2 border border-slate-300 rounded-lg w-64"
        />
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="px-4 py-2 border border-slate-300 rounded-lg"
        >
          <option value="">전체 역할</option>
          <option value="subject">보호대상자</option>
          <option value="guardian">보호자</option>
          <option value="both">둘 다</option>
        </select>
        <select
          value={sortKey}
          onChange={(e) => setSortKey(e.target.value as SortKey)}
          className="px-4 py-2 border border-slate-300 rounded-lg"
        >
          <option value="createdAt-desc">가입일 최신순</option>
          <option value="createdAt-asc">가입일 오래된순</option>
          <option value="name-asc">이름 가나다순</option>
          <option value="name-desc">이름 가나다 역순</option>
        </select>
        <span className="py-2 text-sm text-slate-500">
          총 {filtered.length}명 / {list.length}명
        </span>
        <button
          onClick={() => setShowFcmModal(true)}
          disabled={selectedIds.size === 0}
          className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
        >
          FCM 발송 ({selectedIds.size})
        </button>
        <button
          onClick={load}
          disabled={loading}
          className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 text-sm"
        >
          새로고침
        </button>
      </div>

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
              <th className="w-16 min-w-[4rem] text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">번호</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">이름</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">전화번호</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">이메일</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">가입일시</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">역할</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">연결된 보호자</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">연결된 보호대상자</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">마지막 FCM 발송</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600 whitespace-nowrap">마지막 FCM 열람</th>
            </tr>
          </thead>
          <tbody>
            {paginated.map((u, idx) => (
              <tr
                key={u.id}
                onClick={() => setSelectedUser(u)}
                className="border-t border-slate-100 hover:bg-slate-50 cursor-pointer"
              >
                <td className="w-12 py-3 px-4" onClick={(e) => e.stopPropagation()}>
                  <input
                    type="checkbox"
                    checked={selectedIds.has(u.id)}
                    onChange={() => {}}
                    onClick={(e) => toggleSelect(u.id, e)}
                    className="rounded border-slate-300"
                  />
                </td>
                <td className="w-16 min-w-[4rem] py-3 px-4 text-sm text-slate-600">{filtered.length - (page - 1) * PAGE_SIZE - idx}</td>
                <td className="py-3 px-4 text-sm">{u.name ?? u.displayName ?? '-'}</td>
                <td className="py-3 px-4 font-mono text-sm">{u.phone || '-'}</td>
                <td className="py-3 px-4 text-sm text-slate-600">{u.email ?? '-'}</td>
                <td className="py-3 px-4 text-sm text-slate-600">
                  {u.createdAt ? new Date(u.createdAt).toLocaleString('ko-KR') : '-'}
                </td>
                <td className="py-3 px-4">
                  <span
                    className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${
                      u.role === 'guardian'
                        ? 'bg-blue-100 text-blue-700'
                        : u.role === 'subject'
                          ? 'bg-green-100 text-green-700'
                          : 'bg-slate-100 text-slate-700'
                    }`}
                  >
                    {u.role === 'guardian' ? '보호자' : u.role === 'subject' ? '보호대상자' : '둘 다'}
                  </span>
                </td>
                <td className="py-3 px-4 text-sm text-slate-600 font-mono">
                  {(u.guardianPhones ?? []).length > 0
                    ? (u.guardianPhones ?? []).join(', ')
                    : '-'}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600 font-mono">
                  {(u.wardPhones ?? []).length > 0
                    ? (u.wardPhones ?? []).join(', ')
                    : '-'}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600 whitespace-nowrap">
                  {u.lastFcmSentAt ? new Date(u.lastFcmSentAt).toLocaleString('ko-KR') : '-'}
                </td>
                <td className="py-3 px-4 text-sm text-slate-600 whitespace-nowrap">
                  {u.lastFcmOpenedAt ? new Date(u.lastFcmOpenedAt).toLocaleString('ko-KR') : '-'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="py-12 text-center text-slate-500">
            {list.length === 0 ? '등록된 회원이 없습니다.' : '검색 결과가 없습니다.'}
          </div>
        )}
      </div>

      {totalPages > 1 && (
        <div className="mt-6 flex items-center justify-center gap-2">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page <= 1}
            className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            이전
          </button>
          <span className="px-4 py-2 text-sm text-slate-600">
            {page} / {totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page >= totalPages}
            className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            다음
          </button>
        </div>
      )}

      {selectedUser && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedUser(null)}
        >
          <div
            className="bg-white rounded-xl shadow-xl max-w-md w-full p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-slate-800">회원 상세</h3>
              <button
                onClick={() => setSelectedUser(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>
            <dl className="space-y-3">
              <div>
                <dt className="text-sm text-slate-500">이름</dt>
                <dd>{selectedUser.name ?? selectedUser.displayName ?? '-'}</dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">전화번호</dt>
                <dd className="font-mono">{selectedUser.phone || '-'}</dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">이메일</dt>
                <dd className="text-sm">{selectedUser.email ?? '-'}</dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">역할</dt>
                <dd>
                  <span
                    className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${
                      selectedUser.role === 'guardian'
                        ? 'bg-blue-100 text-blue-700'
                        : selectedUser.role === 'subject'
                          ? 'bg-green-100 text-green-700'
                          : 'bg-slate-100 text-slate-700'
                    }`}
                  >
                    {selectedUser.role === 'guardian' ? '보호자' : selectedUser.role === 'subject' ? '보호대상자' : '둘 다'}
                  </span>
                </dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">연결된 보호자</dt>
                <dd className="text-sm font-mono">
                  {(selectedUser.guardianPhones ?? []).length > 0
                    ? (selectedUser.guardianPhones ?? []).join(', ')
                    : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">연결된 보호대상자</dt>
                <dd className="text-sm font-mono">
                  {(selectedUser.wardPhones ?? []).length > 0
                    ? (selectedUser.wardPhones ?? []).join(', ')
                    : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">가입일</dt>
                <dd className="text-sm">
                  {selectedUser.createdAt ? new Date(selectedUser.createdAt).toLocaleString('ko-KR') : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">마지막 FCM 발송</dt>
                <dd className="text-sm">
                  {selectedUser.lastFcmSentAt ? new Date(selectedUser.lastFcmSentAt).toLocaleString('ko-KR') : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">마지막 FCM 열람</dt>
                <dd className="text-sm">
                  {selectedUser.lastFcmOpenedAt ? new Date(selectedUser.lastFcmOpenedAt).toLocaleString('ko-KR') : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-sm text-slate-500">회원 ID</dt>
                <dd className="font-mono text-xs text-slate-600 break-all">{selectedUser.id}</dd>
              </div>
            </dl>
          </div>
        </div>
      )}

      {showFcmModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-md mx-4">
            <h2 className="text-lg font-bold text-slate-800 mb-4">FCM 푸시 발송</h2>
            <p className="text-sm text-slate-500 mb-4">
              선택한 {selectedIds.size}명 중 FCM 토큰이 등록된 회원에게만 발송됩니다.
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
