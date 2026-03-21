const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

const db = admin.firestore();

/** Google Play Android Publisher API 클라이언트 (서비스 계정 필요) */
function getAndroidPublisher() {
  const credsJson = process.env.PLAY_SERVICE_ACCOUNT_JSON || functions.config().play?.credentials;
  if (!credsJson) {
    throw new Error('PLAY_SERVICE_ACCOUNT_JSON 또는 functions.config().play.credentials 설정 필요');
  }
  const creds = typeof credsJson === 'string' ? JSON.parse(credsJson) : credsJson;
  const auth = new google.auth.GoogleAuth({
    credentials: creds,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return google.androidpublisher({ version: 'v3', auth });
}

/** 한국 시간(KST) 기준 오늘 날짜 yyyy-MM-dd (pairedAt 등 앱과 일치) */
function todayKoreaStr() {
  const koreaOffset = 9 * 60 * 60 * 1000;
  return new Date(Date.now() + koreaOffset).toISOString().slice(0, 10);
}

/** KST 오늘 00:00에 해당하는 Timestamp (lastResponseAt 조건 쿼리용) */
function todayMidnightKSTTimestamp() {
  const todayStr = todayKoreaStr();
  const [y, m, d] = todayStr.split('-').map(Number);
  // KST 00:00 = UTC 전날 15:00 (예: 2/7 00:00 KST = 2/6 15:00 UTC)
  const utcDate = new Date(Date.UTC(y, m - 1, d - 1, 15, 0, 0));
  return admin.firestore.Timestamp.fromDate(utcDate);
}

/** lastResponseAt이 없을 때 사용할 epoch (미기록 사용자 = 19시 푸시 대상) */
const EPOCH_TIMESTAMP = admin.firestore.Timestamp.fromDate(new Date(0));

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

/** 프리미엄 여부 판단 (subscriptionStatus + expiry) */
function isPremium(userData) {
  const status = (userData?.subscriptionStatus ?? '').toString().toLowerCase();
  const exp = userData?.subscriptionExpiry;
  if (status !== 'active' && status !== 'premium') return false;
  if (exp) {
    const expiryDate = exp.toDate ? exp.toDate() : (exp instanceof Date ? exp : new Date(exp));
    if (expiryDate < new Date()) return false;
  }
  return true;
}

/** 무료 플랜 보호대상자 제한 */
const FREE_GUARDIAN_SUBJECT_LIMIT = 2;

/**
 * 보호자가 보호대상자 추가 (Callable) - 서버 레벨 제한 적용
 * - subjectPhone 또는 subjectId로 대상 지정
 * - 트랜잭션: guardianSubjectCount + subscriptionStatus 확인
 * - 무료 + count >= 2면 reject
 */
exports.addGuardianToSubject = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }
  const guardianUid = context.auth.uid;
  const subjectId = data?.subjectId;
  const subjectPhone = data?.subjectPhone;
  const guardianPhone = (data?.guardianPhone ?? '').toString().trim();
  const guardianDisplayName = (data?.guardianDisplayName ?? '').toString().trim();

  let resolvedSubjectId = subjectId;
  if (!resolvedSubjectId && subjectPhone) {
    const normalized = normalizePhone(subjectPhone);
    if (!normalized) {
      throw new functions.https.HttpsError('invalid-argument', '전화번호를 입력해 주세요.');
    }
    const usersSnap = await db.collection('users').where('phone', '==', normalized).limit(1).get();
    if (usersSnap.empty) {
      throw new functions.https.HttpsError('failed-precondition',
        '이 분이 아직 앱에 가입하지 않았습니다. 가입하시면 자동으로 연결됩니다.');
    }
    resolvedSubjectId = usersSnap.docs[0].id;
  }
  if (!resolvedSubjectId || typeof resolvedSubjectId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'subjectId 또는 subjectPhone이 필요합니다.');
  }
  if (guardianUid === resolvedSubjectId) {
    throw new functions.https.HttpsError('invalid-argument', '본인 핸드폰 번호는 추가할 수 없습니다.');
  }

  const userRef = db.collection('users').doc(guardianUid);
  const subjectRef = db.collection('subjects').doc(resolvedSubjectId);

  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    const subjectSnap = await transaction.get(subjectRef);

    const userData = userSnap.exists ? userSnap.data() : {};
    const guardianSubjectCount = userData.guardianSubjectCount ?? 0;
    const premium = isPremium(userData);

    if (!premium && guardianSubjectCount >= FREE_GUARDIAN_SUBJECT_LIMIT) {
      throw new functions.https.HttpsError('resource-exhausted',
        '무료 플랜에서는 보호대상자 2명까지 등록할 수 있습니다. 3명 이상 추가를 원하시면 프리미엄 기능이 필요합니다.');
    }

    const existing = subjectSnap.exists ? subjectSnap.data() : {};
    const paired = [...(existing.pairedGuardianUids || [])];
    if (paired.includes(guardianUid)) {
      return { subjectId: resolvedSubjectId, alreadyAdded: true };
    }

    const infos = { ...(existing.guardianInfos || {}) };
    infos[guardianUid] = {
      phone: guardianPhone,
      displayName: guardianDisplayName,
      pairedAt: todayKoreaStr(),
    };
    paired.push(guardianUid);

    const subjectUpdate = {
      pairedGuardianUids: paired,
      guardianInfos: infos,
    };
    if (!subjectSnap.exists || !subjectSnap.data()?.lastResponseAt) {
      subjectUpdate.lastResponseAt = EPOCH_TIMESTAMP;
    }
    if (!subjectSnap.exists) {
      subjectUpdate.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }

    transaction.set(subjectRef, subjectUpdate, { merge: true });
    transaction.update(userRef, {
      guardianSubjectCount: admin.firestore.FieldValue.increment(1),
    });

    return { subjectId: resolvedSubjectId, alreadyAdded: false };
  });

  console.log('[addGuardianToSubject] 완료 subject=', resolvedSubjectId, 'guardian=', guardianUid);
  return result;
});

