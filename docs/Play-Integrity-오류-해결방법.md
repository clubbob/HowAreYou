# Play Integrity/reCAPTCHA 오류 해결 방법

## 오류 메시지
```
This request is missing a valid app identifier, meaning that Play Integrity checks, 
and reCAPTCHA checks were unsuccessful.
```

## 원인
이 오류는 Firebase Phone Authentication에서 Play Integrity와 reCAPTCHA 검사가 실패했을 때 발생합니다. 주로 **SHA-1/SHA-256 지문이 Firebase Console에 등록되지 않았을 때** 발생합니다.

## 해결 방법

### 방법 1: Gradle을 통한 SHA-1 지문 확인 (권장)

#### 1단계: Android Studio에서 확인
1. Android Studio 열기
2. 프로젝트 열기: `d:\project\HowAreYou\android`
3. 오른쪽 사이드바에서 **Gradle** 탭 클릭
4. `android` → `Tasks` → `android` → **signingReport** 더블클릭
5. 하단 **Run** 탭에서 출력 확인:
   ```
   Variant: debug
   Config: debug
   Store: C:\Users\사용자명\.android\debug.keystore
   Alias: AndroidDebugKey
   SHA1: A1:B2:C3:D4:E5:F6:... (이 값을 복사)
   SHA256: AA:BB:CC:DD:EE:FF:... (선택사항)
   ```

#### 2단계: Firebase Console에 등록
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: **howareyou-1c5de**
3. 왼쪽 상단 **⚙️ 프로젝트 설정** 클릭
4. **내 앱** 섹션에서 Android 앱 (`com.example.how_are_you`) 선택
5. **SHA 인증서 지문** 섹션으로 스크롤
6. **지문 추가** 버튼 클릭
7. 위에서 확인한 **SHA-1** 지문 입력 (콜론 포함 또는 제외 모두 가능)
   - 예: `A1:B2:C3:D4:E5:F6:...` 또는 `A1B2C3D4E5F6...`
8. **저장** 클릭

### 방법 2: 명령줄에서 확인 (Java 환경이 정상인 경우)

#### Windows PowerShell:
```powershell
cd android
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

출력에서 `SHA1:` 라인을 찾아 값을 복사하세요.

#### 또는 간단하게 SHA-1만:
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
```

### 방법 3: Flutter 명령어 사용

```powershell
cd d:\project\HowAreYou
flutter build apk --debug
```

빌드 후 출력에서 SHA-1 지문을 확인할 수 있습니다.

## 추가 확인 사항

### 1. google-services.json 파일 확인
- 파일 위치: `android/app/google-services.json`
- 파일이 최신인지 확인 (Firebase Console에서 다시 다운로드 가능)

### 2. 앱 패키지 이름 확인
- `android/app/build.gradle.kts` 또는 `android/app/build.gradle`에서 확인
- `applicationId`가 `com.example.how_are_you`인지 확인
- Firebase Console의 패키지 이름과 일치해야 함

### 3. 테스트 전화번호 확인
Firebase Console에서:
1. **Authentication** → **Sign-in method** → **전화번호**
2. **테스트 전화번호** 섹션 확인:
   - `+821011112222` / `111111` (보호자)
   - `+821033334444` / `333333` (보호 대상자)

## 적용 후 단계

SHA 지문을 등록한 후:

1. **앱 완전 재빌드:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

2. **에뮬레이터에서 앱 재설치:**
   ```powershell
   adb uninstall com.example.how_are_you
   flutter run
   ```

3. **다시 테스트:**
   - Pixel 6에서 `010-1111-2222` 입력
   - "인증 코드 전송" 클릭
   - 정상 작동하는지 확인

## 여전히 오류가 발생하는 경우

### 1. Firebase Console에서 앱 재등록
1. 프로젝트 설정 → 내 앱 → Android 앱 삭제
2. **앱 추가** → Android 선택
3. 패키지 이름: `com.example.how_are_you`
4. 앱 닉네임: `HowAreYou` (선택사항)
5. **앱 등록** 클릭
6. `google-services.json` 다운로드
7. `android/app/google-services.json` 교체
8. SHA-1 지문 다시 등록

### 2. Firebase 프로젝트 확인
- 프로젝트가 활성화되어 있는지 확인
- 결제 계정이 연결되어 있는지 확인 (Blaze 플랜 필요할 수 있음)

### 3. 네트워크 확인
- 에뮬레이터가 인터넷에 연결되어 있는지 확인
- Firebase 서비스에 접근 가능한지 확인

## 참고 자료
- [Firebase SHA 지문 등록 가이드](Firebase-SHA-지문-등록-가이드.md)
- [테스트 전화번호 설정](테스트-전화번호-설정.md)
