# Firebase DB·Auth 설정 정리 (이 앱 기준)

이 문서는 **지금 어때?** 앱과 맞추기 위한 Firebase Console 설정과 Firestore 규칙 요약입니다.

---

## 1. Authentication (전화번호 인증)

- **사용 방식**: 전화번호(Phone) 로그인만 사용합니다.
- **Console 설정**:
  1. [Firebase Console](https://console.firebase.google.com/) → 프로젝트 선택 → **Authentication**
  2. **Sign-in method** 탭에서 **전화번호(Phone)** 사용 설정을 **사용**으로 둡니다.
  3. **에뮬레이터/테스트**:
     - **전화번호** 영역에 테스트용 번호 등록 (예: `+82 10 3333 4444`)
     - 표시된 **인증 코드**를 앱에서 수동 입력해 로그인합니다.
     - **테스트 번호 목록** (Firebase Console → Authentication → Sign-in method → 전화번호 → 테스트 전화번호):
       - `+821011112222` → 인증 코드 `111111`
       - `+821033334444` → 인증 코드 `333333`
       - `+821055556666` → 인증 코드 `555555`
       - `+821077778888` → 인증 코드 `777777`
- **실기기**: 실제 SMS가 발송되며, 앱에서 자동 입력 또는 수동 입력으로 인증합니다.

---

## 2. Firestore 컬렉션 구조 (앱이 사용하는 것)

| 경로 | 용도 | 읽기 | 쓰기 |
|------|------|------|------|
| `users/{userId}` | 사용자 프로필, 전화번호, FCM 토큰, 보호자별 별칭(subjectLabels) | 본인 + 인증된 사용자(전화번호 조회용) | 본인만 |
| `subjects/{subjectUid}` | 보호대상자 문서 (pairedGuardianUids, guardianInfos, displayName, phone) | 본인 + 연결된 보호자 + 보호자 추가를 위해 인증 사용자 읽기 | 본인(전체) / 보호자(pairedGuardianUids 등만) |
| `subjects/{subjectUid}/prompts/{promptId}` | 일일 상태 응답 (아침/점심/저녁) | 보호대상자 본인 + 연결된 보호자 | 보호대상자 본인만 |
| `notification_requests/{requestId}` | 알림 요청 (Cloud Functions에서 소비) | 앱 읽기 불가 | 인증 사용자 생성만 |

- **알림**: 앱은 `notification_requests`에만 `add()`로 생성합니다. 실제 푸시는 Cloud Functions가 `users`의 `fcmTokens`를 보고 발송합니다.
- **alerts** 컬렉션은 현재 앱/함수에서 사용하지 않습니다. 규칙만 남겨 두었습니다.

---

## 3. Firestore 규칙 배포 (필수)

로컬에서 규칙을 수정한 뒤 **반드시 배포**해야 합니다.

```bash
firebase deploy --only firestore:rules
```

- 배포하지 않으면 기존 Console 규칙이 그대로 적용되어, 앱에서 permission-denied가 날 수 있습니다.
- 규칙 파일: 프로젝트 루트의 **`firestore.rules`**.

---

## 4. 규칙 요약 (firestore.rules와 일치)

- **users**
  - 본인: 읽기·쓰기
  - 그 외 인증 사용자: 읽기만 (보호자가 전화번호로 보호대상자 조회할 때 필요)
- **subjects**
  - 보호대상자 본인: 해당 문서 및 서브컬렉션 읽기·쓰기
  - 연결된 보호자: 해당 문서 및 `prompts` 읽기만
  - 보호자 추가 시: 본인이 아닌 인증 사용자가 해당 subject 문서를 읽을 수 있어야 하므로, “인증됨 + 본인 문서 아님”이면 읽기 허용
  - 쓰기: 보호자가 자신을 `pairedGuardianUids`에 넣고, 허용된 필드(pairedGuardianUids, guardianInfos, displayName, phone)만 변경
- **subjects/{id}/prompts**
  - 보호대상자 본인: 읽기·쓰기
  - 보호자: 부모 `subjects/{id}` 문서의 `pairedGuardianUids`에 자신이 포함된 경우에만 읽기 (규칙에서 `get()`으로 부모 문서 조회)
- **notification_requests**
  - 인증 사용자: `create`만 허용, 읽기·업데이트는 false (Functions 전용)

---

## 5. 체크리스트

- [ ] Authentication → 전화번호(Phone) 사용 설정 **사용**
- [ ] 에뮬레이터 사용 시 테스트 전화번호 + 인증 코드 등록·수동 입력
- [ ] `firestore.rules` 수정 후 `firebase deploy --only firestore:rules` 실행
- [ ] 앱에서 보호자 추가 시 permission-denied 나오면 → 위 배포 여부와 Console 규칙 탭 확인

이렇게 맞추면 이 앱의 Firebase DB·Auth 설정과 규칙이 일치합니다.
