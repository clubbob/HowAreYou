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

const INITIAL_COUNT = 5;

export function AnnouncementsSection() {
  const [items, setItems] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showAll, setShowAll] = useState(false);

  useEffect(() => {
    getAnnouncements()
      .then(setItems)
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  }, []);

  if (loading || items.length === 0) return null;

  const displayItems = showAll ? items : items.slice(0, INITIAL_COUNT);
  const hasMore = items.length > INITIAL_COUNT;

  const formatDate = (sec: number) => {
    const d = new Date(sec * 1000);
    return d.toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  return (
    <section id="announcements" className="bg-white px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          공지사항
        </h2>

        <ul className="space-y-5">
          {displayItems.map((a) => {
            const isExpanded = expandedId === a.id;
            return (
              <li
                key={a.id}
                className="rounded-[1rem] border border-navy-100 bg-white shadow-[0_2px_12px_rgba(0,0,0,0.04)] overflow-hidden"
              >
                <button
                  type="button"
                  onClick={() => setExpandedId(isExpanded ? null : a.id)}
                  className="flex w-full flex-col gap-1 p-5 text-left hover:bg-navy-50/50 transition-colors sm:flex-row sm:items-start sm:justify-between sm:gap-4 sm:p-6"
                >
                  <h3 className="text-[15px] font-semibold leading-[1.4] text-navy-900 sm:text-base">
                    {a.pinned && (
                      <span className="mr-2 inline-flex rounded-md bg-primary-50 px-2 py-0.5 text-sm font-medium text-primary-500">
                        중요
                      </span>
                    )}
                    {a.title}
                  </h3>
                  <span className="flex shrink-0 items-center gap-2 text-[14px] text-navy-500 sm:text-[17px]">
                    {a.createdAt && formatDate(a.createdAt.seconds)}
                    <span className={`inline-block transition-transform ${isExpanded ? 'rotate-180' : ''}`}>
                      ▼
                    </span>
                  </span>
                </button>
                {isExpanded && (
                  <div className="border-t border-navy-100 px-5 py-4 sm:px-6 sm:py-5">
                    <p className="whitespace-pre-wrap text-[17px] leading-[1.6] text-navy-700">
                      {a.content}
                    </p>
                  </div>
                )}
              </li>
            );
          })}
        </ul>
        {hasMore && !showAll && (
          <div className="mt-6 text-center">
            <button
              type="button"
              onClick={() => setShowAll(true)}
              className="rounded-xl border border-navy-200 bg-white px-6 py-3 text-[15px] font-medium text-navy-700 transition-colors hover:bg-navy-50"
            >
              더 보기 ({items.length - INITIAL_COUNT}건)
            </button>
          </div>
        )}
      </div>
    </section>
  );
}
