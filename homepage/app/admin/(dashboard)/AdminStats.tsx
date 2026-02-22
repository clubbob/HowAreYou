'use client';

import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';

type Stats = {
  usersCount: number;
  inquiriesCount: number;
  unansweredInquiriesCount: number;
  announcementsCount: number;
  waitlistCount: number;
  serviceFeedbackCount: number;
  firebaseConfigured?: boolean;
};

const defaultStats: Stats = {
  usersCount: 0,
  inquiriesCount: 0,
  unansweredInquiriesCount: 0,
  announcementsCount: 0,
  waitlistCount: 0,
  serviceFeedbackCount: 0,
};

export function AdminStats() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const res = await fetch('/api/admin/stats');
      if (!res.ok) throw new Error('조회 실패');
      const data = await res.json();
      setStats(data);
    } catch {
      setStats(defaultStats);
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  if (loading && !stats) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-6 mb-6">
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className="p-4 bg-white rounded-xl border border-slate-200 animate-pulse">
            <div className="h-4 bg-slate-200 rounded w-20 mb-2" />
            <div className="h-8 bg-slate-200 rounded w-12" />
          </div>
        ))}
      </div>
    );
  }

  const displayStats = stats ?? defaultStats;

  const cards = [
    {
      label: '가입 회원',
      value: displayStats.usersCount,
      href: '/admin/members',
    },
    {
      label: '미답변 문의',
      value: displayStats.unansweredInquiriesCount,
      href: '/admin/inquiries',
      highlight: displayStats.unansweredInquiriesCount > 0,
    },
    {
      label: '전체 문의',
      value: displayStats.inquiriesCount,
      href: '/admin/inquiries',
    },
    {
      label: '공지사항',
      value: displayStats.announcementsCount,
      href: '/admin/announcements',
    },
    {
      label: '베타 1기 대기',
      value: displayStats.waitlistCount,
      href: '/admin/waitlist',
    },
    {
      label: '서비스 개선',
      value: displayStats.serviceFeedbackCount,
      href: '/admin/service-feedback',
    },
  ];

  const showFirebaseWarning = displayStats.firebaseConfigured === false;
  const showError = error;

  return (
    <div className="mb-8">
      {showFirebaseWarning && (
        <div className="mb-4 p-4 bg-slate-50 border border-slate-200 rounded-xl">
          <span className="text-slate-600 text-sm">
            Firebase Admin이 연결되지 않았습니다. 통계는 0으로 표시됩니다. 회원/문의/공지 등 데이터 조회를 위해 .env에 FIREBASE_SERVICE_ACCOUNT_JSON을 설정해주세요.
          </span>
        </div>
      )}
      {showError && (
        <div className="mb-4 p-4 bg-amber-50 border border-amber-200 rounded-xl flex items-center justify-between">
          <span className="text-amber-800 text-sm">통계를 불러오지 못했습니다.</span>
          <button
            onClick={load}
            disabled={loading}
            className="px-3 py-1.5 bg-amber-100 text-amber-800 rounded-lg hover:bg-amber-200 text-sm disabled:opacity-50"
          >
            다시 시도
          </button>
        </div>
      )}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-6">
        {cards.map((c) => (
          <Link
            key={c.label}
            href={c.href}
            className={`block p-5 bg-white rounded-xl border shadow-sm transition hover:shadow ${
              c.highlight ? 'border-amber-300' : 'border-slate-200'
            }`}
          >
            <p className="text-sm font-medium text-slate-500">{c.label}</p>
            <p className={`mt-1 text-2xl font-bold ${c.highlight ? 'text-amber-600' : 'text-slate-800'}`}>
              {c.value}
            </p>
          </Link>
        ))}
      </div>
    </div>
  );
}
