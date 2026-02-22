import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const SATISFACTION_VALUES = [1, 2, 3, 4, 5] as const;
const CONTINUE_INTENTS = [
  '계속 사용할 예정입니다',
  '고민 중입니다',
  '사용하지 않을 것 같습니다',
] as const;

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      satisfaction,
      inconvenience,
      improvementIdea,
      continueIntent,
      userPhone,
      userDisplayName,
    } = body;

    const sat = parseInt(satisfaction, 10);
    if (!SATISFACTION_VALUES.includes(sat as (typeof SATISFACTION_VALUES)[number])) {
      return NextResponse.json({ error: '만족도 평가를 선택해 주세요.' }, { status: 400 });
    }

    const db = getAdminFirestore();
    if (!db) {
      return NextResponse.json(
        { error: '서비스를 일시적으로 사용할 수 없습니다.' },
        { status: 500 }
      );
    }

    const doc: Record<string, unknown> = {
      userId: '',
      source: 'web',
      satisfaction: sat,
      createdAt: FieldValue.serverTimestamp(),
    };

    if (userPhone && typeof userPhone === 'string' && userPhone.trim()) {
      doc.userPhone = userPhone.trim();
    }
    if (userDisplayName && typeof userDisplayName === 'string' && userDisplayName.trim()) {
      doc.userDisplayName = userDisplayName.trim();
    }
    if (inconvenience && typeof inconvenience === 'string' && inconvenience.trim()) {
      doc.inconvenience = inconvenience.trim().slice(0, 1000);
    }
    if (improvementIdea && typeof improvementIdea === 'string' && improvementIdea.trim()) {
      doc.improvementIdea = improvementIdea.trim().slice(0, 1000);
    }
    if (
      continueIntent &&
      typeof continueIntent === 'string' &&
      CONTINUE_INTENTS.includes(continueIntent as (typeof CONTINUE_INTENTS)[number])
    ) {
      doc.continueIntent = continueIntent;
    }

    await db.collection('service_feedback').add(doc);

    return NextResponse.json({ success: true });
  } catch (e) {
    console.error('[service-feedback]', e);
    return NextResponse.json(
      { error: '의견 전송에 실패했습니다. 잠시 후 다시 시도해 주세요.' },
      { status: 500 }
    );
  }
}
