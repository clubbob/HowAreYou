import Link from 'next/link';
import { AdminStats } from './AdminStats';

export default function AdminDashboardPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-800 mb-6">관리자 대시보드</h1>
      <AdminStats />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <Link
          href="/admin/members"
          className="block p-6 bg-white rounded-xl shadow border border-slate-200 hover:border-blue-300 transition"
        >
          <h2 className="font-semibold text-slate-800">회원관리</h2>
          <p className="text-sm text-slate-500 mt-1">가입 회원 목록 조회</p>
        </Link>
        <Link
          href="/admin/inquiries"
          className="block p-6 bg-white rounded-xl shadow border border-slate-200 hover:border-blue-300 transition"
        >
          <h2 className="font-semibold text-slate-800">1:1 문의</h2>
          <p className="text-sm text-slate-500 mt-1">사용자 문의 확인 및 답변</p>
        </Link>
        <Link
          href="/admin/service-feedback"
          className="block p-6 bg-white rounded-xl shadow border border-slate-200 hover:border-blue-300 transition"
        >
          <h2 className="font-semibold text-slate-800">서비스 개선</h2>
          <p className="text-sm text-slate-500 mt-1">앱 피드백(만족도, 개선 의견) 확인</p>
        </Link>
        <Link
          href="/admin/announcements"
          className="block p-6 bg-white rounded-xl shadow border border-slate-200 hover:border-blue-300 transition"
        >
          <h2 className="font-semibold text-slate-800">공지사항</h2>
          <p className="text-sm text-slate-500 mt-1">공지사항 등록 및 관리</p>
        </Link>
        <Link
          href="/admin/waitlist"
          className="block p-6 bg-white rounded-xl shadow border border-slate-200 hover:border-blue-300 transition"
        >
          <h2 className="font-semibold text-slate-800">베타 1기 대기</h2>
          <p className="text-sm text-slate-500 mt-1">베타 1기 신청 전화번호 목록 조회</p>
        </Link>
      </div>
    </div>
  );
}
