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
