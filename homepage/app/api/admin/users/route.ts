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

  const [usersSnap, subjectsSnap] = await Promise.all([
    db.collection('users').limit(500).get(),
    db.collection('subjects').get(),
  ]);

  const guardianUids = new Set<string>();
  const subjectUids = new Set<string>();
  subjectsSnap.docs.forEach((doc) => {
    subjectUids.add(doc.id);
    const paired = (doc.data()?.pairedGuardianUids as string[]) ?? [];
    paired.forEach((uid: string) => guardianUids.add(uid));
  });

  const list = usersSnap.docs.map((doc) => {
    const d = doc.data();
    const uid = doc.id;
    const isSubject = subjectUids.has(uid);
    const isGuardian = guardianUids.has(uid);
    let role = 'subject';
    if (isSubject && isGuardian) role = 'both';
    else if (isGuardian) role = 'guardian';
    else if (isSubject) role = 'subject';

    const createdAt = d.createdAt?.toDate?.();
    return {
      id: uid,
      phone: d.phone ?? '',
      displayName: d.displayName ?? null,
      role,
      createdAt: createdAt ? createdAt.toISOString() : null,
    };
  });
  return NextResponse.json(list);
}
