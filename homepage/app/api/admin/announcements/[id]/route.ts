import { NextRequest, NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore } from '@/lib/firebase-admin';

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  const { id } = await params;
  if (!id) {
    return NextResponse.json({ error: 'id required' }, { status: 400 });
  }

  let body: { title?: string; content?: string; pinned?: boolean };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid body' }, { status: 400 });
  }

  const ref = db.collection('announcements').doc(id);
  const doc = await ref.get();
  if (!doc.exists) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  const now = new Date();
  const updates: Record<string, unknown> = {
    updatedAt: now,
    createdAt: now, // 수정 시 표시 날짜 갱신 (홈페이지·정렬 반영)
  };
  if (typeof body.title === 'string' && body.title.trim()) updates.title = body.title.trim();
  if (typeof body.content === 'string') updates.content = body.content.trim();
  if (typeof body.pinned === 'boolean') updates.pinned = body.pinned;

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: 'No updates' }, { status: 400 });
  }

  await ref.update(updates);
  return NextResponse.json({ ok: true });
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  const { id } = await params;
  if (!id) {
    return NextResponse.json({ error: 'id required' }, { status: 400 });
  }

  const ref = db.collection('announcements').doc(id);
  const doc = await ref.get();
  if (!doc.exists) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  await ref.delete();
  return NextResponse.json({ ok: true });
}
