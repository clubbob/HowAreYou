# GPT 검증용: 알림 서비스 구현 현황

## 1. 개요

**목표**: 앱이 백그라운드/종료 상태여도 매일 정해진 시간에 알림이 뜨도록, **서버 비용 0원**으로 구현.

| 구분 | ID | 시간(KST) | 문구 | 방식 |
|------|-----|-----------|------|------|
| 보호대상자 | 1 | 19:00 | 오늘 안부 남겨볼까요? | 로컬 알림 |
| 보호자 | 2 | 20:00 | 오늘 안부 확인하기 | 로컬 알림 |

- **기록/확인 여부와 무관**하게 무조건 매일 반복
- **3일 미응답 알림**: 미구현 (비용 절감으로 제거)

---

## 2. 아키텍처

### 2.1 역할 플래그 (rolesEnabled)

| 플래그 | SharedPreferences 키 | 설정 시점 |
|--------|----------------------|------------|
| subjectEnabled | roles_subject_enabled | SubjectModeScreen 진입 시 `true` |
| guardianEnabled | roles_guardian_enabled | GuardianModeScreen 진입 시 `true` |

- **lastSelectedMode**: 라우팅/초기 화면용만 사용, 스케줄 기준 아님
- **둘 다 true 가능**: 한 사람이 두 역할 동시 수행 시 id=1, id=2 둘 다 등록
- **로그아웃 시**: `ModeService.clearRoleFlags()` 호출

### 2.2 스케줄 호출 위치 (2곳만)

| 위치 | 시점 |
|------|------|
| auth_service | 로그인 또는 앱 시작 시 auth state 변경 (`user != null`) |
| _AppLifecycleHandler | 앱 포그라운드 복귀 시 (2초 디바운스) |

- SubjectModeScreen, GuardianModeScreen: **스케줄 호출 없음**, 역할 플래그만 설정
- Splash, Home: 스케줄 호출 없음

### 2.3 스케줄 로직

```
scheduleDailyRemindersByRole():
  if subjectEnabled → scheduleSubjectDailyReminder()  // id=1
  if guardianEnabled → scheduleGuardianDailyReminder() // id=2
  둘 다 false → 아무 것도 하지 않음 (취소도 안 함)
```

- id=1, id=2 **독립 등록** (서로 취소하지 않음)
- 예약 전 `cancel(id)` 후 스케줄 (중복 방지)
- `_nextTimeInKST(hour, minute)`: 정시 지났으면 내일로
- `matchDateTimeComponents: DateTimeComponents.time`: 매일 반복

---

## 3. 파일별 역할

| 파일 | 역할 |
|------|------|
| **lib/services/notification_service.dart** | 로컬 알림 스케줄/취소, 탭 핸들러, 테스트 발송 |
| **lib/services/mode_service.dart** | roles_subject_enabled, roles_guardian_enabled, lastSelectedMode, clearRoleFlags |
| **lib/services/auth_service.dart** | 로그인 시 scheduleDailyRemindersByRole, 로그아웃 시 cancelAll + clearRoleFlags |
| **lib/main.dart** | _AppLifecycleHandler: 포그라운드 복귀 시 2초 디바운스 후 scheduleDailyRemindersByRole |
| **lib/screens/subject_mode_screen.dart** | 진입 시 setSubjectEnabled(true) |
| **lib/screens/guardian_mode_screen.dart** | 진입 시 setGuardianEnabled(true) |
| **lib/screens/guardian_dashboard_screen.dart** | 안부 확인 탭: 카드 UX(오늘 기록 ✅/미기록 ⏳, 정렬) |
| **lib/screens/home_screen.dart** | 테스트 알림 버튼 2개 (보호대상자/보호자) |

---

## 4. 알림 탭 시 라우팅

| payload | 이동 화면 |
|---------|-----------|
| SUBJECT_REMINDER | QuestionScreen (컨디션 기록) |
| GUARDIAN_REMINDER | GuardianDashboardScreen (안부 확인 탭) |
| RESPONSE_RECEIVED\|subjectId 등 | GuardianDashboardScreen 또는 SubjectDetailScreen |

---

## 5. cancelAll / cancel(id)

| 메서드 | 사용처 |
|--------|--------|
| cancelAllNotifications() | **로그아웃 시에만** (auth_service) |
| cancel(1), cancel(2) | scheduleSubjectDailyReminder, scheduleGuardianDailyReminder 내부 |

- 알림 예약 경로에는 cancelAll 없음

---

## 6. 테스트 알림 (HomeScreen)

| 버튼 | 호출 | 문구 |
|------|------|------|
| 보호대상자 알림 | NotificationService.sendTestSubjectNotification() | 오늘 안부 남겨볼까요? |
| 보호자 알림 | NotificationService.sendTestGuardianNotification() | 오늘 안부 확인하기 |

- 3일 미응답 시뮬레이션: **제거됨** (기능 미구현)

---

## 7. 알림 권한 거부 시

| 화면 | 배너 문구 |
|------|-----------|
| SubjectModeScreen | 알림을 켜야 컨디션 기록 알림을 받을 수 있습니다. |
| GuardianModeScreen | 알림을 켜야 안부 확인 알림을 받을 수 있습니다. |

---

## 8. 한계·운영 체크포인트

| 케이스 | 동작 |
|--------|------|
| 19시/20시 이후 첫 실행 | 정시 지났으면 내일로 예약, 그날 알림 없음 |
| 폰 재부팅 | 앱 실행 시 scheduleDailyRemindersByRole 재확인 |
| 그날 앱 미실행 | 알림 없음 (로컬 알림 한계) |
| 로그아웃 | cancelAll + clearRoleFlags, 알림 모두 취소 |
| Android 13+ / 배터리 최적화 | 일부 기기에서 알림 누락 가능 |

---

## 9. 검증 포인트 (GPT용)

1. **rolesEnabled 기준**: lastSelectedMode가 아닌 subjectEnabled/guardianEnabled로 스케줄
2. **스케줄 2곳**: auth_service + _AppLifecycleHandler만
3. **id=1, id=2 독립**: 둘 다 true면 둘 다 등록, 서로 취소 안 함
4. **둘 다 false**: 아무 것도 하지 않음 (취소 안 함)
5. **cancelAll**: 로그아웃 시에만
6. **KST**: tz.setLocalLocation(Asia/Seoul), _nextTimeInKST 사용
7. **비용**: Cloud Functions, FCM 발송, Firestore 추가 스캔 없음
