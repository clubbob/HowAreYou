import { NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';

export async function GET() {
  const ok = await verifyAdminSession();
  return NextResponse.json({ ok });
}
