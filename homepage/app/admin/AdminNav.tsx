'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const menus = [
  { href: '/admin', label: '대시보드' },
  { href: '/admin/members', label: '회원관리' },
  { href: '/admin/inquiries', label: '1:1 문의' },
  { href: '/admin/announcements', label: '공지사항' },
];

export default function AdminNav() {
  const pathname = usePathname();

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
              className={`font-medium ${
                pathname === m.href ? 'text-blue-600' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              {m.label}
            </Link>
          ))}
        </div>
        <button
          onClick={handleLogout}
          className="text-sm text-slate-500 hover:text-red-600"
        >
          로그아웃
        </button>
      </div>
    </nav>
  );
}
