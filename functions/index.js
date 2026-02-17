const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/** 한국 시간(KST) 기준 오늘 날짜 yyyy-MM-dd (pairedAt 등 앱과 일치) */
function todayKoreaStr() {
  const koreaOffset = 9 * 60 * 60 * 1000;
  return new Date(Date.now() + koreaOffset).toISOString().slice(0, 10);
}

/**
 * nextReminderAt 초기값 (신규 subject 생성 시)
 * - 현재 19:00 이전 → 오늘 19:00 KST
 * - 현재 19:00 이후 → 내일 19:00 KST
 */
function getInitialNextReminderAt() {
  const todayStr = todayKoreaStr();
  const [y, m, d] = todayStr.split('-').map(Number);
  const koreaHour = new Date(Date.now() + 9 * 60 * 60 * 1000).getUTCHours();
  const isBefore19 = koreaHour < 19;
  const targetDate = isBefore19 ? new Date(Date.UTC(y, m - 1, d, 10, 0, 0)) : new Date(Date.UTC(y, m - 1, d + 1, 10, 0, 0));
  return admin.firestore.Timestamp.fromDate(targetDate);
}

/** 전화번호 E.164 정규화 (매칭용) */
function normalizePhone(phone) {
  if (!phone || typeof phone !== 'string') return '';
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 0) return '';
  if (digits.startsWith('82') && digits.length >= 11) return '+' + digits;
  if (digits.startsWith('010') && digits.length >= 9) return '+82' + digits.substring(1);
  if (digits.startsWith('0') && digits.length >= 10) return '+82' + digits.substring(1);
  if (!phone.trim().startsWith('+')) return '+82' + digits;
  return phone.trim();
}

/**
 * 신규 가입 시 대기 초대 처리 (가입 시 자동 연결)
 * - 보호자→대상자: 새 사용자 = 대상자 → pending_guardian_invites에서 guardian 추가
 * - 대상자→보호자: 새 사용자 = 보호자 → pending_subject_invites에서 subject에 self 추가
 */
exports.processPendingInvitesOnSignup = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const phone = user.phoneNumber || '';
  const normalized = normalizePhone(phone);
  if (!normalized) {
    console.log('[대기초대] 전화번호 없음, 스킵:', uid);
    return null;
  }
  console.log('[대기초대] 신규 가입 처리 uid=', uid, 'phone=', normalized);

  try {
    // 1. pending_guardian_invites: 이 번호를 subject로 등록하려 했던 보호자들이 있다면 연결
    const guardianInvitesSnap = await db.collection('pending_guardian_invites')
      .where('subjectPhone', '==', normalized)
      .get();

    for (const doc of guardianInvitesSnap.docs) {
      const data = doc.data();
      const guardianUid = data.guardianUid;
      if (!guardianUid || guardianUid === uid) continue;
      try {
        const subjectRef = db.collection('subjects').doc(uid);
        const subjectSnap = await subjectRef.get();
        const existing = subjectSnap.data() || {};
        const paired = [...(existing.pairedGuardianUids || [])];
        const infos = { ...(existing.guardianInfos || {}) };
        if (paired.includes(guardianUid)) continue;
        paired.push(guardianUid);
        const pairedAt = todayKoreaStr();
        infos[guardianUid] = {
          phone: data.guardianPhone || '',
          displayName: data.guardianDisplayName || '',
          pairedAt,
        };
        const setData = { pairedGuardianUids: paired, guardianInfos: infos };
        if (!subjectSnap.exists || !subjectSnap.data()?.nextReminderAt) {
          setData.nextReminderAt = getInitialNextReminderAt();
          setData.reminderSentForDate = null;
        }
        await subjectRef.set(setData, { merge: true });
        console.log('[대기초대] 보호자 연결 완료 subject=', uid, 'guardian=', guardianUid);
      } catch (e) {
        console.error('[대기초대] 보호자 연결 실패:', e);
      }
      await doc.ref.delete();
    }

    // 2. pending_subject_invites: 이 번호를 guardian으로 등록하려 했던 대상자들이 있다면 연결
    const subjectInvitesSnap = await db.collection('pending_subject_invites')
      .where('guardianPhone', '==', normalized)
      .get();

    const guardianUserDoc = await db.collection('users').doc(uid).get();
    const guardianData = guardianUserDoc.exists ? guardianUserDoc.data() : {};
    const guardianPhone = guardianData.phone || normalized;
    const guardianDisplayName = guardianData.displayName || '';

    for (const doc of subjectInvitesSnap.docs) {
      const data = doc.data();
      const subjectUid = data.subjectUid;
      if (!subjectUid || subjectUid === uid) continue;
      try {
        const subjectRef = db.collection('subjects').doc(subjectUid);
        const subjectSnap = await subjectRef.get();
        const existing = subjectSnap.data() || {};
        const paired = [...(existing.pairedGuardianUids || [])];
        const infos = { ...(existing.guardianInfos || {}) };
        if (paired.includes(uid)) continue;
        paired.push(uid);
        const pairedAt = todayKoreaStr();
        infos[uid] = { phone: guardianPhone, displayName: guardianDisplayName, pairedAt };
        const setData2 = { pairedGuardianUids: paired, guardianInfos: infos };
        if (!subjectSnap.exists || !subjectSnap.data()?.nextReminderAt) {
          setData2.nextReminderAt = getInitialNextReminderAt();
          setData2.reminderSentForDate = null;
        }
        await subjectRef.set(setData2, { merge: true });
        console.log('[대기초대] 보호대상자 연결 완료 subject=', subjectUid, 'guardian=', uid);
      } catch (e) {
        console.error('[대기초대] 보호대상자 연결 실패:', e);
      }
      await doc.ref.delete();
    }
  } catch (error) {
    console.error('[대기초대] 오류:', error);
  }
  return null;
});

