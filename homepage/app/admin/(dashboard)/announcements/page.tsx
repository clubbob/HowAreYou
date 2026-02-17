'use client';

import { useEffect, useState } from 'react';

type Announcement = {
  id: string;
  title: string;
  content: string;
  pinned: boolean;
  createdAt: string;
};

export default function AdminAnnouncementsPage() {
  const [list, setList] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [submitting, setSubmitting] = useState(false);

  function load() {
    fetch('/api/admin/announcements')
      .then((res) => {
        if (!res.ok) throw new Error('조회 실패');
        return res.json();
      })
      .then(setList)
      .catch((e) => setError(e.message));
  }

  useEffect(() => {
    load();
    setLoading(false);
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;
    setSubmitting(true);
    try {
      const res = await fetch('/api/admin/announcements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: title.trim(), content: content.trim() }),
      });
      if (!res.ok) throw new Error('등록 실패');
      setTitle('');
      setContent('');
      setShowForm(false);
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
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-800">공지사항</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          {showForm ? '취소' : '공지 등록'}
        </button>
      </div>
      {showForm && (
        <form onSubmit={handleSubmit} className="mb-8 p-6 bg-white rounded-xl shadow border border-slate-200">
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
          </div>
          <button
            type="submit"
            disabled={submitting}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {submitting ? '등록 중...' : '등록'}
          </button>
        </form>
      )}
      <div className="space-y-4">
        {list.map((a) => (
          <div key={a.id} className="p-6 bg-white rounded-xl shadow border border-slate-200">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h2 className="font-semibold text-slate-800">{a.title}</h2>
                <p className="text-sm text-slate-500 mt-1">
                  {new Date(a.createdAt).toLocaleString('ko-KR')}
                  {a.pinned && ' · 상단고정'}
                </p>
                <p className="mt-3 text-slate-700 whitespace-pre-wrap">{a.content}</p>
              </div>
            </div>
          </div>
        ))}
        {list.length === 0 && !showForm && (
          <div className="py-12 text-center text-slate-500">등록된 공지가 없습니다.</div>
        )}
      </div>
    </div>
  );
}
