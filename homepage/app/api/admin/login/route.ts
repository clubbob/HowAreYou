import { NextRequest, NextResponse } from 'next/server';
import { createAdminSession, getAdminSessionCookie } from '@/lib/admin-auth';

export async function POST(request: NextRequest) {
  const username = process.env.ADMIN_USERNAME;
  const password = process.env.ADMIN_PASSWORD;
  if (!username || !password) {
    return NextResponse.json({ error: '관리자 설정이 없습니다.' }, { status: 500 });
  }

  let body: { username?: string; password?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: '잘못된 요청입니다.' }, { status: 400 });
  }

  const { username: u, password: p } = body;
  if (u !== username || p !== password) {
    return NextResponse.json({ error: '아이디 또는 비밀번호가 올바르지 않습니다.' }, { status: 401 });
  }

  const token = createAdminSession(username, password);
  const res = NextResponse.json({ ok: true });
  res.headers.set('Set-Cookie', getAdminSessionCookie('admin_session', token));
  return res;
}
