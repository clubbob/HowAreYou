import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const LOGIN_PATH = '/admin/login';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // /admin/login은 항상 허용 (쿠키 유무와 무관).
  // 쿠키가 있어도 redirect하지 않음: 만료/잘못된 쿠키 시 layout에서 검증 후 /admin 접근 시에만 /admin/login으로 보냄.
  if (pathname === LOGIN_PATH) {
    return NextResponse.next();
  }

  // 그 외 /admin 경로는 세션 필수
  if (pathname.startsWith('/admin')) {
    const session = request.cookies.get('admin_session')?.value;
    if (!session) {
      return NextResponse.redirect(new URL(LOGIN_PATH, request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/admin', '/admin/:path*'],
};
