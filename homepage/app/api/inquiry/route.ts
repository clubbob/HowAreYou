import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, email, phone, message } = body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return NextResponse.json({ error: '문의 내용을 입력해주세요.' }, { status: 400 });
    }

    if (message.length > 2000) {
      return NextResponse.json({ error: '문의 내용은 2000자 이내로 입력해주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ error: '서비스를 일시적으로 사용할 수 없습니다.' }, { status: 500 });
    }

    const contact = [email, phone].filter(Boolean).join(' / ') || '(미입력)';
    const emailTrimmed = email && typeof email === 'string' ? email.trim().toLowerCase() : null;

    await db.collection('inquiries').add({
      userId: '',
      userPhone: contact,
      userDisplayName: (name && typeof name === 'string' ? name.trim() : null) || null,
      role: 'visitor',
      email: emailTrimmed || null,
      message: message.trim(),
      createdAt: FieldValue.serverTimestamp(),
      replies: [],
    });

    return NextResponse.json({ success: true });
  } catch (e) {
    console.error('[inquiry]', e);
    return NextResponse.json({ error: '문의 등록에 실패했습니다.' }, { status: 500 });
  }
}