/**
 * 보호대상자(subject)가 보호자(guardian)를 초대 링크로 추가 (subject가 호출)
 * - subject = caller (context.auth.uid), guardianUid = 초대한 보호자
 */
exports.addGuardianToSubjectBySubjectInvite = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }
  const subjectUid = context.auth.uid;
  const guardianUid = data?.guardianUid;
  if (!guardianUid || typeof guardianUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'guardianUid가 필요합니다.');
  }
  if (subjectUid === guardianUid) {
    throw new functions.https.HttpsError('invalid-argument', '본인은 추가할 수 없습니다.');
  }

  const userRef = db.collection('users').doc(guardianUid);
  const subjectRef = db.collection('subjects').doc(subjectUid);

  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    const subjectSnap = await transaction.get(subjectRef);

    const userData = userSnap.exists ? userSnap.data() : {};
    const guardianSubjectCount = userData.guardianSubjectCount ?? 0;
    const premium = isPremium(userData);

    if (!premium && guardianSubjectCount >= FREE_GUARDIAN_SUBJECT_LIMIT) {
      throw new functions.https.HttpsError('resource-exhausted',
        '무료 플랜에서는 보호대상자 2명까지 등록할 수 있습니다. 3명 이상 추가를 원하시면 프리미엄 기능이 필요합니다.');
    }

    const existing = subjectSnap.exists ? subjectSnap.data() : {};
    const paired = [...(existing.pairedGuardianUids || [])];
    if (paired.includes(guardianUid)) {
      return { subjectId: subjectUid, alreadyAdded: true };
    }

    const guardianData = userSnap.exists ? userSnap.data() : {};
    const guardianPhone = (guardianData.phone ?? '').toString().trim();
    const subjectInputDisplayName = (data?.guardianDisplayName ?? '').toString().trim();
    const guardianDisplayName = subjectInputDisplayName || (guardianData.displayName ?? '').toString().trim();

    const infos = { ...(existing.guardianInfos || {}) };
    infos[guardianUid] = {
      phone: guardianPhone,
      displayName: guardianDisplayName,
      pairedAt: todayKoreaStr(),
    };
    paired.push(guardianUid);

    const subjectUpdate = {
      pairedGuardianUids: paired,
      guardianInfos: infos,
    };
    const subjectPhone = (data?.subjectPhone ?? '').toString().trim();
    const subjectDisplayName = (data?.subjectDisplayName ?? '').toString().trim();
    if (subjectPhone) subjectUpdate.phone = subjectPhone;
    if (subjectDisplayName) subjectUpdate.displayName = subjectDisplayName;
    if (!subjectSnap.exists || !subjectSnap.data()?.lastResponseAt) {
      subjectUpdate.lastResponseAt = EPOCH_TIMESTAMP;
    }
    if (!subjectSnap.exists) {
      subjectUpdate.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }

    transaction.set(subjectRef, subjectUpdate, { merge: true });
    transaction.update(userRef, {
      guardianSubjectCount: admin.firestore.FieldValue.increment(1),
    });

    return { subjectId: subjectUid, alreadyAdded: false };
  });

  console.log('[addGuardianToSubjectBySubjectInvite] 완료 subject=', subjectUid, 'guardian=', guardianUid);
  return result;
});

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
        const guardianUserSnap = await db.collection('users').doc(guardianUid).get();
        const guardianData = guardianUserSnap.exists ? guardianUserSnap.data() : {};
        const count = guardianData.guardianSubjectCount ?? 0;
        const premium = isPremium(guardianData);
        if (!premium && count >= FREE_GUARDIAN_SUBJECT_LIMIT) {
          console.log('[대기초대] 보호자 제한 초과 스킵 guardian=', guardianUid, 'count=', count);
          await doc.ref.delete();
          continue;
        }

        const subjectRef = db.collection('subjects').doc(uid);
        const subjectSnap = await subjectRef.get();
        const existing = subjectSnap.data() || {};
        const paired = [...(existing.pairedGuardianUids || [])];
        const infos = { ...(existing.guardianInfos || {}) };
        if (paired.includes(guardianUid)) {
          await doc.ref.delete();
          continue;
        }
        paired.push(guardianUid);
        const pairedAt = todayKoreaStr();
        infos[guardianUid] = {
          phone: data.guardianPhone || '',
          displayName: data.guardianDisplayName || '',
          pairedAt,
        };
        const setData = { pairedGuardianUids: paired, guardianInfos: infos };
        if (!subjectSnap.exists || !subjectSnap.data()?.lastResponseAt) {
          setData.lastResponseAt = EPOCH_TIMESTAMP;
        }
        if (!subjectSnap.exists) {
          setData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }
        await subjectRef.set(setData, { merge: true });
        await db.collection('users').doc(guardianUid).update({
          guardianSubjectCount: admin.firestore.FieldValue.increment(1),
        });
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
        const guardianUserSnap = await db.collection('users').doc(uid).get();
        const guardianData = guardianUserSnap.exists ? guardianUserSnap.data() : {};
        const count = guardianData.guardianSubjectCount ?? 0;
        const premium = isPremium(guardianData);
        if (!premium && count >= FREE_GUARDIAN_SUBJECT_LIMIT) {
          console.log('[대기초대] 보호자 제한 초과 스킵 guardian=', uid, 'count=', count);
          await doc.ref.delete();
          continue;
        }

        const subjectRef = db.collection('subjects').doc(subjectUid);
        const subjectSnap = await subjectRef.get();
        const existing = subjectSnap.data() || {};
        const paired = [...(existing.pairedGuardianUids || [])];
        const infos = { ...(existing.guardianInfos || {}) };
        if (paired.includes(uid)) {
          await doc.ref.delete();
          continue;
        }
        paired.push(uid);
        const pairedAt = todayKoreaStr();
        infos[uid] = { phone: guardianPhone, displayName: guardianDisplayName, pairedAt };
        const setData2 = { pairedGuardianUids: paired, guardianInfos: infos };
        if (!subjectSnap.exists || !subjectSnap.data()?.lastResponseAt) {
          setData2.lastResponseAt = EPOCH_TIMESTAMP;
        }
        if (!subjectSnap.exists) {
          setData2.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }
        await subjectRef.set(setData2, { merge: true });
        await db.collection('users').doc(uid).set(
          { guardianSubjectCount: admin.firestore.FieldValue.increment(1) },
          { merge: true }
        );
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
 * 보호자가 보호대상자 목록에서 자신을 제거 (Callable)
 * - guardianSubjectCount -1 업데이트 (트랜잭션)
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
    return { success: true };
  }

  const subjectRef = db.collection('subjects').doc(subjectId);
  const userRef = db.collection('users').doc(guardianUid);

  await db.runTransaction(async (transaction) => {
    // Firestore: 트랜잭션 내 모든 read를 먼저 수행한 뒤에만 write 가능
    const subjectSnap = await transaction.get(subjectRef);
    const userSnap = await transaction.get(userRef);

    if (!subjectSnap.exists) {
      throw new functions.https.HttpsError('not-found', '보호 대상 문서가 없습니다.');
    }

    const existing = subjectSnap.data() || {};
    const paired = [...(existing.pairedGuardianUids || [])].map((u) => String(u).trim());
    const g = String(guardianUid).trim();
    if (!paired.includes(g)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        '이미 연결이 해제되었거나 목록에 없는 보호 대상입니다.',
      );
    }

    const infos = { ...(existing.guardianInfos || {}) };
    delete infos[g];
    const newPaired = paired.filter((uid) => uid !== g);

    transaction.update(subjectRef, {
      pairedGuardianUids: newPaired,
      guardianInfos: infos,
    });

    const userData = userSnap.exists ? userSnap.data() : {};
    const count = userData.guardianSubjectCount ?? 0;
    if (count > 0) {
      transaction.update(userRef, {
        guardianSubjectCount: admin.firestore.FieldValue.increment(-1),
      });
    }
  });

  console.log('[removeGuardianFromSubject] 완료 subject=', subjectId, 'guardian=', guardianUid);
  return { success: true };
});

