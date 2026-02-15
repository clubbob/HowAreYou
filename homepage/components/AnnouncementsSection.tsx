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
    <section className="relative bg-primary-50/50 px-6 py-20 md:py-28">
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-12 text-center text-2xl font-bold tracking-tight text-primary-900 md:text-3xl">
          공지사항
        </h2>

        <ul className="space-y-4">
          {items.map((a) => (
            <li
              key={a.id}
              className="rounded-2xl border border-primary-100/60 bg-white/90 p-6 shadow-soft backdrop-blur-sm transition-all duration-200 hover:shadow-card"
            >
              <div className="flex items-start justify-between gap-4">
                <h3 className="font-semibold text-primary-900">
                  {a.pinned && (
                    <span className="mr-2 inline-flex rounded-md bg-primary-100 px-2 py-0.5 text-xs font-medium text-primary-700">
                      중요
                    </span>
                  )}
                  {a.title}
                </h3>
                {a.createdAt && (
                  <span className="shrink-0 text-sm text-primary-600/80">
                    {formatDate(a.createdAt.seconds)}
                  </span>
                )}
              </div>
              <p className="mt-3 whitespace-pre-wrap text-sm leading-relaxed text-primary-700/90">
                {a.content}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
