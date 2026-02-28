import { NextRequest, NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { BETA } from '@/lib/config/beta';
import { toE164 } from '@/lib/phone';

/** 해당 기수(1기, 2기 등) 대기 인원 수 */
async function getWaitlistCount(
  db: FirebaseFirestore.Firestore,
  cohort: string
): Promise<number> {
  const snap = await db.collection('waitlist').limit(500).get();
  return snap.docs.filter((doc) => {
    const c = doc.data().cohort;
    return !c || c === cohort;
  }).length;
}

/** 1년 무료 혜택 모집 마감 여부 조회 (공개) */
export async function GET() {
  try {
    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ full: false });
    }
    const count = await getWaitlistCount(db, BETA.cohort);
    return NextResponse.json({ full: count >= BETA.limit });
  } catch {
    return NextResponse.json({ full: false });
  }
}

function isValidEmail(v: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim());
}

/** Play Store 테스터 등록용 Gmail/Google 계정만 허용 */
function isGmailOrGoogle(v: string): boolean {
  const domain = v.trim().toLowerCase().split('@')[1] || '';
  return domain === 'gmail.com' || domain === 'googlemail.com';
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const name = body?.name;
    const phone = body?.phone;
    const email = body?.email;

    if (!name || typeof name !== 'string') {
      return NextResponse.json({ error: '이름을 입력해 주세요.' }, { status: 400 });
    }
    if (!phone || typeof phone !== 'string') {
      return NextResponse.json({ error: '휴대폰 번호를 입력해 주세요.' }, { status: 400 });
    }

    const nameTrimmed = name.trim();
    const phoneNormalized = toE164(phone);
    const emailTrimmed = typeof email === 'string' ? email.trim().toLowerCase() : '';
    const hasValidEmail = emailTrimmed && isValidEmail(emailTrimmed) && isGmailOrGoogle(emailTrimmed);

    if (nameTrimmed.length < 1) {
      return NextResponse.json({ error: '이름을 입력해 주세요.' }, { status: 400 });
    }
    if (!phoneNormalized || phoneNormalized.length < 12) {
      return NextResponse.json({ error: '올바른 휴대폰 번호를 입력해 주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json(
        { error: '서비스를 일시적으로 사용할 수 없습니다. (Firebase Admin 미설정)' },
        { status: 500 }
      );
    }

    const [count, phoneSnap, emailSnap] = await Promise.all([
      getWaitlistCount(db, BETA.cohort),
      db.collection('waitlist').where('phone', '==', phoneNormalized).get(),
      hasValidEmail ? db.collection('waitlist').where('email', '==', emailTrimmed).get() : Promise.resolve(null),
    ]);
    if (count >= BETA.limit) return NextResponse.json({ status: 'full' });
    const isDuplicate = (snap: FirebaseFirestore.QuerySnapshot | null) =>
      snap ? snap.docs.some((doc) => {
        const c = doc.data().cohort;
        return !c || c === BETA.cohort;
      }) : false;
    if (isDuplicate(phoneSnap) || isDuplicate(emailSnap)) {
      return NextResponse.json({ status: 'already_registered' });
    }

    await db.collection('waitlist').add({
      name: nameTrimmed,
      phone: phoneNormalized,
      email: hasValidEmail ? emailTrimmed : '',
      cohort: BETA.cohort,
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
