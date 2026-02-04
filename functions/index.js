const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

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
      return { successCount: 0, failureCount: 0 };
    }

    const userData = userDoc.data();
    const tokens = (userData?.fcmTokens || []).filter(Boolean);
    
    if (tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    // FCM 메시지 발송
    const messagePayload = {
      ...payload,
      tokens: tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(messagePayload);

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
      if (guardianUids.length === 0) {
        return null; // 보호자가 없으면 알림 불필요
      }

      // 보호 대상 이름 가져오기
      const subjectDisplayName = subjectData.displayName || '보호 대상';
      
      // slot 값으로 시간대 라벨 결정
      const slot = promptData.slot || '';
      let slotLabel = '상태를';
      if (slot === 'morning') slotLabel = '아침';
      else if (slot === 'noon') slotLabel = '점심';
      else if (slot === 'evening') slotLabel = '저녁';

      // 보호자별로 알림 발송 (FCM 토큰 정리 포함)
      const sendPromises = guardianUids.map(async (guardianUid) => {
        return await sendToGuardian(guardianUid, {
          notification: {
            title: '상태 확인 알림',
            body: `${subjectDisplayName}님이 ${slotLabel} 상태를 확인했습니다`,
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
      
      console.log(`[응답 알림] ${subjectDisplayName}님 (${slotLabel}): ${totalSuccess}개 성공, ${totalFailure}개 실패`);
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
 * 미회신 판단 및 알림 발송 (매일 12:00 실행)
 * Cloud Scheduler로 호출
 */
exports.checkUnreachableSubjects = functions.pubsub
  .schedule('0 12 * * *') // 매일 12:00 (UTC 기준, 한국 시간으로는 21:00)
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    console.log('미회신 판단 시작:', new Date().toISOString());

    try {
      const db = admin.firestore();
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      // 어제 날짜 문자열 (YYYY-MM-DD)
      const yesterdayStr = yesterday.toISOString().split('T')[0];
      // 오늘 날짜 문자열
      const todayStr = today.toISOString().split('T')[0];

      // 모든 subjects 문서 조회
      const subjectsSnapshot = await db.collection('subjects').get();

      // 병렬 처리로 실행 시간 단축 (최적화)
      const checkPromises = subjectsSnapshot.docs.map(async (subjectDoc) => {
        const subjectId = subjectDoc.id;
        const subjectData = subjectDoc.data();
        const guardianUids = subjectData.pairedGuardianUids || [];

        if (guardianUids.length === 0) return null; // 보호자가 없으면 스킵

        // 어제(Day 1) 응답 확인 (병렬 처리)
        const [day1Morning, day1Noon, day1Evening, day2Morning] = await Promise.all([
          db.collection('subjects').doc(subjectId).collection('prompts').doc(`${yesterdayStr}_morning`).get(),
          db.collection('subjects').doc(subjectId).collection('prompts').doc(`${yesterdayStr}_noon`).get(),
          db.collection('subjects').doc(subjectId).collection('prompts').doc(`${yesterdayStr}_evening`).get(),
          db.collection('subjects').doc(subjectId).collection('prompts').doc(`${todayStr}_morning`).get(),
        ]);

        // 미회신 조건 확인
        const day1AllMissed = !day1Morning.exists && !day1Noon.exists && !day1Evening.exists;
        const day2MorningMissed = !day2Morning.exists;

        if (day1AllMissed && day2MorningMissed) {
          // 미회신 조건 충족 → 직접 알림 발송 (notification_requests 제거)
          const subjectDisplayName = subjectData.displayName || '보호 대상';
          
          // 보호자별로 알림 발송 (FCM 토큰 정리 포함)
          const sendPromises = guardianUids.map(async (guardianUid) => {
            return await sendToGuardian(guardianUid, {
              notification: {
                title: '연락 불가 알림',
                body: `${subjectDisplayName}님이 상태를 확인하지 않고 있습니다`,
              },
              data: {
                type: 'UNREACHABLE',
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
          console.log(`미회신 알림 발송: ${subjectId} (${subjectDisplayName}) - ${totalSuccess}개 성공`);
        }

        return null;
      });

      // 모든 체크를 병렬로 실행
      await Promise.all(checkPromises);

      console.log('미회신 판단 완료');
      return null;
    } catch (error) {
      console.error('미회신 판단 오류:', error);
      return null;
    }
  });
