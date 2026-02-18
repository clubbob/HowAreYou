import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const email = searchParams.get('email')?.trim().toLowerCase();

  if (!email || email.length < 3) {
    return NextResponse.json({ error: '이메일을 입력해주세요.' }, { status: 400 });
  }

  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: '서비스를 일시적으로 사용할 수 없습니다.' }, { status: 500 });
  }

  try {
    let snap;
    try {
      snap = await db
        .collection('inquiries')
        .where('role', '==', 'visitor')
        .where('email', '==', email)
        .orderBy('createdAt', 'desc')
        .limit(20)
        .get();
    } catch {
      // 인덱스 미배포 시: role=visitor만 조회 후 이메일로 필터 (기존 문의 호환)
      const allVisitor = await db
        .collection('inquiries')
        .where('role', '==', 'visitor')
        .limit(100)
        .get();
      const filtered = allVisitor.docs.filter((d) => {
        const data = d.data();
        const storedEmail = data.email?.toLowerCase?.();
        const userPhone = (data.userPhone ?? '').toLowerCase();
        return storedEmail === email || userPhone.includes(email);
      });
      filtered.sort((a, b) => {
        const ta = a.data().createdAt?.toDate?.()?.getTime() ?? 0;
        const tb = b.data().createdAt?.toDate?.()?.getTime() ?? 0;
        return tb - ta;
      });
      snap = { docs: filtered.slice(0, 20) };
    }

    const list = snap.docs.map((doc) => {
      const d = doc.data();
      const createdAt = d.createdAt?.toDate?.() ?? new Date();
      return {
        id: doc.id,
        message: d.message ?? '',
        createdAt: createdAt.toISOString(),
        replies: (d.replies ?? []).map((r: { message?: string; createdAt?: { toDate?: () => Date } | Date }) => {
          const dt =
            r.createdAt && typeof r.createdAt === 'object' && 'toDate' in r.createdAt
              ? (r.createdAt as { toDate: () => Date }).toDate()
              : r.createdAt instanceof Date
                ? r.createdAt
                : new Date();
          return { message: r.message ?? '', createdAt: dt.toISOString() };
        }),
      };
    });

    return NextResponse.json(list);
  } catch (e) {
    console.error('[inquiry/check]', e);
    return NextResponse.json({ error: '조회에 실패했습니다.' }, { status: 500 });
  }
}