/**
 * 보호자가 보호대상자 목록에서 자신을 제거 (permission-denied 우회용 Cloud Function)
 * - 호출자(request.auth.uid)가 subjectId 문서의 pairedGuardianUids에 있을 때만 허용
 */
exports.removeGuardianFromSubject = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }
  const guardianUid = context.auth.uid;
  const subjectId = data?.subjectId;
  if (!subjectId || typeof subjectId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'subjectId가 필요합니다.');
  }
  if (guardianUid === subjectId) {
    return { success: true }; // 본인 문서는 무시
  }

  const subjectRef = db.collection('subjects').doc(subjectId);
  const subjectSnap = await subjectRef.get();
  if (!subjectSnap.exists) {
    return { success: true }; // 이미 없으면 성공으로 처리
  }

  const existing = subjectSnap.data() || {};
  const paired = [...(existing.pairedGuardianUids || [])];
  if (!paired.includes(guardianUid)) {
    return { success: true }; // 이미 제거됨
  }

  const infos = { ...(existing.guardianInfos || {}) };
  delete infos[guardianUid];
  const newPaired = paired.filter((uid) => uid !== guardianUid);

  await subjectRef.update({
    pairedGuardianUids: newPaired,
    guardianInfos: infos,
  });
  console.log('[removeGuardianFromSubject] 완료 subject=', subjectId, 'guardian=', guardianUid);
  return { success: true };
});

/**
 * 보호자에게 FCM 알림 발송 및 invalid 토큰 정리
 * @param {string} guardianUid 보호자 UID
 * @param {object} payload FCM 메시지 페이로드 (tokens 제외)
 * @returns {Promise<{successCount: number, failureCount: number}>}
 */
