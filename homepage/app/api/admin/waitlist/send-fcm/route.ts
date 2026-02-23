import { NextRequest, NextResponse } from 'next/server';
import { FieldValue } from 'firebase-admin/firestore';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore, getAdminMessaging } from '@/lib/firebase-admin';

/** 전화번호 E.164 정규화 (users 컬렉션과 매칭용) */
function normalizePhone(phone: string): string {
  if (!phone || typeof phone !== 'string') return '';
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 0) return '';
  if (digits.startsWith('82') && digits.length >= 11) return '+' + digits;
  if (digits.startsWith('010') && digits.length >= 9) return '+82' + digits.substring(1);
  if (digits.startsWith('0') && digits.length >= 10) return '+82' + digits.substring(1);
  return '+82' + digits;
}

export async function POST(request: NextRequest) {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const db = getAdminFirestore();
  const messaging = getAdminMessaging();
  if (!db || !messaging) {
    return NextResponse.json(
      { error: 'Firebase Admin(FCM)이 설정되지 않았습니다.' },
      { status: 500 }
    );
  }

  let body: { selectedIds?: string[]; title?: string; body?: string; link?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: '잘못된 요청입니다.' }, { status: 400 });
  }

  const { selectedIds, title, body: bodyText } = body;
  if (!Array.isArray(selectedIds) || selectedIds.length === 0) {
    return NextResponse.json({ error: '선택된 항목이 없습니다.' }, { status: 400 });
  }
  const trimmedTitle = (title ?? '').toString().trim() || '오늘 어때';
  const trimmedBody = (bodyText ?? '').toString().trim() || '새 소식이 있습니다.';
  const link = (body.link ?? '').toString().trim();

  try {
    // 1. 선택된 waitlist 항목의 휴대폰 번호 조회
    const waitlistSnaps = await Promise.all(
      selectedIds.map((id) => db.collection('waitlist').doc(id).get())
    );
    const phones = waitlistSnaps
      .filter((s) => s.exists)
      .map((s) => (s.data()?.phone ?? '').toString().trim())
      .filter(Boolean);

    if (phones.length === 0) {
      return NextResponse.json({
        success: false,
        error: '선택한 항목에서 휴대폰 번호를 찾을 수 없습니다.',
        sentCount: 0,
        noTokenCount: phones.length,
      });
    }

    // 2. 휴대폰 번호로 users 컬렉션에서 FCM 토큰 수집
    const normalizedPhones = [...new Set(phones.map(normalizePhone))].filter(Boolean);
    const allTokens: string[] = [];
    const phonesWithTokens = new Set<string>();
    const userIdsSentTo = new Set<string>();
    const usersSnap = await db.collection('users').get();

    for (const doc of usersSnap.docs) {
      const data = doc.data();
      const userPhone = (data.phone ?? '').toString().trim();
      if (!userPhone) continue;
      const userNormalized = normalizePhone(userPhone);
      if (normalizedPhones.includes(userNormalized)) {
        const tokens = (data.fcmTokens ?? []).filter((t): t is string => Boolean(t));
        if (tokens.length > 0) {
          phonesWithTokens.add(userNormalized);
          userIdsSentTo.add(doc.id);
        }
        allTokens.push(...tokens);
      }
    }

    const uniqueTokens = [...new Set(allTokens)];
    const noTokenCount = normalizedPhones.filter((p) => !phonesWithTokens.has(p)).length;

    if (uniqueTokens.length === 0) {
      return NextResponse.json({
        success: true,
        sentCount: 0,
        noTokenCount,
        message: '앱을 설치·로그인한 사용자가 없어 발송된 PUSH가 없습니다.',
      });
    }

    // 3. FCM 멀티캐스트 발송 (500개 단위 - FCM 제한)
    const CHUNK = 500;
    let successCount = 0;
    let failureCount = 0;

    for (let i = 0; i < uniqueTokens.length; i += CHUNK) {
      const chunk = uniqueTokens.slice(i, i + CHUNK);
      const payload: import('firebase-admin/messaging').MulticastMessage = {
        tokens: chunk,
        notification: { title: trimmedTitle, body: trimmedBody },
        data: {
          type: 'ADMIN_BROADCAST',
          ...(link ? { link } : {}),
        },
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'daily_mood_check' },
        },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      };

      const res = await messaging.sendEachForMulticast(payload);
      successCount += res.successCount;
      failureCount += res.failureCount;
    }

    // 4. 발송 이력 저장 (waitlist + users)
    const batch = db.batch();
    for (const id of selectedIds) {
      batch.update(db.collection('waitlist').doc(id), { lastFcmSentAt: FieldValue.serverTimestamp() });
    }
    for (const uid of userIdsSentTo) {
      batch.update(db.collection('users').doc(uid), { lastFcmSentAt: FieldValue.serverTimestamp() });
    }
    await batch.commit();

    return NextResponse.json({
      success: true,
      sentCount: successCount,
      failureCount,
      noTokenCount,
    });
  } catch (e) {
    console.error('[admin/waitlist/send-fcm]', e);
    return NextResponse.json(
      { error: 'FCM 발송 중 오류가 발생했습니다.', _debug: String(e) },
      { status: 500 }
    );
  }
}
