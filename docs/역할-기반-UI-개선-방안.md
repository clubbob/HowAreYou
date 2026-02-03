# 역할 기반 UI 개선 방안

## 현재 문제점

### 1. 홈 화면에 모든 기능이 노출됨
- **보호 대상자(subject)**가 "보호자 확인" 버튼을 볼 필요 없음
- **보호자(guardian)**가 "상태 알려주기" 버튼을 볼 필요 없을 수 있음
- UI가 복잡하고 혼란스러울 수 있음

### 2. PRD 원칙과의 불일치
- **PRD 7번**: "지정자는 사용자 응답 내역을 볼 수 없음"
- 하지만 현재 보호자 대시보드에서 응답 이력을 볼 수 있음 (PRD 비범위였지만 구현됨)

### 3. 역할 구분이 UI에 반영되지 않음
- `UserModel`에 `role` 필드가 있지만 홈 화면에서 활용하지 않음
- 모든 사용자가 동일한 화면을 봄

---

## 개선 방안

### 방안 1: 역할 기반 홈 화면 분리 (권장)

#### 보호 대상자 (subject)
**홈 화면 구성:**
- ✅ **"상태 알려주기"** 버튼 (메인)
- ✅ **"보호자 지정"** 버튼
- ❌ "보호자 확인" 버튼 숨김

**이유:**
- 보호 대상자는 자신의 상태를 알려주는 것이 주 목적
- 보호자 확인 기능은 불필요

#### 보호자 (guardian)
**홈 화면 구성:**
- ✅ **"보호자 확인"** 버튼 (메인)
- ❌ "상태 알려주기" 버튼 숨김 (또는 선택적)
- ❌ "보호자 지정" 버튼 숨김

**이유:**
- 보호자는 보호 대상자의 상태를 확인하는 것이 주 목적
- 자신의 상태를 알려줄 필요 없음 (선택적)

#### 둘 다 (both)
**홈 화면 구성:**
- ✅ **"상태 알려주기"** 버튼
- ✅ **"보호자 지정"** 버튼
- ✅ **"보호자 확인"** 버튼

**이유:**
- 자신도 보호 대상자이고, 다른 사람의 보호자이기도 함

---

### 방안 2: 탭 기반 네비게이션 (대안)

**하단 탭 구성:**
- **보호 대상자 탭**: 상태 알려주기, 보호자 지정
- **보호자 탭**: 보호 대상 목록, 상세 확인

**장점:**
- 역할이 명확히 구분됨
- 사용자가 쉽게 이해 가능

**단점:**
- UI 복잡도 증가
- both 역할 처리 복잡

---

## 권장 구현 방안

### 1단계: 역할 기반 홈 화면 분리 (방안 1)

**수정 파일:**
- `lib/screens/home_screen.dart`

**로직:**
```dart
Widget build(BuildContext context) {
  final authService = Provider.of<AuthService>(context);
  final userRole = authService.userModel?.role ?? UserRole.subject;
  
  return Scaffold(
    // ... AppBar ...
    body: _buildRoleBasedContent(userRole),
  );
}

Widget _buildRoleBasedContent(UserRole role) {
  switch (role) {
    case UserRole.subject:
      return _buildSubjectHome();
    case UserRole.guardian:
      return _buildGuardianHome();
    case UserRole.both:
      return _buildBothHome();
  }
}
```

**보호 대상자 화면:**
- "상태 알려주기" (큰 버튼)
- "보호자 지정" (작은 버튼)

**보호자 화면:**
- "보호자 확인" (큰 버튼)
- 또는 바로 보호 대상 목록 표시

**둘 다 화면:**
- 현재와 동일 (모든 버튼 표시)

---

### 2단계: 보호자 대시보드 접근 제한 (선택)

**PRD 원칙 준수:**
- 보호자 대시보드에서 응답 내역을 보지 않도록 수정
- 또는 PRD 업데이트 (실제 사용자 요구사항 반영)

**현재 상태:**
- 보호자 대시보드에서 7일 이력, 그래프 표시
- PRD에서는 "지정자는 사용자 응답 내역을 볼 수 없음"

**결정 필요:**
- PRD 원칙 유지 → 대시보드에서 응답 내역 제거
- 또는 실제 사용자 요구사항 반영 → PRD 업데이트

---

## 구현 예시

### home_screen.dart 수정

```dart
Widget _buildRoleBasedContent(UserRole role) {
  switch (role) {
    case UserRole.subject:
      return _buildSubjectHome();
    case UserRole.guardian:
      return _buildGuardianHome();
    case UserRole.both:
      return _buildBothHome();
  }
}

Widget _buildSubjectHome() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // "지금 어때?" 제목
      Text('지금 어때?', ...),
      
      // "상태 알려주기" 버튼 (큰 버튼)
      FilledButton.icon(
        onPressed: () => _navigateToQuestion(),
        label: const Text('상태 알려주기'),
        ...
      ),
      
      const SizedBox(height: 32),
      
      // "보호자 지정" 버튼
      OutlinedButton.icon(
        onPressed: () => Navigator.push(...),
        label: const Text('보호자 지정'),
        ...
      ),
      
      // "보호자 확인" 버튼은 표시하지 않음
    ],
  );
}

Widget _buildGuardianHome() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('보호 대상 확인', ...),
      
      // "보호자 확인" 버튼 (큰 버튼)
      FilledButton.icon(
        onPressed: () => Navigator.push(...),
        label: const Text('보호 대상 확인'),
        ...
      ),
      
      // 또는 바로 보호 대상 목록 표시
      // FutureBuilder로 보호 대상 목록 로드 후 표시
    ],
  );
}

Widget _buildBothHome() {
  // 현재와 동일 (모든 버튼 표시)
  return Column(...);
}
```

---

## 추가 고려사항

### 1. 역할 자동 감지
- 사용자가 보호자를 지정하면 `role`을 `both`로 업데이트?
- 또는 보호 대상 목록에 자신이 있으면 `both`로 판단?

### 2. 역할 변경
- 보호 대상자가 보호자를 추가하면 자동으로 `both`로 변경?
- 또는 수동으로 역할 선택?

### 3. 보호자 대시보드 접근
- 보호자 역할이면 홈 화면에서 바로 대시보드로 이동?
- 또는 버튼 클릭으로 이동?

---

## 결론

**권장 사항:**
1. ✅ **역할 기반 홈 화면 분리** (방안 1)
2. ✅ 보호 대상자: "상태 알려주기" + "보호자 지정"만
3. ✅ 보호자: "보호자 확인"만 (또는 바로 목록 표시)
4. ⚠️ 보호자 대시보드 접근 제한 여부 결정 필요

**다음 단계:**
1. `home_screen.dart` 수정하여 역할 기반 UI 구현
2. 역할 자동 감지 로직 추가 (선택)
3. 보호자 대시보드 접근 제한 결정 및 구현 (선택)