async function sendToGuardian(guardianUid, payload) {
  try {
    // 보호자 문서에서 FCM 토큰 조회
    const userDoc = await admin.firestore().collection('users').doc(guardianUid).get();
    if (!userDoc.exists) {
      console.log(`[FCM 발송] 보호자 문서 없음: ${guardianUid}`);
      return { successCount: 0, failureCount: 0 };
    }

    const userData = userDoc.data();
    const tokens = (userData?.fcmTokens || []).filter(Boolean);
    console.log(`[FCM 발송] 보호자 ${guardianUid}: 토큰 ${tokens.length}개`);
    
    if (tokens.length === 0) {
      console.log(`[FCM 발송] 보호자 ${guardianUid}: FCM 토큰이 없어 알림 발송 불가`);
      return { successCount: 0, failureCount: 0 };
    }

    // FCM 메시지 발송
    const messagePayload = {
      ...payload,
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(messagePayload);
    console.log(`[FCM 발송] 보호자 ${guardianUid}: ${response.successCount}개 성공, ${response.failureCount}개 실패`);

    // Invalid 토큰 정리
    const invalidTokenErrors = new Set([
      'messaging/registration-token-not-registered',
      'messaging/invalid-registration-token',
    ]);

    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success && invalidTokenErrors.has(resp.error?.code)) {
        invalidTokens.push(tokens[idx]);
        console.log(`[FCM 발송] 보호자 ${guardianUid}: 토큰 ${idx} 실패 - ${resp.error?.code}`);
      } else if (!resp.success) {
        console.log(`[FCM 발송] 보호자 ${guardianUid}: 토큰 ${idx} 실패 - ${resp.error?.message || '알 수 없는 오류'}`);
      }
    });

    // Invalid 토큰 제거
    if (invalidTokens.length > 0) {
      await admin.firestore().collection('users').doc(guardianUid).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
      console.log(`[FCM 토큰 정리] ${guardianUid}: ${invalidTokens.length}개 제거`);
    }

    return {
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error(`[FCM 발송 오류] ${guardianUid}:`, error);
    return { successCount: 0, failureCount: 0 };
  }
}

/**
 * 특정 사용자(보호대상자)의 FCM 토큰으로 알림 발송 (토큰 정리 포함)
 */
async function sendToUser(userId, payload) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) return { successCount: 0, failureCount: 0 };
    const tokens = (userDoc.data()?.fcmTokens || []).filter(Boolean);
    if (tokens.length === 0) return { successCount: 0, failureCount: 0 };
    const response = await admin.messaging().sendEachForMulticast({ ...payload, tokens });
    const invalidTokenErrors = new Set([
      'messaging/registration-token-not-registered',
      'messaging/invalid-registration-token',
    ]);
    const invalidTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success && invalidTokenErrors.has(resp.error?.code)) invalidTokens.push(tokens[idx]);
    });
    if (invalidTokens.length > 0) {
      await admin.firestore().collection('users').doc(userId).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
    return { successCount: response.successCount, failureCount: response.failureCount };
  } catch (error) {
    console.error(`[FCM 발송 오류] ${userId}:`, error);
    return { successCount: 0, failureCount: 0 };
  }
}

/**
 * 응답 저장/업데이트 시 보호자에게 알림 발송
 * prompts 컬렉션에 새 문서가 생성되거나 업데이트되면 실행
 */
