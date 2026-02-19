import { NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore } from '@/lib/firebase-admin';

export async function GET() {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  try {
    const snap = await db.collection('inquiries').orderBy('createdAt', 'desc').limit(200).get();
    const list = snap.docs.map((doc) => {
      try {
        const d = doc.data();
        let createdAt: Date;
        try {
          createdAt = d.createdAt?.toDate?.() ?? new Date();
        } catch {
          createdAt = new Date();
        }
        let deletedByUserAt: Date | null = null;
        try {
          const v = d.deletedByUserAt?.toDate?.();
          deletedByUserAt = v ? v : null;
        } catch {
          deletedByUserAt = null;
        }
        const replies = (d.replies ?? []).map((r: { message?: string; createdAt?: { toDate?: () => Date } | Date }) => {
          let dt: Date;
          try {
            dt = r.createdAt && typeof r.createdAt === 'object' && 'toDate' in r.createdAt
              ? (r.createdAt as { toDate: () => Date }).toDate()
              : r.createdAt instanceof Date ? r.createdAt : new Date();
          } catch {
            dt = new Date();
          }
          return { message: r.message ?? '', createdAt: dt.toISOString() };
        });
        return {
          id: doc.id,
          userId: d.userId ?? '',
          userPhone: d.userPhone ?? '',
          userDisplayName: d.userDisplayName ?? null,
          role: d.role ?? 'subject',
          inquiryCode: d.inquiryCode ?? null,
          message: d.message ?? '',
          createdAt: createdAt.toISOString(),
          deletedByUserAt: deletedByUserAt ? deletedByUserAt.toISOString() : null,
          replies,
        };
      } catch (e) {
        console.error('[admin/inquiries] 문서 파싱 오류:', doc.id, e);
        return {
          id: doc.id,
          userId: '',
          userPhone: '',
          userDisplayName: null,
          role: 'visitor',
          inquiryCode: null,
          message: '(파싱 오류)',
          createdAt: new Date().toISOString(),
          deletedByUserAt: null,
          replies: [],
        };
      }
    });
    return NextResponse.json(list);
  } catch (e) {
    console.error('[admin/inquiries]', e);
    return NextResponse.json({ error: '문의 목록 조회에 실패했습니다.' }, { status: 500 });
  }
}
