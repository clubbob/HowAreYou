import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { verifyPassword } from '@/lib/inquiry-utils';

export async function POST(request: Request) {
  try {
    const body = await request.json().catch(() => ({}));
    const code = typeof body.code === 'string' ? body.code.trim().toUpperCase() : '';
    const password = typeof body.password === 'string' ? body.password : '';

    if (!code || code.length !== 6) {
      return NextResponse.json({ error: '문의 번호를 입력해주세요.' }, { status: 400 });
    }

    if (!password) {
      return NextResponse.json({ error: '비밀번호를 입력해주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ error: '서비스를 일시적으로 사용할 수 없습니다.' }, { status: 500 });
    }

    const snap = await db
      .collection('inquiries')
      .where('role', '==', 'visitor')
      .where('inquiryCode', '==', code)
      .limit(1)
      .get();

    if (snap.empty) {
      return NextResponse.json({ error: '문의를 찾을 수 없습니다.' }, { status: 404 });
    }

    const doc = snap.docs[0];
    const d = doc.data();
    const passwordHash = d.passwordHash;

    if (!passwordHash || !verifyPassword(password, passwordHash)) {
      return NextResponse.json({ error: '비밀번호가 일치하지 않습니다.' }, { status: 401 });
    }

    if (d.deletedByUserAt) {
      return NextResponse.json({ error: '이미 삭제된 문의입니다.' }, { status: 400 });
    }

    await doc.ref.update({
      deletedByUserAt: FieldValue.serverTimestamp(),
    });

    return NextResponse.json({ success: true });
  } catch (e) {
    console.error('[inquiry/delete]', e);
    return NextResponse.json({ error: '삭제에 실패했습니다.' }, { status: 500 });
  }
}
