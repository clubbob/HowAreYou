# 알림 4종 — 조건·내용 (GPT 검증용)

## 정리 표

| # | 알림명 | 수신자 | 발송 시각 | 발송 조건 | 제목 | 본문 |
|---|--------|--------|----------|----------|------|------|
| 1 | 컨디션 미등록 리마인드 | 보호대상자 | 매일 19:00 (KST) | `subjects.lastResponseAt` < 오늘 00:00 (당일 기록 없음) | (없음) | 오늘 하루는 어떠셨나요? |
| 2 | 보호자 기록 미등록 리마인드 | 보호자 | 매일 20:00 (KST) | 담당 보호대상자 중 `lastResponseAt` < 오늘 00:00 인 대상이 1명 이상 있음. 보호자당 1회만 발송. | 안부 확인 | 1명: 오늘 아직 1명의 안부가 도착하지 않았습니다.<br>N명: 오늘 아직 N명의 안부가 도착하지 않았습니다. |
| 3 | 보호자 기록 응답 | 보호자 | 이벤트 발생 시 | 보호대상자가 `prompts` 컬렉션에 새 문서 생성 또는 업데이트 시 (당일 컨디션 기록 완료 시) | 기록 알림 | ○○님이 오늘 안부를 남겼어요. |
| 4 | 보호자 3일 기록 미응답 | 보호자 | 매일 20:05 (KST) | `lastResponseAt` < now−72h AND `createdAt` < now−72h AND (`lastGuardianAlertAt` 없음 OR < now−72h) | 안부 확인 필요 | 3일째 1명의 안부가 확인되지 않았습니다. |

---

## 상세 (발송·표시 기준)

| # | Cloud Function 발송 | 앱 표시(사용자 노출) |
|---|---------------------|----------------------|
| 1 | title: `''`, body: `오늘 하루는 어떠셨나요?` | 동일 |
| 2 | title: `안부 확인`, body: 1명 `오늘 아직 1명의 안부가 도착하지 않았습니다.` / N명 `오늘 아직 N명의 안부가 도착하지 않았습니다.` | 동일 |
| 3 | title: `기록 알림`, body: `○○님이 컨디션을 기록 했습니다` | title: 동일, body: `○○님이 오늘 안부를 남겼어요.` *(Flutter에서 덮어씀)* |
| 4 | title: `안부 확인 필요`, body: `3일째 1명의 안부가 확인되지 않았습니다.` | 동일 |

---

## 트리거/스케줄

- **#1**: `sendSubjectReminder` (Cloud Scheduler 19:00)
- **#2**: `sendGuardianReminder` (Cloud Scheduler 20:00)
- **#3**: `onResponseCreated` / `onResponseUpdated` (Firestore `subjects/{id}/prompts/{id}`)
- **#4**: `sendThreeDayNoResponseAlert` (Cloud Scheduler 20:05)
