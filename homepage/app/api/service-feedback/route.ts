import { NextResponse } from 'next/server';
import { getAdminFirestore } from '@/lib/firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';

const SATISFACTION_VALUES = [1, 2, 3, 4, 5] as const;
const CONTINUE_INTENTS = [
  '계속 사용할 예정입니다',
  '고민 중입니다',
  '사용하지 않을 것 같습니다',
] as const;
const NEEDS_REASON_INTENTS = ['고민 중입니다', '사용하지 않을 것 같습니다'];

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      satisfaction,
      inconvenience,
      improvementIdea,
      continueIntent,
      retentionReason,
      userPhone,
      userDisplayName,
    } = body;

    const sat = parseInt(satisfaction, 10);
    if (!SATISFACTION_VALUES.includes(sat as (typeof SATISFACTION_VALUES)[number])) {
      return NextResponse.json({ error: '사용 경험을 선택해 주세요.' }, { status: 400 });
    }

    const intent =
      continueIntent &&
      typeof continueIntent === 'string' &&
      CONTINUE_INTENTS.includes(continueIntent as (typeof CONTINUE_INTENTS)[number])
        ? continueIntent
        : null;
    if (!intent) {
      return NextResponse.json(
        { error: '계속 사용하실 의향을 선택해 주세요.' },
        { status: 400 }
      );
    }

    const needsReason = NEEDS_REASON_INTENTS.includes(intent);
    if (needsReason && (!retentionReason || typeof retentionReason !== 'string' || !retentionReason.trim())) {
      return NextResponse.json(
        { error: '이유를 입력해 주세요.' },
        { status: 400 }
      );
    }

    if ((sat === 1 || sat === 2) && (!inconvenience || typeof inconvenience !== 'string' || !inconvenience.trim())) {
      return NextResponse.json(
        { error: '가장 아쉬웠던 점을 입력해 주세요.' },
        { status: 400 }
      );
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
    doc.continueIntent = intent;
    if (retentionReason && typeof retentionReason === 'string' && retentionReason.trim()) {
      doc.retentionReason = retentionReason.trim().slice(0, 500);
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