/**
 * 보호대상자(subject)가 보호자(guardian)를 자신의 목록에서 제거 (Callable)
 * - subject = caller (context.auth.uid), guardianUid = 제거할 보호자
 * - guardianSubjectCount -1 업데이트
 */
exports.removeGuardianFromSubjectBySubject = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }
  const subjectUid = context.auth.uid;
  const guardianUid = data?.guardianUid;
  if (!guardianUid || typeof guardianUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'guardianUid가 필요합니다.');
  }
  if (subjectUid === guardianUid) {
    return { success: true };
  }

  const subjectRef = db.collection('subjects').doc(subjectUid);
  const userRef = db.collection('users').doc(guardianUid);

  await db.runTransaction(async (transaction) => {
    const subjectSnap = await transaction.get(subjectRef);
    const userSnap = await transaction.get(userRef);

    if (!subjectSnap.exists) {
      throw new functions.https.HttpsError('not-found', '보호 대상 문서가 없습니다.');
    }

    const existing = subjectSnap.data() || {};
    const paired = [...(existing.pairedGuardianUids || [])].map((u) => String(u).trim());
    const g = String(guardianUid).trim();
    if (!paired.includes(g)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        '이미 연결이 해제되었거나 목록에 없는 보호자입니다.',
      );
    }

    const infos = { ...(existing.guardianInfos || {}) };
    delete infos[g];
    const newPaired = paired.filter((uid) => uid !== g);

    transaction.update(subjectRef, {
      pairedGuardianUids: newPaired,
      guardianInfos: infos,
    });

    const userData = userSnap.exists ? userSnap.data() : {};
    const count = userData.guardianSubjectCount ?? 0;
    if (count > 0) {
      transaction.update(userRef, {
        guardianSubjectCount: admin.firestore.FieldValue.increment(-1),
      });
    }
  });

  console.log('[removeGuardianFromSubjectBySubject] 완료 subject=', subjectUid, 'guardian=', guardianUid);
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
      const subjectRef = admin.firestore().collection('subjects').doc(subjectId);
      const subjectDoc = await subjectRef.get();
      if (!subjectDoc.exists) {
        return null;
      }

      const subjectData = subjectDoc.data();
      const guardianUids = subjectData.pairedGuardianUids || [];

      // 리셋 조건(필수): 보호대상자가 안부를 남기면
      // - 무이동(6/9/12h) 단계 초기화
      // - 무응답(72h) 단계 초기화 (lastNoResponseAlertAt)
      // - lastMovementAt 갱신 (앱 터치 = 이동으로 간주, 센서 보조용)
      await subjectRef.update({
        lastInactivityAlertAt: admin.firestore.FieldValue.delete(),
        lastInactivityAlertLevel: 0,
        lastNoResponseAlertAt: admin.firestore.FieldValue.delete(),
        lastMovementAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`[응답 알림] 보호 대상: ${subjectId}, 보호자 수: ${guardianUids.length}명`);
      if (guardianUids.length === 0) {
        console.log(`[응답 알림] 보호자가 없어 알림 발송하지 않음`);
        return null; // 보호자가 없으면 알림 불필요
      }

      // 보호 대상 이름 가져오기 (보호자가 저장한 표시 이름 우선)
      const subjectDisplayName = subjectData.displayName || '보호 대상';
      
      // 기록 알림 문구: 오늘 ○○님이 안부를 전했습니다
      const bodyText = `오늘 ${subjectDisplayName}님이 안부를 전했습니다`;

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
 * users 문서 업데이트 시: 새로 추가된 FCM 토큰을 다른 사용자 문서에서 제거 (토큰 이전)
 * - FCM 토큰은 기기 단위라, 같은 폰에서 A 로그아웃 후 B 로그인 시 같은 토큰이 B에 추가됨
 * - A 로그아웃 시 removeToken이 실패하면 A 문서에 토큰이 남아있을 수 있음
 * - B 로그인 시 토큰 저장 시 이 트리거가 다른 사용자(A) 문서에서 토큰을 제거함
 */
exports.onUserFcmTokensUpdated = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const before = change.before.data();
    const after = change.after.data();
    const beforeTokens = (before?.fcmTokens || []).filter(Boolean);
    const afterTokens = (after?.fcmTokens || []).filter(Boolean);
    const added = afterTokens.filter((t) => !beforeTokens.includes(t));
    if (added.length === 0) return null;

    for (const token of added) {
      try {
        const others = await db.collection('users')
          .where('fcmTokens', 'array-contains', token)
          .get();
        const refsToUpdate = others.docs.filter((d) => d.id !== userId);
        if (refsToUpdate.length === 0) continue;
        const batch = db.batch();
        for (const doc of refsToUpdate) {
          batch.update(doc.ref, { fcmTokens: admin.firestore.FieldValue.arrayRemove(token) });
          console.log(`[FCM 토큰 이전] ${doc.id}에서 토큰 제거 (${userId}로 이전)`);
        }
        await batch.commit();
      } catch (e) {
        console.error('[FCM 토큰 이전] 오류:', e);
      }
    }
    return null;
  });

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
 * subjects 문서 업데이트 시: lastMovementAt 갱신되면 알림 단계 리셋 (P0 치명 버그 방지)
 * - 12h 알림 후 움직임만 생기고 응답 없으면, (B) 단계 역행 방지 때문에 새 사이클 알림이 영원히 막히는 문제 해결
 * - "움직임이 생기면 새로운 사이클 시작"
 */