async function sendResponseNotification(snap, context) {
    const { subjectId } = context.params;
    const promptData = snap.data();
    
    try {
      // 보호 대상 문서에서 보호자 UID 목록 가져오기
      const subjectDoc = await admin.firestore().collection('subjects').doc(subjectId).get();
      if (!subjectDoc.exists) {
        return null;
      }

      const subjectData = subjectDoc.data();
      const guardianUids = subjectData.pairedGuardianUids || [];
      console.log(`[응답 알림] 보호 대상: ${subjectId}, 보호자 수: ${guardianUids.length}명`);
      if (guardianUids.length === 0) {
        console.log(`[응답 알림] 보호자가 없어 알림 발송하지 않음`);
        return null; // 보호자가 없으면 알림 불필요
      }

      // 보호 대상 이름 가져오기
      const subjectDisplayName = subjectData.displayName || '보호 대상';
      
      // slot 값으로 문구 결정 (하루 1회 응답 시 slot === 'daily')
      const bodyText = `${subjectDisplayName}님이 컨디션을 기록 했습니다`;

      // 보호자별로 알림 발송 (FCM 토큰 정리 포함)
      const sendPromises = guardianUids.map(async (guardianUid) => {
        console.log(`[응답 알림] 보호자 ${guardianUid}에게 알림 발송 시도`);
        return await sendToGuardian(guardianUid, {
          notification: {
            title: '기록 알림',
            body: bodyText,
          },
          data: {
            type: 'RESPONSE_RECEIVED',
            subjectId: subjectId,
            subjectDisplayName: subjectDisplayName,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'guardian_notifications',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });
      });

      const results = await Promise.all(sendPromises);
      const totalSuccess = results.reduce((sum, r) => sum + (r?.successCount || 0), 0);
      const totalFailure = results.reduce((sum, r) => sum + (r?.failureCount || 0), 0);
      
      console.log(`[응답 알림] ${subjectDisplayName}님: ${totalSuccess}개 성공, ${totalFailure}개 실패`);
      console.log(`[응답 알림] 보호자 수: ${guardianUids.length}명`);
      
      return null;
    } catch (error) {
      console.error('응답 알림 발송 오류:', error);
      return null; // 오류 발생해도 응답 저장은 이미 완료되었으므로 무시
    }
}

/**
 * 응답 생성 시 알림 발송
 */
exports.onResponseCreated = functions.firestore
  .document('subjects/{subjectId}/prompts/{promptId}')
  .onCreate(async (snap, context) => {
    return await sendResponseNotification(snap, context);
  });

/**
 * 응답 업데이트 시에도 알림 발송 (같은 시간대에 다시 응답한 경우)
 */
exports.onResponseUpdated = functions.firestore
  .document('subjects/{subjectId}/prompts/{promptId}')
  .onUpdate(async (change, context) => {
    // 업데이트된 문서 사용
    return await sendResponseNotification(change.after, context);
  });

/**
 * 매일 19:00 (Asia/Seoul) 리마인드 푸시 발송
 *
 * [필드 의미]
 * reminderSentForDate: "오늘 기록 완료 또는 오늘 리마인드 발송 완료 마커"
 *   - 기록 시(mood_service): 오늘 날짜로 설정 → 당일 리마인드 제외
 *   - 발송 시: 트랜잭션으로 원자적 업데이트 → 중복 발송 방지
 *
 * reminderSentAt: 실제 발송 시각 (Timestamp, 디버깅용, 비용 미미)
 *
 * nextReminderAt: 항상 "내일 19:00" (Asia/Seoul) 고정
 *   - 기록 시 / 발송 시 동일 규칙
 *
 * [쿼리] nextReminderAt <= now (Firestore inequality 1개 제한)
 * [필터] reminderSentForDate !== today (메모리)
 * [레이스 방지] 발송 직전 트랜잭션으로 "오늘 처리됨" 원자적 선점, 성공 시에만 FCM 발송
 *
 * [필드 위치] 리마인드 스케줄/마커는 subjects에만. users에는 프로필/토큰/역할 등 사용자 공통만.
 * [데이터 타입] reminderSentForDate: "YYYY-MM-DD" 문자열 | nextReminderAt, reminderSentAt: Timestamp
 * [발송 실패 정책 A] 실패해도 "오늘 처리됨" 유지 → 중복발송 방지 최우선, reminderSendError로 로그만 남김
 *
 * [비용 최적화 TODO] 토큰이 users에만 있으면 subjects 조회 후 users 추가 읽기 발생.
 *   → subjects에 fcmTokens 캐시(또는 hasFcmToken) 시 스케줄 함수에서 subjects만 조회 가능
 */
exports.sendDailyReminder = functions.pubsub
  .schedule('0 19 * * *')
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const todayStr = todayKoreaStr(); // Asia/Seoul 기준 오늘 (스케줄 19:00 KST와 일치)
    
    console.log(`[리마인드 푸시] ${todayStr} 19:00 실행 시작`);
    
    try {
      // nextReminderAt <= now 인 사용자 조회 (Firestore는 1개 inequality만 허용)
      const querySnapshot = await admin.firestore()
        .collection('subjects')
        .where('nextReminderAt', '<=', now)
        .get();
      
      // 오늘 이미 기록했거나 오늘 이미 발송한 사용자 제외
      const toSend = querySnapshot.docs.filter((doc) => {
        const sent = doc.data().reminderSentForDate;
        return sent !== todayStr; // null, 어제 날짜 등 → 발송 대상
      });
      
      console.log(`[리마인드 푸시] 발송 대상: ${toSend.length}명 (쿼리 ${querySnapshot.size}명 중 필터)`);
      
      if (toSend.length === 0) {
        console.log('[리마인드 푸시] 발송 대상 없음');
        return null;
      }
      
      // 내일 19:00 (Asia/Seoul) 고정 - mood_service와 동일 규칙
      const [y, m, d] = todayStr.split('-').map(Number);
      const tomorrow1900KST = new Date(Date.UTC(y, m - 1, d + 1, 10, 0, 0)); // 19:00 KST = 10:00 UTC
      const tomorrowTimestamp = admin.firestore.Timestamp.fromDate(tomorrow1900KST);
      
      // 각 사용자별: 트랜잭션으로 선점 → 성공 시에만 FCM 발송 (레이스/중복 방지)
      const sendPromises = toSend.map(async (doc) => {
        const subjectId = doc.id;
        const subjectRef = doc.ref;

        try {
          // 1) FCM 토큰 조회 (토큰 없으면 선점하지 않음 → 내일 재시도)
          const userDoc = await admin.firestore().collection('users').doc(subjectId).get();
          if (!userDoc.exists) {
            console.log(`[리마인드 푸시] 사용자 문서 없음: ${subjectId}`);
            return { success: false, reason: 'user_not_found' };
          }
          const tokens = (userDoc.data()?.fcmTokens || []).filter(Boolean);
          if (tokens.length === 0) {
            console.log(`[리마인드 푸시] FCM 토큰 없음: ${subjectId} (선점 안 함, 내일 재시도)`);
            return { success: false, reason: 'no_tokens' };
          }

          // 2) 트랜잭션: 조건 2개 재확인 후 선점 (스케줄러 지연/중복/부분실패에도 안정)
          const claimed = await db.runTransaction(async (transaction) => {
            const snap = await transaction.get(subjectRef);
            const data = snap.data() || {};
            if (data.reminderSentForDate === todayStr) return false; // 이미 오늘 처리됨
            const nextAt = data.nextReminderAt;
            if (nextAt && typeof nextAt.toMillis === 'function' && nextAt.toMillis() > now.toMillis()) return false; // 아직 발송 시각 아님
            transaction.update(subjectRef, {
              reminderSentForDate: todayStr,
              nextReminderAt: tomorrowTimestamp, // 항상 내일 19:00 고정
              reminderSentAt: admin.firestore.Timestamp.now(), // 디버깅용 실제 발송 시각
            });
            return true;
          });

          if (!claimed) {
            console.log(`[리마인드 푸시] ${subjectId}: 이미 처리됨(레이스) 스킵`);
            return { success: false, reason: 'already_claimed' };
          }

          // 3) FCM 발송 (선점 성공한 경우만)
          const messagePayload = {
            notification: {
              title: '',
              body: '오늘도 잘 지내고 계신가요?',
            },
            data: {
              type: 'DAILY_REMINDER',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                channelId: 'daily_mood_check',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
            tokens: tokens,
          };

          const response = await admin.messaging().sendEachForMulticast(messagePayload);
          console.log(`[리마인드 푸시] ${subjectId}: ${response.successCount}개 성공, ${response.failureCount}개 실패`);

          // Invalid 토큰 정리
          const invalidTokenErrors = new Set([
            'messaging/registration-token-not-registered',
            'messaging/invalid-registration-token',
          ]);
          const invalidTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success && invalidTokenErrors.has(resp.error?.code)) {
              invalidTokens.push(tokens[idx]);
            }
          });
          if (invalidTokens.length > 0) {
            await admin.firestore().collection('users').doc(subjectId).update({
              fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
            });
            console.log(`[리마인드 푸시] ${subjectId}: Invalid 토큰 ${invalidTokens.length}개 제거`);
          }

          // 성공 시 reminderSendError 삭제 (과거 에러가 남아 오해 방지)
          try {
            await subjectRef.update({
              reminderSendError: admin.firestore.FieldValue.delete(),
            });
          } catch (_) {}

          return { success: true, successCount: response.successCount, failureCount: response.failureCount };
        } catch (error) {
          console.error(`[리마인드 푸시] ${subjectId} 발송 오류:`, error);
          // 정책 A: 실패해도 "오늘 처리됨" 유지. reminderSendError만 남겨 운영 디버깅
          try {
            await subjectRef.update({
              reminderSendError: String(error?.message || error).slice(0, 200),
            });
          } catch (_) {}
          return { success: false, reason: 'error', error: error.message };
        }
      });
      
      const results = await Promise.all(sendPromises);
      const totalSuccess = results.filter(r => r.success).length;
      const totalFailure = results.filter(r => !r.success).length;
      const totalSent = results.reduce((sum, r) => sum + (r.successCount || 0), 0);
      
      console.log(`[리마인드 푸시] 완료: ${totalSuccess}명 성공, ${totalFailure}명 실패, 총 ${totalSent}개 알림 발송`);
      
      return null;
    } catch (error) {
      console.error('[리마인드 푸시] 전체 오류:', error);
      return null;
    }
  });

