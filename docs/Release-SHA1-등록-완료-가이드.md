# Release SHA-1 등록 완료 가이드

Release SHA-1을 Firebase에 등록하는 단계별 가이드입니다.

---

## 1단계: Release SHA-1 값 확인

프로젝트 루트에서 PowerShell 실행:

```powershell
cd d:\project\HowAreYou
.\get-release-sha1.ps1
```

- `key.properties`가 있으면 비밀번호를 자동으로 읽습니다.
- 없으면 실행 시 비밀번호 입력이 필요합니다 (key.properties의 storePassword).

**출력 예시:**
```
Release SHA-1 지문 (Firebase에 등록할 값):
AA:BB:CC:DD:EE:FF:...
```

위 값을 **복사**하세요.

---

## 2단계: Firebase Console에 등록

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 **howareyou-1c5de** (또는 해당 프로젝트) 선택
3. ⚙️ **프로젝트 설정** 클릭
4. **내 앱** 섹션에서 **Android 앱** (`com.andy.howareyou`) 선택
   - ⚠️ `com.example.how_are_you`가 아닌 `com.andy.howareyou` 앱을 선택하세요.
5. **SHA 인증서 지문** 섹션으로 스크롤
6. **디지털 지문 추가** (파란 링크) 클릭
7. **SHA-1** 라디오 버튼 선택
8. 1단계에서 복사한 값을 **인증서 지문** 입력란에 붙여넣기
9. **저장** 클릭

---

## 완료 확인

- SHA 인증서 지문 목록에 **2개**가 보이면 성공입니다.
  - Debug SHA-1: `89:C1:47:04:B6:F7:A4:17:...`
  - Release SHA-1: (방금 추가한 값)

---

## 문제 해결

### keytool을 찾을 수 없음
- `get-release-sha1.ps1`이 Eclipse Adoptium JDK 경로를 사용합니다.
- Java가 다른 경로에 있으면 `key.properties`와 동일한 폴더에 `keytool.exe` 경로를 수동으로 지정할 수 있습니다.

### 비밀번호 오류
- `android/key.properties`의 `storePassword`와 `keyPassword`를 확인하세요.
- keystore 생성 시 사용한 비밀번호와 일치해야 합니다.
