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

  const snap = await db.collection('inquiries').orderBy('createdAt', 'desc').limit(200).get();
  const list = snap.docs.map((doc) => {
    const d = doc.data();
    const createdAt = d.createdAt?.toDate?.() ?? new Date();
    return {
      id: doc.id,
      userId: d.userId ?? '',
      userPhone: d.userPhone ?? '',
      userDisplayName: d.userDisplayName ?? null,
      role: d.role ?? 'subject',
      message: d.message ?? '',
      createdAt: createdAt.toISOString(),
      replies: (d.replies ?? []).map((r: { message?: string; createdAt?: { toDate?: () => Date } }) => ({
        message: r.message ?? '',
        createdAt: r.createdAt?.toDate?.() ?? new Date(),
      })),
    };
  });
  return NextResponse.json(list);
}
