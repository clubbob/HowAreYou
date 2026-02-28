import { NextRequest, NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { BETA } from '@/lib/config/beta';
import { normalizePhone } from '@/lib/phone';

/** 1년 무료 혜택 waitlist 등록 여부 확인 (앱에서 betaCohort 부여용) */
export async function GET(request: NextRequest) {
  try {
    const phone = request.nextUrl.searchParams.get('phone');
    if (!phone || typeof phone !== 'string') {
      return NextResponse.json({ isBeta: false });
    }
    const normalized = normalizePhone(phone);
    if (normalized.length < 10) {
      return NextResponse.json({ isBeta: false });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json({ isBeta: false });
    }

    // 01012345678 형식으로 조회 (기존 +82 형식 데이터 호환: 두 형식 모두 시도)
    const altPhone = normalized.startsWith('0') ? '82' + normalized.substring(1) : null;
    const [snap1, snap2] = await Promise.all([
      db.collection('waitlist').where('phone', '==', normalized).limit(1).get(),
      altPhone ? db.collection('waitlist').where('phone', '==', altPhone).limit(1).get() : Promise.resolve({ docs: [] }),
    ]);

    const isBeta = [...snap1.docs, ...snap2.docs].some((doc) => {
      const c = doc.data().cohort;
      return !c || c === BETA.cohort;
    });

    return NextResponse.json({ isBeta });
  } catch {
    return NextResponse.json({ isBeta: false });
  }
}
