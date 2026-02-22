import { NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore } from '@/lib/firebase-admin';

const SATISFACTION_LABELS: Record<number, string> = {
  5: '매우 만족',
  4: '만족',
  3: '보통',
  2: '아쉬움',
  1: '많이 불편함',
};

export async function GET() {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  try {
    const snap = await db
      .collection('service_feedback')
      .orderBy('createdAt', 'desc')
      .limit(200)
      .get();

    const list = snap.docs.map((doc) => {
      try {
        const d = doc.data();
        let createdAt: Date;
        try {
          createdAt = d.createdAt?.toDate?.() ?? new Date();
        } catch {
          createdAt = new Date();
        }
        let reviewedAt: Date | null = null;
        try {
          const v = d.reviewedAt?.toDate?.();
          reviewedAt = v ? v : null;
        } catch {
          reviewedAt = null;
        }
        const satisfaction = typeof d.satisfaction === 'number' ? d.satisfaction : 0;
        return {
          id: doc.id,
          userId: d.userId ?? '',
          userPhone: d.userPhone ?? null,
          userDisplayName: d.userDisplayName ?? null,
          source: d.source ?? 'app',
          satisfaction,
          reviewedAt: reviewedAt ? reviewedAt.toISOString() : null,
          satisfactionLabel: SATISFACTION_LABELS[satisfaction] ?? `${satisfaction}점`,
          inconvenience: d.inconvenience ?? null,
          improvementIdea: d.improvementIdea ?? null,
          continueIntent: d.continueIntent ?? null,
          createdAt: createdAt.toISOString(),
        };
      } catch (e) {
        console.error('[admin/service-feedback] 문서 파싱 오류:', doc.id, e);
        return {
          id: doc.id,
          userId: '',
          userPhone: null,
          userDisplayName: null,
          source: 'app',
          satisfaction: 0,
          reviewedAt: null,
          satisfactionLabel: '-',
          inconvenience: null,
          improvementIdea: null,
          continueIntent: null,
          createdAt: new Date().toISOString(),
        };
      }
    });

    return NextResponse.json(list);
  } catch (e) {
    console.error('[admin/service-feedback]', e);
    return NextResponse.json(
      { error: '서비스 개선 피드백 목록 조회에 실패했습니다.' },
      { status: 500 }
    );
  }
}
