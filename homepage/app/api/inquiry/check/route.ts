import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { verifyPassword } from '@/lib/inquiry-utils';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code')?.trim().toUpperCase();
  const password = searchParams.get('password') ?? '';

  if (!code || code.length !== 6) {
    return NextResponse.json({ error: '문의 번호를 입력해주세요.' }, { status: 400 });
  }

  if (!password) {
    return NextResponse.json({ error: '비밀번호를 입력해주세요.' }, { status: 400 });
  }

  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: '서비스를 일시적으로 사용할 수 없습니다.' }, { status: 500 });
  }

  try {
    const snap = await db
      .collection('inquiries')
      .where('role', '==', 'visitor')
      .where('inquiryCode', '==', code)
      .limit(1)
      .get();

    if (snap.empty) {
      return NextResponse.json({ error: '문의를 찾을 수 없습니다.' }, { status: 404 });
    }

    const doc = snap.docs[0];
    const d = doc.data();
    const passwordHash = d.passwordHash;

    if (d.deletedByUserAt) {
      return NextResponse.json({ error: '문의를 찾을 수 없습니다.' }, { status: 404 });
    }

    if (!passwordHash || !verifyPassword(password, passwordHash)) {
      return NextResponse.json({ error: '비밀번호가 일치하지 않습니다.' }, { status: 401 });
    }

    const createdAt = d.createdAt?.toDate?.() ?? new Date();
    const item = {
      id: doc.id,
      inquiryCode: code,
      message: d.message ?? '',
      createdAt: createdAt.toISOString(),
      replies: (d.replies ?? []).map(
        (r: { message?: string; createdAt?: { toDate?: () => Date } | Date }) => {
          const dt =
            r.createdAt && typeof r.createdAt === 'object' && 'toDate' in r.createdAt
              ? (r.createdAt as { toDate: () => Date }).toDate()
              : r.createdAt instanceof Date
                ? r.createdAt
                : new Date();
          return { message: r.message ?? '', createdAt: dt.toISOString() };
        }
      ),
    };

    return NextResponse.json(item);
  } catch (e) {
    console.error('[inquiry/check]', e);
    return NextResponse.json({ error: '조회에 실패했습니다.' }, { status: 500 });
  }
}
