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

  const snap = await db.collection('waitlist').limit(500).get();
  const list = snap.docs
    .map((doc) => {
      const d = doc.data();
      const createdAt = d.createdAt?.toDate?.() ?? new Date();
      const lastFcmSentAt = d.lastFcmSentAt?.toDate?.();
      const lastFcmOpenedAt = d.lastFcmOpenedAt?.toDate?.();
      return {
        id: doc.id,
        phone: d.phone ?? '',
        cohort: d.cohort ?? '1',
        createdAt: createdAt.toISOString(),
        lastFcmSentAt: lastFcmSentAt ? lastFcmSentAt.toISOString() : null,
        lastFcmOpenedAt: lastFcmOpenedAt ? lastFcmOpenedAt.toISOString() : null,
      };
    })
    .filter((item) => item.phone)
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  return NextResponse.json(list);
}
