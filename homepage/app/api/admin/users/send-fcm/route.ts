import { NextRequest, NextResponse } from 'next/server';
import { FieldValue } from 'firebase-admin/firestore';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore, getAdminMessaging } from '@/lib/firebase-admin';

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
    return NextResponse.json({ error: '선택된 회원이 없습니다.' }, { status: 400 });
  }
  const trimmedTitle = (title ?? '').toString().trim() || '오늘 어때';
  const trimmedBody = (bodyText ?? '').toString().trim() || '새 소식이 있습니다.';
  const link = (body.link ?? '').toString().trim();

  try {
    const uniqueIds = [...new Set(selectedIds)].filter(Boolean);
    const allTokens: string[] = [];
    const usersWithTokens = new Set<string>();

    for (const uid of uniqueIds) {
      const userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) continue;
      const data = userDoc.data();
      // 로그아웃한 사용자(signedOutAt 있음)는 발송 대상에서 제외
      if (data?.signedOutAt) continue;
      const tokens = (data?.fcmTokens ?? []).filter((t: unknown): t is string => typeof t === 'string' && Boolean(t));
      if (tokens.length > 0) {
        usersWithTokens.add(uid);
        allTokens.push(...tokens);
      }
    }

    const uniqueTokens = [...new Set(allTokens)];
    const noTokenCount = uniqueIds.length - usersWithTokens.size;

    if (uniqueTokens.length === 0) {
      return NextResponse.json({
        success: true,
        sentCount: 0,
        noTokenCount: uniqueIds.length,
        message: '선택한 회원 중 FCM 토큰이 있는 사용자가 없어 발송된 PUSH가 없습니다.',
      });
    }

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

    // 발송한 회원의 users 문서에 lastFcmSentAt 업데이트
    const batch = db.batch();
    for (const uid of usersWithTokens) {
      batch.update(db.collection('users').doc(uid), { lastFcmSentAt: FieldValue.serverTimestamp() });
    }
    if (usersWithTokens.size > 0) await batch.commit();

    return NextResponse.json({
      success: true,
      sentCount: successCount,
      failureCount,
      noTokenCount,
    });
  } catch (e) {
    console.error('[admin/users/send-fcm]', e);
    return NextResponse.json(
      { error: 'FCM 발송 중 오류가 발생했습니다.', _debug: String(e) },
      { status: 500 }
    );
  }
}
