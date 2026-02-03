# Cloud Functions 배포 가이드

## 개요

보호 대상이 응답할 때마다 보호자에게 알림을 보내고, 미회신 시에도 알림을 보내기 위해 Cloud Functions가 필요합니다.

## 기능

1. **응답 알림**: 보호 대상이 상태를 확인하면 보호자에게 "OO님이 아침 상태를 확인했습니다" 알림 발송
2. **미회신 알림**: PRD 기준 미회신 조건 충족 시 "OO님이 상태를 확인하지 않고 있습니다" 알림 발송

## 사전 요구사항

- Node.js 18 이상 설치
- Firebase CLI 설치 (`npm install -g firebase-tools`)
- Firebase 프로젝트에 Functions 활성화

## 배포 단계

### 1. Firebase CLI 로그인

```bash
firebase login
```

### 2. 프로젝트 디렉토리로 이동

```bash
cd d:\project\HowAreYou
```

### 3. Firebase 프로젝트 초기화 (처음 한 번만)

```bash
firebase init functions
```

선택 사항:
- 기존 프로젝트 선택 또는 새 프로젝트 생성
- 언어: JavaScript 선택
- ESLint: Yes (권장)
- 의존성 설치: Yes

### 4. Functions 디렉토리로 이동하여 의존성 설치

```bash
cd functions
npm install
```

### 5. Functions 배포

```bash
cd ..
firebase deploy --only functions
```

또는 특정 함수만 배포:

```bash
firebase deploy --only functions:processNotificationRequest
firebase deploy --only functions:checkUnreachableSubjects
```

## Functions 설명

### 1. processNotificationRequest

**트리거**: `notification_requests` 컬렉션에 새 문서 생성 시

**동작**:
1. 알림 요청 문서 읽기
2. 보호자들의 FCM 토큰 조회
3. FCM 메시지 발송 (소리 포함)
4. 요청 문서를 `processed: true`로 업데이트

### 2. checkUnreachableSubjects

**트리거**: 매일 12:00 (한국 시간) Cloud Scheduler

**동작**:
1. 모든 보호 대상(subjects) 조회
2. 미회신 조건 확인:
   - Day 1: 아침/점심/저녁 모두 미회신
   - Day 2: 아침 미회신
3. 조건 충족 시 `notification_requests`에 알림 요청 생성

## Firestore 컬렉션

### notification_requests/{requestId}

앱에서 알림 요청을 생성하면 Functions가 이를 처리합니다.

**필드**:
- `type`: 'RESPONSE_RECEIVED' | 'UNREACHABLE'
- `subjectId`: 보호 대상 UID
- `subjectDisplayName`: 보호 대상 이름
- `slot`: 'morning' | 'noon' | 'evening' (RESPONSE_RECEIVED만)
- `slotLabel`: '아침' | '점심' | '저녁' (RESPONSE_RECEIVED만)
- `guardianUids`: 보호자 UID 배열
- `message`: 알림 메시지
- `createdAt`: 생성 시각
- `processed`: 처리 여부 (boolean)
- `sentAt`: 발송 시각 (처리 후)
- `successCount`: 성공한 알림 수
- `failureCount`: 실패한 알림 수

## 테스트

### 로컬 테스트

```bash
cd functions
npm run serve
```

Firebase Emulator에서 테스트 가능합니다.

### 배포 후 테스트

1. 앱에서 보호 대상이 상태를 확인
2. Firebase Console → Functions → Logs에서 실행 로그 확인
3. 보호자 앱에서 알림 수신 확인

## 문제 해결

### 알림이 오지 않을 때

1. **FCM 토큰 확인**
   - Firebase Console → Firestore → users/{uid} → fcmTokens 배열 확인

2. **Functions 로그 확인**
   - Firebase Console → Functions → Logs

3. **알림 요청 문서 확인**
   - Firestore → notification_requests 컬렉션
   - `processed: false`인 문서가 있으면 Functions가 실행되지 않은 것

4. **알림 권한 확인**
   - 보호자 앱에서 알림 권한이 허용되어 있는지 확인

## 비용

- Cloud Functions: 무료 할당량 내에서 무료 (월 200만 호출)
- Cloud Scheduler: 무료 할당량 내에서 무료 (월 3개 작업)
- FCM: 무료

## 참고

- Functions 코드: `functions/index.js`
- 배포 명령어: `firebase deploy --only functions`
