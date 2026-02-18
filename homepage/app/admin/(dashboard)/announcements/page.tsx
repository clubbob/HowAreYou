'use client';

import { useEffect, useMemo, useState } from 'react';

type Announcement = {
  id: string;
  title: string;
  content: string;
  pinned: boolean;
  createdAt: string;
  updatedAt: string | null;
};

export default function AdminAnnouncementsPage() {
  const [list, setList] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [pinned, setPinned] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [previewAnnouncement, setPreviewAnnouncement] = useState<Announcement | null>(null);
  const [sortBy, setSortBy] = useState<'date' | 'updated'>('date');

  function load() {
    setLoading(true);
    fetch('/api/admin/announcements')
      .then((res) => {
        if (!res.ok) throw new Error('조회 실패');
        return res.json();
      })
      .then((data: Announcement[]) => setList(data))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  const sortedList = useMemo(() => {
    return [...list].sort((a, b) => {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      const dateA =
        sortBy === 'updated' && a.updatedAt
          ? new Date(a.updatedAt).getTime()
          : new Date(a.createdAt).getTime();
      const dateB =
        sortBy === 'updated' && b.updatedAt
          ? new Date(b.updatedAt).getTime()
          : new Date(b.createdAt).getTime();
      return dateB - dateA;
    });
  }, [list, sortBy]);

  function openCreateForm() {
    setEditingId(null);
    setTitle('');
    setContent('');
    setPinned(false);
    setShowForm(true);
  }

  function openEditForm(a: Announcement) {
    setEditingId(a.id);
    setTitle(a.title);
    setContent(a.content);
    setPinned(a.pinned);
    setShowForm(true);
  }

  function closeForm() {
    setShowForm(false);
    setEditingId(null);
    setTitle('');
    setContent('');
    setPinned(false);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;
    setSubmitting(true);
    try {
      if (editingId) {
        const res = await fetch(`/api/admin/announcements/${editingId}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ title: title.trim(), content: content.trim(), pinned }),
        });
        if (!res.ok) throw new Error('수정 실패');
      } else {
        const res = await fetch('/api/admin/announcements', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ title: title.trim(), content: content.trim(), pinned }),
        });
        if (!res.ok) throw new Error('등록 실패');
      }
      closeForm();
      load();
    } catch (e) {
      alert((e as Error).message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('이 공지사항을 삭제하시겠습니까?')) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/admin/announcements/${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('삭제 실패');
      if (editingId === id) closeForm();
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
      <div className="flex items-center justify-between mb-6 flex-wrap gap-4">
        <h1 className="text-2xl font-bold text-slate-800">공지사항</h1>
        <div className="flex items-center gap-2">
          <span className="text-sm text-slate-500">정렬:</span>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as 'date' | 'updated')}
            className="px-3 py-2 border border-slate-300 rounded-lg text-sm"
          >
            <option value="date">등록일 순</option>
            <option value="updated">수정일 순</option>
          </select>
        </div>
        <button
          onClick={() => (showForm ? closeForm() : openCreateForm())}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          {showForm ? '취소' : '공지 등록'}
        </button>
      </div>
      {showForm && (
        <form onSubmit={handleSubmit} className="mb-8 p-6 bg-white rounded-xl shadow border border-slate-200">
          <h2 className="font-semibold text-slate-800 mb-4">{editingId ? '공지 수정' : '공지 등록'}</h2>
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-600 mb-1">제목</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg"
              required
            />
          </div>
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-600 mb-1">내용</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className="w-full px-4 py-2 border border-slate-300 rounded-lg min-h-[120px]"
              required
            />
            <p className="mt-1 text-xs text-slate-500">글자 수: {content.length}자</p>
          </div>
          <div className="mb-4 flex items-center gap-2">
            <input
              type="checkbox"
              id="pinned"
              checked={pinned}
              onChange={(e) => setPinned(e.target.checked)}
              className="rounded"
            />
            <label htmlFor="pinned" className="text-sm text-slate-600">
              상단 고정
            </label>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() =>
                setPreviewAnnouncement({
                  id: '',
                  title: title.trim(),
                  content: content.trim(),
                  pinned,
                  createdAt: new Date().toISOString(),
                  updatedAt: null,
                })
              }
              disabled={!title.trim() || !content.trim()}
              className="px-4 py-2 bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50"
            >
              미리보기
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {submitting ? '처리 중...' : editingId ? '수정' : '등록'}
            </button>
            {editingId && (
              <button
                type="button"
                onClick={closeForm}
                className="px-4 py-2 bg-slate-200 text-slate-700 rounded-lg hover:bg-slate-300"
              >
                취소
              </button>
            )}
          </div>
        </form>
      )}
      <div className="space-y-4">
        {sortedList.map((a) => (
          <div key={a.id} className="p-6 bg-white rounded-xl shadow border border-slate-200">
            <div className="flex items-start justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h2 className="font-semibold text-slate-800">{a.title}</h2>
                  <button
                    type="button"
                    onClick={() => setPreviewAnnouncement(a)}
                    className="text-sm text-slate-500 hover:text-blue-600"
                  >
                    미리보기
                  </button>
                </div>
                <p className="text-sm text-slate-500 mt-1">
                  등록 {new Date(a.createdAt).toLocaleString('ko-KR')}
                  {a.updatedAt && (
                    <span className="ml-2">· 수정 {new Date(a.updatedAt).toLocaleString('ko-KR')}</span>
                  )}
                  {a.pinned && (
                    <span className="ml-2 inline-flex px-2 py-0.5 rounded bg-amber-100 text-amber-700 text-xs">
                      상단고정
                    </span>
                  )}
                </p>
                <p className="mt-3 text-slate-700 whitespace-pre-wrap">{a.content}</p>
              </div>
              <div className="flex shrink-0 gap-2">
                <button
                  onClick={() => openEditForm(a)}
                  disabled={submitting}
                  className="px-3 py-1.5 text-sm bg-slate-100 text-slate-700 rounded-lg hover:bg-slate-200 disabled:opacity-50"
                >
                  수정
                </button>
                <button
                  onClick={() => handleDelete(a.id)}
                  disabled={submitting}
                  className="px-3 py-1.5 text-sm bg-red-50 text-red-600 rounded-lg hover:bg-red-100 disabled:opacity-50"
                >
                  삭제
                </button>
              </div>
            </div>
          </div>
        ))}
        {sortedList.length === 0 && !showForm && (
          <div className="py-12 text-center text-slate-500">등록된 공지가 없습니다.</div>
        )}
      </div>

      {previewAnnouncement && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setPreviewAnnouncement(null)}
        >
          <div
            className="bg-white rounded-xl shadow-xl max-w-lg w-full max-h-[80vh] overflow-auto p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text-slate-800">미리보기</h3>
              <button
                onClick={() => setPreviewAnnouncement(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                ✕
              </button>
            </div>
            <h2 className="font-semibold text-slate-800 text-lg">{previewAnnouncement.title}</h2>
            <p className="text-sm text-slate-500 mt-1">
              {new Date(previewAnnouncement.createdAt).toLocaleString('ko-KR')}
              {previewAnnouncement.pinned && (
                <span className="ml-2 inline-flex px-2 py-0.5 rounded bg-amber-100 text-amber-700 text-xs">
                  상단고정
                </span>
              )}
            </p>
            <p className="mt-4 text-slate-700 whitespace-pre-wrap">{previewAnnouncement.content}</p>
          </div>
        </div>
      )}
    </div>
  );
}
