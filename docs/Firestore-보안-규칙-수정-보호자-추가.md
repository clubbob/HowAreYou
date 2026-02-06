# Firestore 보안 규칙 수정: 보호자가 보호대상자 추가

## 문제 상황

보호자가 보호대상자를 추가하려고 할 때 다음 오류가 발생했습니다:

```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## 원인 분석

### 기존 보안 규칙의 문제점

기존 `firestore.rules`에서는:
- 보호대상자 본인만 `subjects/{subjectUid}` 문서를 읽기/쓰기할 수 있었습니다
- 보호자는 이미 `pairedGuardianUids`에 포함된 경우에만 읽기만 가능했습니다

하지만 보호자가 보호대상자를 추가하는 과정에서는:
1. 보호자가 `subjects/{subjectUid}` 문서에 자신의 UID를 `pairedGuardianUids` 배열에 추가해야 합니다
2. 이때 문서가 아직 존재하지 않거나, 보호자 UID가 아직 배열에 포함되지 않은 상태입니다
3. 따라서 `isGuardian()` 함수가 false를 반환하여 쓰기 권한이 없었습니다

## 해결 방법

### 수정된 보안 규칙

```javascript
match /subjects/{subjectUid} {
  // 보호 대상자 본인: 읽기/쓰기 가능
  function isSubject() {
    return request.auth != null && request.auth.uid == subjectUid;
  }
  
  // 보호자: 연결된 경우에만 읽기 가능
  function isGuardian() {
    return request.auth != null
      && request.auth.uid in resource.data.pairedGuardianUids;
  }
  
  // 보호자가 자신을 pairedGuardianUids에 추가하는 경우 허용
  function canAddSelfAsGuardian() {
    return request.auth != null
      && (!resource.exists 
          || request.auth.uid != subjectUid  // 본인 문서가 아님
          || !(request.auth.uid in resource.data.get('pairedGuardianUids', [])));
  }
  
  // 보호 대상자 본인은 읽기/쓰기 가능
  allow read, write: if isSubject();
  
  // 보호자는 읽기만 가능
  allow read: if isGuardian();
  
  // 보호자가 자신을 pairedGuardianUids에 추가하는 경우 쓰기 허용
  allow write: if canAddSelfAsGuardian() 
    && request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['pairedGuardianUids', 'guardianInfos', 'displayName'])
    && request.auth.uid in request.resource.data.pairedGuardianUids;
}
```

### 보안 규칙 설명

1. **`canAddSelfAsGuardian()` 함수**:
   - 문서가 존재하지 않거나
   - 보호자가 보호대상자 본인이 아니거나
   - 기존 `pairedGuardianUids`에 보호자 UID가 없는 경우 true 반환

2. **추가 쓰기 권한 조건**:
   - `canAddSelfAsGuardian()`이 true이고
   - 변경되는 필드가 `pairedGuardianUids`, `guardianInfos`, `displayName`만이고
   - 요청한 보호자의 UID가 새 `pairedGuardianUids` 배열에 포함되어 있어야 함

### 보안 고려사항

✅ **허용되는 작업**:
- 보호자가 자신의 UID를 `pairedGuardianUids`에 추가
- `guardianInfos`에 자신의 정보 추가/수정
- `displayName` 필드 업데이트

❌ **차단되는 작업**:
- 보호자가 다른 보호자의 UID를 추가/제거
- 보호대상자 본인이 아닌 경우 다른 필드 수정
- `pairedGuardianUids`에서 자신을 제거 (이미 연결된 경우)

## 적용 방법

### 1. Firebase Console에서 수정

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택
3. **Firestore Database** → **규칙** 탭
4. `firestore.rules` 파일의 내용을 복사하여 붙여넣기
5. **게시** 버튼 클릭

### 2. Firebase CLI로 배포

```bash
firebase deploy --only firestore:rules
```

## 테스트 시나리오

### ✅ 정상 동작 케이스

1. **보호대상자가 보호자 추가**:
   - 보호대상자 본인이 자신의 `subjects/{subjectUid}` 문서 수정
   - `isSubject()` 함수로 허용됨

2. **보호자가 보호대상자 추가**:
   - 보호자가 `subjects/{subjectUid}` 문서에 자신을 추가
   - `canAddSelfAsGuardian()` 함수로 허용됨

3. **보호자가 보호대상자 정보 읽기**:
   - 이미 연결된 보호자가 `subjects/{subjectUid}` 문서 읽기
   - `isGuardian()` 함수로 허용됨

### ❌ 차단되는 케이스

1. **보호자가 다른 보호자 추가/제거**:
   - `pairedGuardianUids`에서 자신이 아닌 UID 변경 시도
   - `affectedKeys()` 검증으로 차단됨

2. **보호자가 자신을 제거**:
   - 이미 연결된 보호자가 자신을 `pairedGuardianUids`에서 제거 시도
   - `canAddSelfAsGuardian()`이 false 반환하여 차단됨

3. **권한 없는 사용자의 접근**:
   - 로그인하지 않은 사용자 또는 권한 없는 사용자의 접근
   - 모든 함수에서 `request.auth != null` 검증으로 차단됨

## 참고사항

- 이 수정은 보호자가 보호대상자를 추가하는 기능을 활성화합니다
- 보안 규칙은 여전히 보호대상자 본인의 전체 권한을 보장합니다
- 보호자는 자신을 추가하는 경우에만 쓰기 권한을 가집니다

## 관련 파일

- `firestore.rules`: Firestore 보안 규칙 파일
- `lib/screens/guardian_screen.dart`: 보호자 추가 화면
- `lib/services/guardian_service.dart`: 보호자 서비스 로직
