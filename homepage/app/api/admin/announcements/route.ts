import { NextRequest, NextResponse } from 'next/server';
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
  const snap = await db.collection('announcements').orderBy('createdAt', 'desc').limit(50).get();
  const list = snap.docs.map((doc) => {
    const d = doc.data();
    const createdAt = d.createdAt?.toDate?.() ?? new Date();
    return {
      id: doc.id,
      title: d.title ?? '',
      content: d.content ?? '',
      pinned: d.pinned ?? false,
      createdAt: createdAt.toISOString(),
    };
  });
  return NextResponse.json(list);
}

export async function POST(request: NextRequest) {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  let body: { title?: string; content?: string; pinned?: boolean };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid body' }, { status: 400 });
  }
  const title = (body.title ?? '').trim();
  const content = (body.content ?? '').trim();
  if (!title || !content) {
    return NextResponse.json({ error: 'title and content required' }, { status: 400 });
  }

  await db.collection('announcements').add({
    title,
    content,
    pinned: body.pinned ?? false,
    createdAt: new Date(),
  });
  return NextResponse.json({ ok: true });
}
