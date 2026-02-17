'use client';

import { useEffect, useState } from 'react';

type User = { id: string; phone: string; displayName: string | null; role: string };

export default function AdminMembersPage() {
  const [list, setList] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetch('/api/admin/users')
      .then((res) => {
        if (!res.ok) throw new Error('조회 실패');
        return res.json();
      })
      .then(setList)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="text-slate-500">로딩 중...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-800 mb-6">회원관리</h1>
      <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-slate-50">
            <tr>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">전화번호</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">이름</th>
              <th className="text-left py-3 px-4 text-sm font-medium text-slate-600">역할</th>
            </tr>
          </thead>
          <tbody>
            {list.map((u) => (
              <tr key={u.id} className="border-t border-slate-100">
                <td className="py-3 px-4">{u.phone}</td>
                <td className="py-3 px-4">{u.displayName ?? '-'}</td>
                <td className="py-3 px-4">
                  <span className="text-sm">{u.role === 'guardian' ? '보호자' : u.role === 'subject' ? '보호대상자' : '둘 다'}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.length === 0 && (
          <div className="py-12 text-center text-slate-500">등록된 회원이 없습니다.</div>
        )}
      </div>
    </div>
  );
}
