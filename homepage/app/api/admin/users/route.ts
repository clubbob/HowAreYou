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

  const snap = await db.collection('users').limit(500).get();
  const list = snap.docs.map((doc) => {
    const d = doc.data();
    return {
      id: doc.id,
      phone: d.phone ?? '',
      displayName: d.displayName ?? null,
      role: d.role ?? 'subject',
    };
  });
  return NextResponse.json(list);
}