function toMs(ts) {
  if (!ts) return 0;
  return ts.toDate ? ts.toDate().getTime() : (ts instanceof Date ? ts.getTime() : 0);
}

exports.onSubjectUpdated = functions.firestore
  .document('subjects/{subjectId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const beforeMs = toMs(before?.lastMovementAt);
    const afterMs = toMs(after?.lastMovementAt);
    if (beforeMs === afterMs) return null;

    // 이미 0이면 update 호출하지 않음 (루프·불필요 write 방지)
    if (after?.lastInactivityAlertLevel === 0) return null;

    try {
      await change.after.ref.update({
        lastInactivityAlertAt: admin.firestore.FieldValue.delete(),
        lastInactivityAlertLevel: 0,
      });
      console.log(`[onSubjectUpdated] lastMovementAt 갱신 → 알림 단계 리셋 subjectId=${context.params.subjectId}`);
    } catch (e) {
      console.error('[onSubjectUpdated] 리셋 오류:', e);
    }
    return null;
  });

/**
 * 19:00 보호대상자 푸시 (생존 신호 기반 조건부)
 * - lastResponseAt < 오늘 00:00 → 당일 미기록 사용자만 조회 (전체 스캔 없음)
 */
exports.sendSubjectReminder = functions.pubsub
  .schedule('0 19 * * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const todayStr = todayKoreaStr();
    const todayStart = todayMidnightKSTTimestamp();
    console.log(`[19:00 보호대상자] ${todayStr} 실행, lastResponseAt < ${todayStart.toDate().toISOString()}`);

    try {
      const snapshot = await db.collection('subjects')
        .where('lastResponseAt', '<', todayStart)
        .get();

      const toSend = snapshot.docs;
      console.log(`[19:00 보호대상자] 발송 대상: ${toSend.length}명`);

      for (const doc of toSend) {
        const subjectId = doc.id;
        const r = await sendToUser(subjectId, {
          notification: { title: '', body: '오늘 어때요? 편안한 저녁 되세요.' },
          data: { type: 'DAILY_REMINDER', click_action: 'FLUTTER_NOTIFICATION_CLICK' },
          android: { priority: 'high', notification: { sound: 'default', channelId: 'daily_mood_check' } },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        });
        if (r.successCount > 0) console.log(`[19:00 보호대상자] ${subjectId} 발송 완료`);
      }
      return null;
    } catch (e) {
      console.error('[19:00 보호대상자] 오류:', e);
      return null;
    }
  });

