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

  const { id } = await params;
  if (!id) {
    return NextResponse.json({ error: 'id required' }, { status: 400 });
  }

  let body: { phone?: string; name?: string; email?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const phone = body.phone != null ? String(body.phone).trim().replace(/[\s-]/g, '') : undefined;
  const name = body.name != null ? String(body.name).trim() : undefined;
  const email = body.email != null ? String(body.email).trim() : undefined;

  const updates: Record<string, string> = {};
  if (phone !== undefined) updates.phone = phone;
  if (name !== undefined) updates.name = name;
  if (email !== undefined) updates.email = email;
  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: 'phone, name or email required' }, { status: 400 });
  }

  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  try {
    await db.collection('waitlist').doc(id).update(updates);
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error('[waitlist patch]', e);
    return NextResponse.json({ error: '수정 실패' }, { status: 500 });
  }
}

export async function DELETE(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { id } = await params;
  if (!id) {
    return NextResponse.json({ error: 'id required' }, { status: 400 });
  }

  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  try {
    await db.collection('waitlist').doc(id).delete();
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error('[waitlist delete]', e);
    return NextResponse.json({ error: '삭제 실패' }, { status: 500 });
  }
}
