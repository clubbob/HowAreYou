# Android Studio 설치 가이드

Android Studio를 설치하면 Flutter 개발과 SHA-1 지문 확인이 더 쉬워집니다.

## 1. Android Studio 다운로드

1. **공식 웹사이트 접속**
   - https://developer.android.com/studio 접속
   - 또는 https://developer.android.com/studio/index.html

2. **다운로드 버튼 클릭**
   - "Download Android Studio" 버튼 클릭
   - Windows용 설치 파일 다운로드 (약 1GB)

## 2. Android Studio 설치

1. **설치 파일 실행**
   - 다운로드한 `.exe` 파일 실행
   - 관리자 권한이 필요할 수 있습니다

2. **설치 마법사 진행**
   - "Next" 클릭하여 기본 설정으로 설치
   - 설치 경로 확인 (기본: `C:\Program Files\Android\Android Studio`)

3. **설정 옵션**
   - "Android Virtual Device (AVD)" 체크 (에뮬레이터 사용 시)
   - "Android SDK" 자동 설치됨
   - "Android SDK Platform" 자동 설치됨

## 3. Android Studio 첫 실행 설정

1. **설정 가져오기**
   - "Do not import settings" 선택 (처음 설치 시)
   - "Next" 클릭

2. **설정 마법사**
   - "Standard" 설치 유형 선택 (권장)
   - "Next" 클릭

3. **SDK 구성 확인**
   - Android SDK 위치 확인
   - 기본: `C:\Users\사용자명\AppData\Local\Android\Sdk`
   - "Next" 클릭

4. **라이선스 동의**
   - 모든 라이선스에 동의
   - "Finish" 클릭

5. **SDK 다운로드 대기**
   - 필요한 SDK 컴포넌트 다운로드 (시간 소요)
   - 완료되면 "Finish" 클릭

## 4. Flutter 플러그인 설치

1. **플러그인 설정 열기**
   - File → Settings (또는 Ctrl+Alt+S)
   - Plugins 클릭

2. **Flutter 플러그인 설치**
   - "Marketplace" 탭 선택
   - "Flutter" 검색
   - "Install" 클릭
   - Dart 플러그인도 자동 설치됨

3. **Android Studio 재시작**
   - 플러그인 설치 후 재시작 필요

## 5. SHA-1 지문 확인하기

### 방법 1: Gradle을 통한 확인 (가장 쉬움)

1. **프로젝트 열기**
   - File → Open
   - `d:\project\HowAreYou\android` 폴더 선택

2. **Gradle 탭 열기**
   - 오른쪽 사이드바에서 "Gradle" 탭 클릭
   - 또는 View → Tool Windows → Gradle

3. **signingReport 실행**
   - `android` → `Tasks` → `android` → `signingReport` 더블클릭
   - 또는 터미널에서: `.\gradlew signingReport`

4. **SHA-1 확인**
   - 하단 "Run" 탭에서 출력 확인
   - 다음을 찾으세요:
     ```
     Variant: debug
     Config: debug
     Store: C:\Users\사용자명\.android\debug.keystore
     Alias: AndroidDebugKey
     SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
     ```
   - **SHA1:** 뒤의 값(콜론 포함)을 복사하세요

### 방법 2: 터미널에서 확인

Android Studio 하단 "Terminal" 탭에서:

```bash
cd d:\project\HowAreYou\android
.\gradlew signingReport
```

## 6. Firebase Console에 SHA-1 추가

1. Firebase Console → 프로젝트 설정 → 내 앱 → Android 앱 선택
2. "SHA 인증서 지문" 섹션으로 스크롤
3. "인증서 지문" 입력 필드에 SHA-1 값 붙여넣기
4. "SHA1" 버튼이 선택되어 있는지 확인
5. "저장" 버튼 클릭

## 7. Flutter 프로젝트 설정

### Android SDK 경로 확인

Android Studio에서:
1. File → Settings → Appearance & Behavior → System Settings → Android SDK
2. "Android SDK Location" 확인
3. 이 경로를 Flutter의 `local.properties`에 설정:

```properties
sdk.dir=C\:\\Users\\사용자명\\AppData\\Local\\Android\\Sdk
flutter.sdk=C\:\\src\\flutter
```

## 문제 해결

### Android Studio가 느린 경우:
- File → Settings → Appearance & Behavior → System Settings
- "Memory Settings"에서 힙 크기 증가

### Gradle 빌드 오류:
- File → Settings → Build, Execution, Deployment → Build Tools → Gradle
- "Gradle JDK"를 설치된 Java로 설정

### SHA-1을 찾을 수 없는 경우:
- 먼저 Flutter 빌드를 실행:
  ```bash
  cd d:\project\HowAreYou
  flutter build apk --debug
  ```

## 참고사항

- Android Studio는 Flutter 개발에 필수는 아니지만, 디버깅과 빌드에 유용합니다
- SHA-1 지문 확인 외에도 Android 에뮬레이터 실행, 네이티브 코드 디버깅 등에 사용됩니다
- Android Studio 없이도 Cursor/VS Code에서 Flutter 개발이 가능합니다
