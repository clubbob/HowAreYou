import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { hashPassword, generateInquiryCode } from '@/lib/inquiry-utils';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { message, password } = body;

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return NextResponse.json({ error: '문의 내용을 입력해주세요.' }, { status: 400 });
    }

    if (message.length > 2000) {
      return NextResponse.json({ error: '문의 내용은 2000자 이내로 입력해주세요.' }, { status: 400 });
    }

    if (!password || typeof password !== 'string' || password.trim().length < 4) {
      return NextResponse.json({ error: '비밀번호를 4자 이상 입력해주세요.' }, { status: 400 });
    }

    if (password.length > 50) {
      return NextResponse.json({ error: '비밀번호는 50자 이내로 입력해주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ error: '서비스를 일시적으로 사용할 수 없습니다.' }, { status: 500 });
    }

    const inquiryCode = generateInquiryCode();
    const passwordHash = hashPassword(password.trim());

    await db.collection('inquiries').add({
      userId: '',
      userPhone: null,
      userDisplayName: null,
      role: 'visitor',
      email: null,
      message: message.trim(),
      inquiryCode,
      passwordHash,
      createdAt: FieldValue.serverTimestamp(),
      replies: [],
    });

    return NextResponse.json({
      success: true,
      inquiryCode,
    });
  } catch (e) {
    console.error('[inquiry]', e);
    return NextResponse.json({ error: '문의 등록에 실패했습니다.' }, { status: 500 });
  }
}
