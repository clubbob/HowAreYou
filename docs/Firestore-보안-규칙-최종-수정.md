# Firestore 보안 규칙 최종 수정

## 수정된 보안 규칙

보호자가 보호대상자를 추가할 수 있도록 보안 규칙을 수정했습니다.

### 주요 변경사항

1. **`canAddSelfAsGuardian()` 함수 추가**:
   - 보호자가 자신의 UID를 `pairedGuardianUids`에 추가할 수 있도록 허용
   - 본인 문서가 아니고, 자신을 추가하는 경우에만 허용
   - 문서가 없거나, 기존에 자신이 없는 경우 허용

2. **쓰기 권한 추가**:
   - 보호자가 자신을 `pairedGuardianUids`에 추가하는 경우 쓰기 허용
   - 변경 가능한 필드: `pairedGuardianUids`, `guardianInfos`, `displayName`만 허용

## 문제 해결 체크리스트

여전히 오류가 발생하는 경우 다음을 확인하세요:

### 1. Firebase Console에서 규칙 확인
1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택
3. **Firestore Database** → **규칙** 탭
4. 최신 규칙이 배포되었는지 확인

### 2. 앱 재시작
- 보안 규칙 변경 후 앱을 완전히 종료하고 다시 시작하세요

### 3. 로그인 상태 확인
- 보호자 모드에서 로그인되어 있는지 확인
- Firebase Authentication이 정상적으로 작동하는지 확인

### 4. 전화번호 형식 확인
- 보호대상자의 전화번호가 올바른 형식인지 확인
- `users` 컬렉션에 해당 전화번호로 가입된 사용자가 있는지 확인

### 5. 디버그 로그 확인
앱에서 다음 오류 메시지를 확인하세요:
- `permission-denied`: 보안 규칙 문제
- `not-found`: 사용자를 찾을 수 없음
- `already-exists`: 이미 등록된 보호자

## 수정된 보안 규칙 코드

```javascript
match /subjects/{subjectUid} {
  function isSubject() {
    return request.auth != null && request.auth.uid == subjectUid;
  }
  
  function isGuardian() {
    return request.auth != null
      && resource.data.pairedGuardianUids != null
      && request.auth.uid in resource.data.pairedGuardianUids;
  }
  
  function canAddSelfAsGuardian() {
    return request.auth != null
      && request.auth.uid != subjectUid  // 본인 문서가 아님
      && request.resource.data.pairedGuardianUids != null
      && request.auth.uid in request.resource.data.pairedGuardianUids  // 자신을 추가
      && (
        !resource.exists  // 문서가 없으면 허용 (새로 생성)
        || resource.data.pairedGuardianUids == null  // 기존 문서에 pairedGuardianUids가 없으면 허용
        || !(request.auth.uid in resource.data.pairedGuardianUids)  // 기존에 자신이 없으면 허용
      );
  }
  
  allow read, write: if isSubject();
  allow read: if isGuardian();
  
  allow write: if canAddSelfAsGuardian()
    && (
      !resource.exists  // 문서가 없으면 모든 필드 허용
      || request.resource.data.diff(resource.data).affectedKeys()
        .hasOnly(['pairedGuardianUids', 'guardianInfos', 'displayName'])  // 문서가 있으면 지정된 필드만
    );
}
```

## 추가 문제 해결

### 문제가 계속되는 경우

1. **Firebase Console에서 직접 규칙 확인**:
   - Firebase Console → Firestore Database → 규칙
   - 현재 배포된 규칙이 위 코드와 일치하는지 확인

2. **Firebase CLI로 다시 배포**:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **앱 완전 재시작**:
   - 앱을 완전히 종료
   - 에뮬레이터 재시작 (선택사항)
   - 앱 다시 실행

4. **Firebase 인증 상태 확인**:
   - 로그아웃 후 다시 로그인
   - Firebase Authentication이 정상 작동하는지 확인

## 관련 파일

- `firestore.rules`: Firestore 보안 규칙 파일
- `lib/services/guardian_service.dart`: 보호자 서비스 로직
- `lib/screens/guardian_dashboard_screen.dart`: 보호자 대시보드 화면