/** 72h = 3일 (밀리초) */
const H72 = 72 * 60 * 60 * 1000;

/**
 * 3일 무응답 알림 (72h) — lastResponseAt만 기준, movement 무관
 * - 매일 20:05 실행
 * - lastNoResponseAlertAt으로 중복 방지
 * - 톤: 루틴/관계 알림 (부담 낮게)
 */
exports.sendThreeDayNoResponseAlert = functions.pubsub
  .schedule('5 20 * * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const now = Date.now();
    const seventyTwoHoursAgo = new Date(now - H72);
    const thresholdTs = admin.firestore.Timestamp.fromDate(seventyTwoHoursAgo);

    console.log(`[3일 무응답] 실행 ${new Date().toISOString()}, lastResponseAt < ${seventyTwoHoursAgo.toISOString()}`);

    try {
      const snapshot = await db.collection('subjects')
        .where('lastResponseAt', '<', thresholdTs)
        .get();

      let sentCount = 0;
      for (const doc of snapshot.docs) {
        const subjectId = doc.id;
        const data = doc.data();
        const lastResponseAt = data.lastResponseAt;
        const createdAt = data.createdAt;
        const lastNoResponseAlertAt = data.lastNoResponseAlertAt;
        const guardianUids = data.pairedGuardianUids || [];
        const displayName = data.displayName || '보호 대상';

        if (!lastResponseAt) continue;

        // 가입 72h 미만 스킵 (신규 사용자 과경보 방지)
        const createdAtMs = toMs(createdAt);
        if (createdAtMs > 0 && now - createdAtMs < H72) continue;

        // 중복 방지: lastNoResponseAlertAt이 최근 72h 이내면 스킵
        const lastAlertMs = toMs(lastNoResponseAlertAt);
        if (lastAlertMs > 0 && now - lastAlertMs < H72) continue;

        if (guardianUids.length === 0) continue;

        const body = '3일째 안부 기록이 없어요. 부담 없이 한 번 연락해보세요.';
        const title = '루틴 알림';

        for (const guardianUid of guardianUids) {
          const r = await sendToGuardian(guardianUid, {
            notification: { title, body: `${displayName}님: ${body}` },
            data: {
              type: 'NO_RESPONSE_ALERT',
              subjectId,
              subjectDisplayName: displayName,
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: { sound: 'default', channelId: 'guardian_notifications' },
            },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          });
          if (r.successCount > 0) {
            sentCount++;
            await db.collection('notification_requests').add({
              type: 'NO_RESPONSE_ALERT',
              subjectUid: subjectId,
              guardianUid,
              sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }

        await doc.ref.update({
          lastNoResponseAlertAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`[3일 무응답] ${subjectId} 발송 완료`);
      }

      console.log(`[3일 무응답] 완료, 총 ${sentCount}건 발송`);
      return null;
    } catch (e) {
      console.error('[3일 무응답] 오류:', e);
      return null;
    }
  });

/** 6h/9h/12h 기준 (밀리초) */
const H6 = 6 * 60 * 60 * 1000;
const H9 = 9 * 60 * 60 * 1000;
const H12 = 12 * 60 * 60 * 1000;
const H3 = 3 * 60 * 60 * 1000; // 같은 단계 재발송 방지: 3h 이내 스킵

/** 센서 비정상: lastMovementAt이 24h 이상 오래되면 lastResponseAt 보조로 전환 (오탐 방지) */
const MOVEMENT_STALE_HOURS = 24;
const MOVEMENT_STALE_MS = MOVEMENT_STALE_HOURS * 60 * 60 * 1000;

/**
 * 프리미엄 실시간 무활동 알림 (6h/9h/12h 단계)
 * - 30분마다 실행, lastMovementAt(핸드폰 이동) 우선, 없거나 24h 이상 오래되면 lastResponseAt(앱 기록) 보조
 * - 프리미엄 보호자에게만 발송 (무료 보호자 절대 발송 금지)
 */
exports.sendPremiumInactivityAlert = functions.pubsub
  .schedule('*/30 * * * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const now = Date.now();
    const sixHoursAgo = new Date(now - H6);
    const sixHoursAgoTs = admin.firestore.Timestamp.fromDate(sixHoursAgo);

    console.log(`[무활동 알림] 실행 ${new Date().toISOString()}, lastMovementAt/lastResponseAt < ${sixHoursAgo.toISOString()}`);

    try {
      // 1) lastResponseAt < 6h (앱 기록 없음)
      const snapByResponse = await db.collection('subjects')
        .where('lastResponseAt', '<', sixHoursAgoTs)
        .get();
      // 2) lastMovementAt < 6h (핸드폰 이동 없음) - lastMovementAt 있는 문서만
      let snapByMovement;
      try {
        snapByMovement = await db.collection('subjects')
          .where('lastMovementAt', '<', sixHoursAgoTs)
          .get();
      } catch (e) {
        console.log('[무활동 알림] lastMovementAt 쿼리 스킵 (인덱스 없을 수 있음):', e.message);
        snapByMovement = { docs: [] };
      }

      const docMap = new Map();
      for (const doc of snapByResponse.docs) docMap.set(doc.id, doc);
      for (const doc of snapByMovement.docs) docMap.set(doc.id, doc);

      let sentCount = 0;
      for (const doc of docMap.values()) {
        const subjectId = doc.id;
        const data = doc.data();
        const lastResponseAt = data.lastResponseAt;
        const lastMovementAt = data.lastMovementAt;
        const lastInactivityAlertAt = data.lastInactivityAlertAt;
        const lastInactivityAlertLevel = data.lastInactivityAlertLevel ?? 0;
        const guardianUids = data.pairedGuardianUids || [];
        const displayName = data.displayName || '보호 대상';

        // 기준 시각: lastMovementAt 원칙, 없거나 센서 비정상(24h 이상) 시에만 lastResponseAt 보조
        const movementMs = lastMovementAt ? toMs(lastMovementAt) : 0;
        const movementStale = movementMs === 0 || (now - movementMs) > MOVEMENT_STALE_MS;
        const baseTs = !movementStale && lastMovementAt ? lastMovementAt : lastResponseAt;
        if (!baseTs) continue;
        const lastMs = baseTs.toDate ? baseTs.toDate().getTime() : baseTs;
        const inactiveMs = now - lastMs;

        // 현재 단계: 1=6h, 2=9h, 3=12h
        let currentStage = 0;
        if (inactiveMs >= H12) currentStage = 3;
        else if (inactiveMs >= H9) currentStage = 2;
        else if (inactiveMs >= H6) currentStage = 1;

        if (currentStage === 0) continue;

        // (B) 단계 역행 방지
        if (currentStage <= lastInactivityAlertLevel) continue;

        // (A) 같은 단계 재발송 방지
        if (lastInactivityAlertLevel === currentStage && lastInactivityAlertAt) {
          const lastAlertMs = lastInactivityAlertAt.toDate ? lastInactivityAlertAt.toDate().getTime() : lastInactivityAlertAt;
          if (now - lastAlertMs < H3) continue;
        }

        // 프리미엄 보호자만 필터
        const premiumGuardians = [];
        for (const uid of guardianUids) {
          const userSnap = await db.collection('users').doc(uid).get();
          const userData = userSnap.exists ? userSnap.data() : {};
          if (isPremium(userData)) premiumGuardians.push(uid);
        }

        if (premiumGuardians.length === 0) continue;

        // 무이동(6/9/12h): "안전 확인 필요(즉시)" 톤 — 72h와 의미 분리
        const typeByStage = { 1: 'INACTIVITY_6H', 2: 'INACTIVITY_9H', 3: 'INACTIVITY_12H' };
        const bodyByStage = {
          1: '6시간째 움직임이 없습니다. 안전 확인이 필요합니다.',
          2: '9시간째 움직임이 없습니다. 즉시 확인해 주세요.',
          3: '12시간째 움직임이 없습니다. 긴급 확인이 필요합니다.',
        };
        const body = bodyByStage[currentStage] || bodyByStage[1];

        for (const guardianUid of premiumGuardians) {
          const r = await sendToGuardian(guardianUid, {
            notification: { title: '안전 확인 필요', body: `${displayName}님: ${body}` },
            data: {
              type: 'INACTIVITY_ALERT',
              subjectId,
              subjectDisplayName: displayName,
              stage: String(currentStage),
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              priority: 'high',
              notification: { sound: 'default', channelId: 'guardian_notifications' },
            },
            apns: { payload: { aps: { sound: 'default', badge: 1 } } },
          });
          if (r.successCount > 0) {
            sentCount++;
            await db.collection('notification_requests').add({
              type: typeByStage[currentStage] || 'INACTIVITY_6H',
              subjectUid: subjectId,
              guardianUid,
              sentAt: admin.firestore.FieldValue.serverTimestamp(),
              stage: currentStage,
              baseAt: baseTs,
            });
          }
        }

        await doc.ref.update({
          lastInactivityAlertAt: admin.firestore.FieldValue.serverTimestamp(),
          lastInactivityAlertLevel: currentStage,
        });
        console.log(`[무활동 알림] ${subjectId} 단계${currentStage} 발송 완료`);
      }

      console.log(`[무활동 알림] 완료, 총 ${sentCount}건 발송`);
      return null;
    } catch (e) {
      console.error('[무활동 알림] 오류:', e);
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
    // subjects 문서 조회
    let batch = admin.firestore().batch();
    let batchCount = 0;
    let migratedCount = 0;
    const batchSize = 500; // Firestore 배치 제한
    
    const subjectsSnapshot = await admin.firestore().collection('subjects').get();
    console.log(`[마이그레이션] 전체 subjects 문서 수: ${subjectsSnapshot.size}`);
    
    for (const doc of subjectsSnapshot.docs) {
      const data = doc.data();
      const needsUpdate = {};
      if (!data.lastResponseAt) needsUpdate.lastResponseAt = EPOCH_TIMESTAMP;
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
 * guardianSubjectCount 마이그레이션 (배포 전 1회 실행)
 * - subjects의 pairedGuardianUids를 기반으로 각 보호자별 count 계산
 * - users/{guardianUid}.guardianSubjectCount 설정
 * 호출: ?key=migrate_guardian_count_2026
 */
exports.migrateGuardianSubjectCount = functions.https.onRequest(async (req, res) => {
  const adminKey = req.query.key;
  if (adminKey !== 'migrate_guardian_count_2026') {
    res.status(403).send('Unauthorized');
    return;
  }

  console.log('[마이그레이션 guardianSubjectCount] 시작');
  try {
    const countByGuardian = {};
    const subjectsSnap = await db.collection('subjects').get();
    for (const doc of subjectsSnap.docs) {
      const paired = doc.data()?.pairedGuardianUids || [];
      for (const uid of paired) {
        countByGuardian[uid] = (countByGuardian[uid] || 0) + 1;
      }
    }

    let updated = 0;
    let batch = db.batch();
    let batchCount = 0;
    const batchSize = 500;
    for (const [guardianUid, count] of Object.entries(countByGuardian)) {
      batch.set(db.collection('users').doc(guardianUid), { guardianSubjectCount: count }, { merge: true });
      batchCount++;
      updated++;
      if (batchCount >= batchSize) {
        await batch.commit();
        console.log(`[마이그레이션 guardianSubjectCount] 배치 커밋: ${updated}명`);
        batch = db.batch();
        batchCount = 0;
      }
    }
    if (batchCount > 0) await batch.commit();

    console.log(`[마이그레이션 guardianSubjectCount] 완료: ${updated}명`);
    res.status(200).json({ success: true, updatedCount: updated });
  } catch (error) {
    console.error('[마이그레이션 guardianSubjectCount] 오류:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/** 베타 선착순 제한 인원 */
const BETA_LIMIT = 100;

/**
 * 베타 대기목록 등록 (Callable)
 * - 선착순 BETA_LIMIT명까지 등록 가능
 * - 트랜잭션으로 동시 요청 시에도 중복 등록 방지
 * - 이미 등록된 이메일이면 { status: 'already_registered' } 반환
 * - 인원 마감 시 { status: 'full' } 반환
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

  const phone = data?.phone && typeof data.phone === 'string' ? data.phone.trim().replace(/\s/g, '') : null;

  try {
    const countSnap = await db.collection('waitlist').count().get();
    const count = countSnap.data().count;
    if (count >= BETA_LIMIT) {
      return { status: 'full' };
    }

    const status = await db.runTransaction(async (transaction) => {
      const existingSnapshot = await transaction.get(
        db.collection('waitlist').where('email', '==', normalized).limit(1)
      );
      if (!existingSnapshot.empty) {
        return 'already_registered';
      }
      const docData = {
        email: normalized,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      if (phone) docData.phone = phone;
      const ref = db.collection('waitlist').doc();
      transaction.set(ref, docData);
      return 'success';
    });

    return { status };
  } catch (error) {
    console.error('[addToWaitlist] 오류:', error);
    throw new functions.https.HttpsError('internal', '등록에 실패했습니다. 다시 시도해 주세요.');
  }
});

/**
 * Google Play 구독 검증 (Callable)
 * - 구매 성공 시 클라이언트가 purchaseToken 전송
 * - Play API로 검증 후 Firestore users/{uid} 갱신
 * - subscriptionStatus, subscriptionExpiry는 서버 전용 (클라이언트 쓰기 금지)
 */
exports.verifyPlaySubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }
  const uid = context.auth.uid;
  const productId = data?.productId;
  const purchaseToken = data?.purchaseToken;
  const packageName = data?.packageName || 'com.andy.howareyou';

  if (!productId || !purchaseToken || typeof productId !== 'string' || typeof purchaseToken !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'productId와 purchaseToken이 필요합니다.');
  }

  const validProductIds = ['premium_monthly', 'premium_yearly'];
  if (!validProductIds.includes(productId)) {
    throw new functions.https.HttpsError('invalid-argument', '유효하지 않은 상품 ID입니다.');
  }

  try {
    const androidPublisher = getAndroidPublisher();
    const result = await androidPublisher.purchases.subscriptions.get({
      packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    const data2 = result.data;
    const expiryTimeMillis = data2.expiryTimeMillis;
    if (!expiryTimeMillis) {
      console.error('[verifyPlaySubscription] 만료 시각 없음:', data2);
      return { success: false, error: '구독 정보를 확인할 수 없습니다.' };
    }

    const expiryDate = new Date(parseInt(expiryTimeMillis, 10));
    if (expiryDate <= new Date()) {
      return { success: false, error: '이미 만료된 구독입니다.' };
    }

    await db.collection('users').doc(uid).set({
      subscriptionStatus: 'premium',
      subscriptionExpiry: admin.firestore.Timestamp.fromDate(expiryDate),
      subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`[verifyPlaySubscription] ${uid} premium 활성화, 만료: ${expiryDate.toISOString()}`);
    return { success: true, expiryTimeMillis };
  } catch (e) {
    console.error('[verifyPlaySubscription] 오류:', e);
    if (e.code === 404 || (e.message && e.message.includes('404'))) {
      throw new functions.https.HttpsError('invalid-argument', '유효하지 않은 구매 정보입니다.');
    }
    throw new functions.https.HttpsError('internal', '구독 검증에 실패했습니다. 잠시 후 다시 시도해 주세요.');
  }
});

/**
 * 프리미엄 구독 만료 동기화 (매일 00:10 KST)
 * - subscriptionStatus=premium 이면서 subscriptionExpiry < now 인 사용자 → inactive 처리
 */
exports.syncPremiumExpiry = functions.pubsub
  .schedule('10 0 * * *')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const now = new Date();
    console.log(`[syncPremiumExpiry] 실행 ${now.toISOString()}`);

    try {
      const snapshot = await db.collection('users')
        .where('subscriptionStatus', 'in', ['premium', 'active'])
        .get();

      let updated = 0;
      const batch = db.batch();
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const exp = data.subscriptionExpiry;
        if (!exp) continue;
        const expiryDate = exp.toDate ? exp.toDate() : new Date(exp);
        if (expiryDate < now) {
          batch.update(doc.ref, {
            subscriptionStatus: 'inactive',
            subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          updated++;
        }
      }
      if (updated > 0) {
        await batch.commit();
        console.log(`[syncPremiumExpiry] ${updated}명 만료 처리`);
      }
      return null;
    } catch (e) {
      console.error('[syncPremiumExpiry] 오류:', e);
      return null;
    }
  });

/**
 * 관리자 FCM(ADMIN_BROADCAST) 열람 보고
 * - 앱에서 알림 탭 시 호출 → 해당 사용자 전화번호와 매칭되는 waitlist 항목에 lastFcmOpenedAt 업데이트
 */
exports.reportAdminFcmOpened = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', '로그인이 필요합니다.');
  }
  const uid = context.auth.uid;

  try {
    let userPhone = '';
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      userPhone = (userDoc.data()?.phone ?? '').toString().trim();
    }
    if (!userPhone) {
      const authUser = await admin.auth().getUser(uid);
      userPhone = (authUser.phoneNumber ?? '').toString().trim();
    }
    if (!userPhone) return { updated: 0 };
    const userNormalized = normalizePhone(userPhone);

    const now = admin.firestore.Timestamp.now();
    const batch = db.batch();

    // users/{uid}에 lastFcmOpenedAt 업데이트 (회원관리 페이지 표시용)
    batch.update(db.collection('users').doc(uid), { lastFcmOpenedAt: now });

    const waitlistSnap = await db.collection('waitlist').get();
    let updated = 0;
    for (const doc of waitlistSnap.docs) {
      const wlPhone = (doc.data()?.phone ?? '').toString().trim();
      if (!wlPhone) continue;
      if (normalizePhone(wlPhone) === userNormalized) {
        batch.update(doc.ref, { lastFcmOpenedAt: now });
        updated++;
      }
    }
    await batch.commit();
    return { updated };
  } catch (e) {
    console.error('[reportAdminFcmOpened] 오류:', e);
    throw new functions.https.HttpsError('internal', '열람 보고에 실패했습니다.');
  }
});
