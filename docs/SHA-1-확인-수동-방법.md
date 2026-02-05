# SHA-1 지문 수동 확인 방법

## 현재 상황
자동화된 방법들이 Java 환경 문제로 작동하지 않는 경우

## 가장 확실한 방법: Android Studio 사용

### 방법 1: Android Studio Terminal 사용 (권장)

1. **Android Studio 열기**
2. 프로젝트 열기: `d:\project\HowAreYou`
3. 하단 **Terminal** 탭 클릭
4. 다음 명령어 실행:

```powershell
cd android
.\gradlew signingReport
```

5. 출력에서 `SHA1:` 라인 찾기

### 방법 2: Android Studio Gradle 탭에서 검색

1. **Gradle** 탭 열기 (오른쪽 사이드바)
2. 상단 **검색 아이콘** 클릭
3. `signingReport` 입력
4. 검색 결과에서 `app` → `Tasks` → `android` → `signingReport` 더블클릭
5. 하단 **Run** 탭에서 결과 확인

### 방법 3: 직접 keytool 사용 (Android Studio JDK)

Android Studio의 Terminal에서:

```powershell
# Android Studio JDK 사용
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

출력에서 `SHA1:` 라인 찾기

## 출력 예시

정상적으로 실행되면:

```
Variant: debug
Config: debug
Store: C:\Users\사용자명\.android\debug.keystore
Alias: AndroidDebugKey
MD5: 12:34:56:78:90:AB:CD:EF:...
SHA1: A1:B2:C3:D4:E5:F6:... ← 이 값을 복사!
SHA-256: AA:BB:CC:DD:EE:FF:...
```

## 다음 단계

SHA-1 지문을 확인한 후:

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: **howareyou-1c5de**
3. 왼쪽 상단 **⚙️ 프로젝트 설정** 클릭
4. **내 앱** 섹션에서 Android 앱 선택
5. **SHA 인증서 지문** 섹션으로 스크롤
6. **지문 추가** 버튼 클릭
7. 확인한 **SHA-1** 지문 입력 (콜론 포함/제외 모두 가능)
8. **저장** 클릭

## 문제 해결

### Gradle 동기화가 안 되는 경우:
- **File** → **Sync Project with Gradle Files**
- 또는 **File** → **Invalidate Caches / Restart**

### 여전히 안 되는 경우:
Android Studio의 Terminal에서 직접 실행하는 것이 가장 확실합니다.
