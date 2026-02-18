import { NextRequest, NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const BETA_LIMIT = 100;

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const email = body?.email;
    const phone = body?.phone;

    if (!email || typeof email !== 'string') {
      return NextResponse.json({ error: '이메일을 입력해 주세요.' }, { status: 400 });
    }

    const normalized = email.trim().toLowerCase();
    if (!normalized) {
      return NextResponse.json({ error: '이메일을 입력해 주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ error: '서비스를 일시적으로 사용할 수 없습니다.' }, { status: 500 });
    }

    const countSnap = await db.collection('waitlist').count().get();
    const count = countSnap.data().count;
    if (count >= BETA_LIMIT) {
      return NextResponse.json({ status: 'full' });
    }

    const phoneNormalized = phone && typeof phone === 'string' ? phone.trim().replace(/\s/g, '') : '';

    const existingSnap = await db.collection('waitlist').where('email', '==', normalized).limit(1).get();
    if (!existingSnap.empty) {
      const existingDoc = existingSnap.docs[0];
      if (phoneNormalized) {
        const existingData = existingDoc.data();
        if (!existingData.phone) {
          await db.collection('waitlist').doc(existingDoc.id).update({ phone: phoneNormalized });
        }
      }
      return NextResponse.json({ status: 'already_registered' });
    }

    const docData: Record<string, unknown> = {
      email: normalized,
      createdAt: FieldValue.serverTimestamp(),
    };
    if (phoneNormalized) {
      docData.phone = phoneNormalized;
    }

    await db.collection('waitlist').add(docData);
    return NextResponse.json({ status: 'success' });
  } catch (e) {
    console.error('[waitlist]', e);
    return NextResponse.json({ error: '등록에 실패했습니다.' }, { status: 500 });
  }
}
