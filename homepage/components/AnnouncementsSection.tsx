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
    <section className="bg-white px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          공지사항
        </h2>

        <ul className="space-y-5">
          {items.map((a) => (
            <li
              key={a.id}
              className="rounded-[1rem] border border-navy-100 bg-white p-5 shadow-[0_2px_12px_rgba(0,0,0,0.04)] sm:p-6"
            >
              <div className="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between sm:gap-4">
                <h3 className="text-[15px] font-semibold leading-[1.4] text-navy-900 sm:text-base">
                  {a.pinned && (
                    <span className="mr-2 inline-flex rounded-md bg-primary-50 px-2 py-0.5 text-sm font-medium text-primary-500">
                      중요
                    </span>
                  )}
                  {a.title}
                </h3>
                {a.createdAt && (
                  <span className="shrink-0 text-[14px] text-navy-500 sm:text-[17px]">
                    {formatDate(a.createdAt.seconds)}
                  </span>
                )}
              </div>
              <p className="mt-3 whitespace-pre-wrap text-[17px] leading-[1.6] text-navy-700">
                {a.content}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
