# 지금 어때 (HowAreYou) - 현재 구현 상태 (GPT 평가용)

> **목적**: GPT가 현재 구현의 로직·비즈니스·일관성·리스크를 평가할 수 있도록 정리한 문서입니다.
> 아래 내용을 복사해 GPT에 붙여넣고 "이 구현을 평가해주세요. 로직·리스크·개선점을 구체적으로 분석해주세요." 라고 요청하세요.

---

## 1. 서비스 개요

- **포지션**: 부모님 걱정을 줄여주는 일일 안부 확인 습관 앱
- **아님**: 긴급 알림·공포 유도 앱
- **역할**: 보호대상자(Subject) = 안부 기록, 보호자(Guardian) = 안부 확인
- **1대다**: 한 보호자가 여러 대상자, 한 대상자가 여러 보호자 가능

---

## 2. 기술 스택

- **앱**: Flutter (Dart)
- **백엔드**: Firebase (Auth, Firestore, Cloud Functions, FCM)

---

## 3. Firestore 구조

### subjects/{subjectUid}
- `pairedGuardianUids`: string[] — 보호자 UID 목록
- `guardianInfos`: map — { guardianUid: { phone, displayName, pairedAt } }
- `lastResponseAt`: Timestamp — 마지막 기록 시각
- `lastRecordedDate`: string — yyyy-MM-dd
- `currentStreak`, `longestStreak`: number
- `lastGuardianAlertAt`: Timestamp — 3일 무응답 알림 마지막 발송 시각
- **`createdAt`**: Timestamp (신규 subject 생성 시 serverTimestamp, 기존 문서에는 없음)

### subjects/{subjectUid}/prompts/{yyyy-MM-dd}
- slot, answeredAt, mood (1~5), note(선택)

---

## 4. 푸시 알림 (FCM) — 생존 신호 기반

| 시간(KST) | 대상 | 조건 | 문구 |
|-----------|------|------|------|
| **19:00** | 보호대상자 | `lastResponseAt < 오늘 00:00 KST` | "오늘 상태를 남겨주세요." |
| **20:00** | 보호자 | 동일 쿼리 → pairedGuardianUids 수집 → **보호자당 1회만** 발송 | "오늘 아직 신호가 없습니다." / "오늘 아직 신호가 없는 분이 N명 있습니다." |
| **20:05** | 보호자 | `lastResponseAt < now-72h` AND `createdAt < now-72h` AND (lastGuardianAlertAt 없음 또는 72h 이전) | "3일간 신호가 없습니다. 확인이 필요합니다." |

- **createdAt 조건**: 가입 72시간 미만이면 3일 경보 스킵 (신규 subject epoch 과경보 방지)
- **createdAt 없는 문서**: 스킵 (기존 유저 마이그레이션 전 안전)

---

## 5. 핵심 구현 상세

### 5.1 KST "오늘 00:00" 계산 (Cloud Functions)

```javascript
function todayMidnightKSTTimestamp() {
  const todayStr = todayKoreaStr();  // yyyy-MM-dd (KST)
  const [y, m, d] = todayStr.split('-').map(Number);
  const utcDate = new Date(Date.UTC(y, m - 1, d - 1, 15, 0, 0));  // KST 00:00 = UTC 전날 15:00
  return admin.firestore.Timestamp.fromDate(utcDate);
}
```

### 5.2 신규 subject 생성 시

- `lastResponseAt` = epoch (1970-01-01) → 19시/20시 미기록 대상
- **`createdAt` = serverTimestamp()** → 3일 경보는 가입 72h 이후부터만

생성 위치: auth_service, guardian_service, processPendingInvitesOnSignup

### 5.3 응답 삭제 (deleteTodayResponse)

- **prompts/{오늘}** 문서 삭제
- **subjects** 롤백: `lastResponseAt` = **오늘 00:00 KST - 1초**, `lastRecordedDate` 삭제, `currentStreak` = 0
- **epoch 금지**: epoch면 3일 무응답 즉시 트리거됨 → "오늘 00:00 - 1초" 사용

