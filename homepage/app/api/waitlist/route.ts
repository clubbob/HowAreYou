import { NextRequest, NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const BETA_LIMIT = 100;

async function getWaitlistCount(db: FirebaseFirestore.Firestore): Promise<number> {
  try {
    const countSnap = await db.collection('waitlist').count().get();
    return countSnap.data().count ?? 0;
  } catch {
    // count() 미지원 시 get().size로 폴백
    const snap = await db.collection('waitlist').limit(BETA_LIMIT + 1).get();
    return snap.size;
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const phone = body?.phone;

    if (!phone || typeof phone !== 'string') {
      return NextResponse.json({ error: '휴대폰 번호를 입력해 주세요.' }, { status: 400 });
    }

    const phoneNormalized = phone.trim().replace(/[\s-]/g, '');
    if (phoneNormalized.length < 10) {
      return NextResponse.json({ error: '올바른 휴대폰 번호를 입력해 주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json(
        { error: '서비스를 일시적으로 사용할 수 없습니다. (Firebase Admin 미설정)' },
        { status: 500 }
      );
    }

    const [count, existingSnap] = await Promise.all([
      getWaitlistCount(db),
      db.collection('waitlist').where('phone', '==', phoneNormalized).limit(1).get(),
    ]);
    if (count >= BETA_LIMIT) return NextResponse.json({ status: 'full' });
    if (!existingSnap.empty) return NextResponse.json({ status: 'already_registered' });

    await db.collection('waitlist').add({
      phone: phoneNormalized,
      createdAt: FieldValue.serverTimestamp(),
    });
    return NextResponse.json({ status: 'success' });
  } catch (e) {
    console.error('[waitlist]', e);
    const errMsg = e instanceof Error ? e.message : '알 수 없는 오류';
    const isFirestore = errMsg.includes('Firestore') || errMsg.includes('firebase') || errMsg.includes('permission');
    const userMessage = isFirestore
      ? '서비스를 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해 주세요.'
      : '등록에 실패했습니다. 잠시 후 다시 시도해 주세요.';
    return NextResponse.json(
      { error: userMessage, ...(process.env.NODE_ENV === 'development' && { _debug: errMsg }) },
      { status: 500 }
    );
  }
}
