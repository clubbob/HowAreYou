'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';

const menus = [
  { href: '/admin', label: '대시보드' },
  { href: '/admin/members', label: '회원관리' },
  { href: '/admin/inquiries', label: '1:1 문의', badgeKey: 'unansweredInquiriesCount' as const },
  { href: '/admin/announcements', label: '공지사항' },
  { href: '/admin/waitlist', label: '베타 대기' },
];

export default function AdminNav() {
  const pathname = usePathname();
  const [unansweredCount, setUnansweredCount] = useState(0);

  useEffect(() => {
    fetch('/api/admin/stats')
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => data && setUnansweredCount(data.unansweredInquiriesCount ?? 0))
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
              {m.badgeKey === 'unansweredInquiriesCount' && unansweredCount > 0 && (
                <span className="px-1.5 py-0.5 text-xs font-medium bg-amber-100 text-amber-700 rounded-full">
                  {unansweredCount}
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
