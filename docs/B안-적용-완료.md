# B안(가족 공유형) 적용 완료 보고

## 적용 일시
2026-01-27

## 적용 내용

### 1. Firestore Rules 수정 ✅
**파일**: `firestore.rules`

**변경 사항**:
- 보호자도 `prompts` 컬렉션 읽기 가능하도록 수정
- `subjectUid = uid`로 통일 (이미 적용되어 있음)
- 보호자는 읽기만 가능, 쓰기 불가

**주요 규칙**:
```javascript
match /subjects/{subjectUid} {
  function isSubject() {
    return request.auth != null && request.auth.uid == subjectUid;
  }
  function isGuardian() {
    return request.auth != null
      && request.auth.uid in resource.data.pairedGuardianUids;
  }
  
  allow read, write: if isSubject();
  allow read: if isGuardian();
  
  match /prompts/{promptId} {
    allow read, write: if isSubject();
    allow read: if isGuardian(); // 보호자 읽기 허용
  }
}
```

### 2. FCM 토큰 정리 로직 수정 ✅
**파일**: `functions/index.js`

**변경 사항**:
- `sendToGuardian()` 헬퍼 함수 추가
- 보호자별로 별도 multicast 발송
- 실패한 토큰만 해당 보호자의 `users` 문서에서 `arrayRemove`
- `onResponseCreated`와 `checkUnreachableSubjects` 모두 적용

**주요 로직**:
```javascript
async function sendToGuardian(guardianUid, payload) {
  // 보호자별 토큰 조회
  const tokens = (userData?.fcmTokens || []).filter(Boolean);
  
  // 보호자별로 multicast 발송
  const response = await admin.messaging().sendEachForMulticast({
    ...payload,
    tokens: tokens,
  });
  
  // Invalid 토큰만 해당 보호자 문서에서 제거
  const invalidTokens = [];
  response.responses.forEach((resp, idx) => {
    if (!resp.success && invalidTokenErrors.has(resp.error?.code)) {
      invalidTokens.push(tokens[idx]);
    }
  });
  
  if (invalidTokens.length > 0) {
    await admin.firestore().collection('users').doc(guardianUid).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
    });
  }
}
```

### 3. Guardian 안내 문구 추가 ✅
**파일**: `lib/screens/guardian_dashboard_screen.dart`

**변경 사항**:
- 보호자 대시보드 최상단에 안내 문구 추가
- ChatGPT 제안 문구 적용: "이 앱은 응답 '내용'은 공유하지 않으며, 안부 확인 여부만 알려줍니다."

**UI 구조**:
```dart
Column(
  children: [
    // 안내 문구
    Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text('이 앱은 응답 "내용"은 공유하지 않으며, 안부 확인 여부만 알려줍니다.'),
          ),
        ],
      ),
    ),
    // 보호 대상 목록
    Expanded(child: FutureBuilder(...)),
  ],
)
```

### 4. 제품 원칙 문서 수정 ✅
**파일**: `HowAreYou_PRD_v1.0.md`

**변경 사항**:
- 핵심 원칙을 B안(가족 공유형) 기준으로 재작성
- "상태는 가족에게 '공유'되지만, 앱은 '감시/평가/세부 이력 추적'이 아니라 '안부 확인과 변화 감지'만 지원한다."
- 공유 범위 제한 명시 (7일까지만, 슬롯 기준만, 정확한 시각 공유 없음)
- 보호자 규칙 섹션 수정

## 확인 사항

### ✅ 완료된 항목
1. Firestore Rules 수정 (보호자 prompts 읽기 허용)
2. FCM 토큰 정리 로직 수정 (guardianUid별 처리)
3. Guardian 안내 문구 추가
4. 제품 원칙 문서 수정

### ⏳ 향후 작업 (선택 사항)
1. 보호자 추가 시 동의 UI 추가
   - 보호 대상자가 보호자 추가할 때 체크박스: "내 상태(최근 7일, 슬롯 기준)를 보호자에게 공유합니다."
   - 언제든 해제 가능 (연결 해제)

## 테스트 필요 사항

1. **Firestore Rules 테스트**
   - 보호 대상자 본인: prompts 읽기/쓰기 가능 확인
   - 보호자: prompts 읽기만 가능, 쓰기 불가 확인
   - 비연결 보호자: prompts 접근 불가 확인

2. **FCM 토큰 정리 테스트**
   - Invalid 토큰이 있을 때 자동 제거 확인
   - 여러 보호자 중 일부만 실패해도 정상 동작 확인

3. **UI 테스트**
   - Guardian 대시보드에 안내 문구 표시 확인
   - 보호자가 보호 대상자 상태 조회 가능 확인

## 참고 문서

- `docs/ChatGPT-피드백-검토.md`: ChatGPT 피드백 및 검토 내용
- `HowAreYou_PRD_v1.0.md`: 수정된 제품 원칙 문서
- `firestore.rules`: 수정된 Firestore Security Rules
- `functions/index.js`: 수정된 Cloud Functions 코드

---

**작성일**: 2026-01-27
