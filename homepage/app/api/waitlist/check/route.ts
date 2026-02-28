import { NextRequest, NextResponse } from 'next/server';
import { getAdminFirestore, getAdminAuth } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { BETA } from '@/lib/config/beta';
import { toE164 } from '@/lib/phone';

/**
 * 1년 무료 혜택 waitlist 등록 여부 확인 (앱에서 betaCohort 부여용)
 * POST + Firebase ID token 검증 → 토큰의 phone_number로 매칭 (클라이언트 조작 불가)
 * - 매칭 시 waitlist에 activatedAt, activatedByUid 기록 (1회만 적용 강제)
 * - 이미 activated면 업데이트 생략, isBeta만 반환
 */
export async function POST(request: NextRequest) {
  try {
    const authHeader = request.headers.get('authorization');
    const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) {
      return NextResponse.json({ isBeta: false });
    }

    const auth = getAdminAuth();
    if (!auth) {
      return NextResponse.json({ isBeta: false });
    }

    const decoded = await auth.verifyIdToken(token);
    const phoneFromToken = decoded.phone_number;
    const uid = decoded.uid;
    if (!phoneFromToken || typeof phoneFromToken !== 'string') {
      return NextResponse.json({ isBeta: false });
    }

    // Firebase Auth는 이미 E.164 반환. 통일을 위해 toE164 한 번 더 적용
    const phoneE164 = toE164(phoneFromToken);
    if (!phoneE164 || phoneE164.length < 12) {
      return NextResponse.json({ isBeta: false });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ isBeta: false });
    }

    // E.164로 조회. 기존 010 형식 데이터 호환: 010 형식도 시도
    const phone010 = phoneE164.startsWith('+82')
      ? '0' + phoneE164.substring(3)
      : null;

    const [snapE164, snap010] = await Promise.all([
      db.collection('waitlist').where('phone', '==', phoneE164).limit(1).get(),
      phone010
        ? db.collection('waitlist').where('phone', '==', phone010).limit(1).get()
        : Promise.resolve({ docs: [] }),
    ]);

    const allDocs = [...snapE164.docs, ...snap010.docs];
    const matchDoc = allDocs.find((doc) => {
      const d = doc.data();
      const c = d.cohort;
      return !c || c === BETA.cohort;
    });

    if (!matchDoc) {
      return NextResponse.json({ isBeta: false });
    }

    const data = matchDoc.data();
    const alreadyActivated = !!data.activatedAt;

    // applied → activated 전이: 1회만 허용
    if (!alreadyActivated) {
      await matchDoc.ref.update({
        activatedAt: FieldValue.serverTimestamp(),
        activatedByUid: uid,
      });
    }

    return NextResponse.json({ isBeta: true });
  } catch {
    return NextResponse.json({ isBeta: false });
  }
}