/**
 * 기존 사용자 마이그레이션: 리마인드 필드 초기화
 * 한 번만 실행하면 되는 배치 작업 (수동 호출)
 */
exports.migrateReminderFields = functions.https.onRequest(async (req, res) => {
  // 보안: 관리자만 실행 가능하도록 (실제 환경에서는 인증 추가 필요)
  const adminKey = req.query.key;
  if (adminKey !== 'migrate_reminder_2026') {
    res.status(403).send('Unauthorized');
    return;
  }
  
  console.log('[마이그레이션] 시작');
  
  try {
    const now = admin.firestore.Timestamp.now();
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    const todayStr = `${year}-${month}-${day}`;
    
    // 내일 19:00 계산 (Asia/Seoul 기준)
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(19, 0, 0, 0);
    const tomorrowTimestamp = admin.firestore.Timestamp.fromDate(tomorrow);
    
    // 모든 subjects 문서 조회 (배치 처리)
    let batch = admin.firestore().batch();
    let batchCount = 0;
    let migratedCount = 0;
    const batchSize = 500; // Firestore 배치 제한
    
    const subjectsSnapshot = await admin.firestore().collection('subjects').get();
    console.log(`[마이그레이션] 전체 subjects 문서 수: ${subjectsSnapshot.size}`);
    
    for (const doc of subjectsSnapshot.docs) {
      const data = doc.data();
      const needsUpdate = {};
      
      // 필드가 없으면 초기화
      if (!data.nextReminderAt) {
        needsUpdate.nextReminderAt = tomorrowTimestamp;
      }
      if (!data.hasOwnProperty('reminderSentForDate')) {
        needsUpdate.reminderSentForDate = null;
      }
      if (!data.lastResponseAt) {
        needsUpdate.lastResponseAt = null;
      }
      if (!data.lastResponseDate) {
        needsUpdate.lastResponseDate = null;
      }
      
      if (Object.keys(needsUpdate).length > 0) {
        batch.update(doc.ref, needsUpdate);
        batchCount++;
        migratedCount++;
        
        // 배치 제한 도달 시 커밋
        if (batchCount >= batchSize) {
          await batch.commit();
          console.log(`[마이그레이션] 배치 커밋: ${migratedCount}개 문서 처리`);
          batch = admin.firestore().batch();
          batchCount = 0;
        }
      }
    }
    
    // 남은 배치 커밋
    if (batchCount > 0) {
      await batch.commit();
      console.log(`[마이그레이션] 최종 배치 커밋: ${batchCount}개 문서 처리`);
    }
    
    console.log(`[마이그레이션] 완료: 총 ${migratedCount}개 문서 마이그레이션`);
    res.status(200).json({
      success: true,
      totalDocuments: subjectsSnapshot.size,
      migratedCount: migratedCount,
    });
  } catch (error) {
    console.error('[마이그레이션] 오류:', error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

/**
 * 베타 대기목록 등록 (Callable)
 * - 트랜잭션으로 동시 요청 시에도 중복 등록 방지
 * - 이미 등록된 이메일이면 { status: 'already_registered' } 반환
 * - 신규 등록이면 { status: 'success' } 반환
 */
exports.addToWaitlist = functions.https.onCall(async (data) => {
  const email = data?.email;
  if (!email || typeof email !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', '이메일을 입력해 주세요.');
  }

  const normalized = email.trim().toLowerCase();
  if (!normalized) {
    throw new functions.https.HttpsError('invalid-argument', '이메일을 입력해 주세요.');
  }

  try {
    const status = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(
        db.collection('waitlist').where('email', '==', normalized).limit(1)
      );
      if (!snapshot.empty) {
        return 'already_registered';
      }
      const ref = db.collection('waitlist').doc();
      transaction.set(ref, {
        email: normalized,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return 'success';
    });

    return { status };
  } catch (error) {
    console.error('[addToWaitlist] 오류:', error);
    throw new functions.https.HttpsError('internal', '등록에 실패했습니다. 다시 시도해 주세요.');
  }
});
