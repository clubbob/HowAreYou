'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';

const menus = [
  { href: '/admin', label: '대시보드' },
  { href: '/admin/members', label: '회원관리' },
  { href: '/admin/inquiries', label: '1:1 문의', badgeKey: 'unansweredInquiriesCount' as const },
  { href: '/admin/service-feedback', label: '서비스 개선', badgeKey: 'serviceFeedbackCount' as const },
  { href: '/admin/announcements', label: '공지사항' },
  { href: '/admin/waitlist', label: '베타 1기 대기' },
];

export default function AdminNav() {
  const pathname = usePathname();

  const [stats, setStats] = useState<{
    unansweredInquiriesCount?: number;
    serviceFeedbackCount?: number;
  }>({});

  useEffect(() => {
    fetch('/api/admin/stats', { credentials: 'include' })
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => data && setStats(data))
      .catch(() => {});
  }, [pathname]);

  async function handleLogout() {
    await fetch('/api/admin/logout', { method: 'POST' });
    window.location.href = '/admin/login';
  }

  return (
    <nav className="bg-white border-b border-slate-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex gap-6">
          {menus.map((m) => (
            <Link
              key={m.href}
              href={m.href}
              className={`font-medium flex items-center gap-1.5 ${
                pathname === m.href || (m.href !== '/admin' && pathname.startsWith(m.href))
                  ? 'text-blue-600'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              {m.label}
              {m.badgeKey === 'unansweredInquiriesCount' && (stats.unansweredInquiriesCount ?? 0) > 0 && (
                <span className="px-1.5 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
                  {stats.unansweredInquiriesCount}
                </span>
              )}
              {m.badgeKey === 'serviceFeedbackCount' && (stats.serviceFeedbackCount ?? 0) > 0 && (
                <span className="px-1.5 py-0.5 text-xs font-medium bg-blue-100 text-blue-700 rounded-full">
                  {stats.serviceFeedbackCount}
                </span>
              )}
            </Link>
          ))}
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm font-medium text-slate-600 hover:text-slate-900"
          >
            홈페이지
          </Link>
          <button
            onClick={handleLogout}
            className="text-sm text-slate-500 hover:text-red-600"
          >
            로그아웃
          </button>
        </div>
      </div>
    </nav>
  );
}
