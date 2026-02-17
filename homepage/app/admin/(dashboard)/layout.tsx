import { redirect } from 'next/navigation';
import { verifyAdminSession } from '@/lib/admin-auth';
import AdminNav from '../AdminNav';

export default async function AdminDashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const isAuth = await verifyAdminSession();
  if (!isAuth) {
    redirect('/admin/login');
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <AdminNav />
      <main className="p-6">{children}</main>
    </div>
  );
}
