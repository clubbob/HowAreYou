'use client';

import { useEffect, useState } from 'react';
import { getAnnouncements } from '@/lib/announcements';

type Announcement = {
  id: string;
  title: string;
  content: string;
  createdAt: { seconds: number } | null;
  pinned?: boolean;
};

export function AnnouncementsSection() {
  const [items, setItems] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAnnouncements()
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  if (loading || items.length === 0) return null;

  const formatDate = (sec: number) => {
    const d = new Date(sec * 1000);
    return d.toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  return (
    <section className="bg-primary-50 px-6 py-16 md:py-20">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-8 text-center text-xl font-bold text-gray-900 md:text-2xl">
          공지사항
        </h2>
        <ul className="space-y-3">
          {items.map((a) => (
            <li
              key={a.id}
              className="rounded-xl bg-white p-4 shadow-sm"
            >
              <div className="flex items-start justify-between gap-2">
                <h3 className="font-semibold text-gray-900">
                  {a.pinned && <span className="mr-1 text-primary-500">[중요]</span>}
                  {a.title}
                </h3>
                {a.createdAt && (
                  <span className="shrink-0 text-xs text-gray-500">
                    {formatDate(a.createdAt.seconds)}
                  </span>
                )}
              </div>
              <p className="mt-2 whitespace-pre-wrap text-sm text-gray-600">{a.content}</p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