```dart
final todayStartKst = tz.TZDateTime(..., k.year, k.month, k.day, 0, 0, 0);
final yesterdayEndKst = todayStartKst.subtract(Duration(seconds: 1));
// lastResponseAt = yesterdayEndKst
```

### 5.4 20:00 보호자 푸시 — 보호자당 1회

```javascript
const guardianCounts = new Map();
for (const doc of snapshot.docs) {
  for (const uid of doc.data().pairedGuardianUids || []) {
    guardianCounts.set(uid, (guardianCounts.get(uid) || 0) + 1);
  }
}
for (const [guardianId, count] of guardianCounts) {
  const body = count > 1 ? `오늘 아직 신호가 없는 분이 ${count}명 있습니다.` : '오늘 아직 신호가 없습니다.';
  await sendToGuardian(guardianId, { ... });
}
```

### 5.5 3일 무응답 (20:05) — createdAt 필터

```javascript
for (const doc of snapshot.docs) {
  const d = doc.data();
  if (!d.createdAt || d.createdAt.toMillis() >= cutoff.toMillis()) continue;  // 신규/기존 skip
  // ... lastGuardianAlertAt 체크 ...
  toAlert.push(...);
}
```

---

## 6. FCM type → 앱 라우팅

| type | 화면 |
|------|------|
| DAILY_REMINDER | QuestionScreen |
| GUARDIAN_REMINDER | GuardianDashboardScreen |
| ESCALATION_3DAYS | SubjectDetailScreen (subjectId) 또는 GuardianDashboardScreen |
| RESPONSE_RECEIVED | SubjectDetailScreen 또는 GuardianDashboardScreen |

---

## 7. 보호자 대시보드 "오늘 기록" 판단

- **prompts 컬렉션** 존재 여부로 판단 (`getTodayResponses` → `today.values.any((r) => r != null)`)
- lastRecordedDate 미사용 → 삭제 시 롤백해도 UI 일관

---

## 8. 이미 완료된 보완 사항

- [x] deleteTodayResponse: prompts 삭제 + subjects 롤백 (트랜잭션)
- [x] lastResponseAt = 오늘 00:00 - 1초 (epoch → 3일 즉시 경보 방지)
- [x] subject 생성 시 createdAt 추가
- [x] 3일 무응답: createdAt 필터 (가입 72h 미만 스킵)
- [x] 20:00 보호자 푸시: 보호자당 1회 집계

---

## 9. 검증 체크리스트 (QA)

1. KST "오늘 00:00" 계산이 18:59/19:01, 23:59/00:01 경계에서 정확한가
2. lastResponseAt 없는 subject도 19시/20시 대상에 포함되는가
3. 20:00 보호자 푸시가 보호자당 1회인가
4. 오늘 기록 후 삭제 → 19시/20시 푸시 받고, 20:05 3일 경보는 받지 않는가
5. 신규 가입(당일~2일) → 20:05 3일 경보 안 받는가
6. 앱 종료 상태에서 푸시 탭 → 올바른 화면 이동하는가

---

## 10. GPT 평가 요청용 프롬프트

아래를 GPT에 붙여넣으세요:

---

```
[위 1~9 절 전체 내용]

위는 Flutter + Firebase 기반 "일일 안부 확인 앱"의 현재 구현 상태입니다.
다음을 구체적으로 평가해주세요:

1. **로직 일관성**: 푸시 조건·삭제 롤백·createdAt 설계가 서로 모순 없이 맞는지
2. **숨은 리스크**: 실제 서비스에서 자주 터지는 지점 (타임존, null, 경계, 폭탄 등)
3. **개선 제안**: 효과 대비 개발비가 작은 개선 3가지
4. **운영 지표**: 이 서비스를 "감이 아닌 데이터로" 운영하려면 어떤 지표 3개를 추적해야 하는지

한국어로 답변해주세요.
```

---

*작성일: 2026-02, 최근 변경 반영 (deleteTodayResponse 롤백, createdAt, 20:00 보호자당 1회)*
