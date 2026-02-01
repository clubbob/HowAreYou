# Flutter 설치 가이드 (Windows)

## 1. Flutter SDK 다운로드

1. [Flutter 공식 사이트](https://docs.flutter.dev/get-started/install/windows) 접속
2. 최신 안정 버전(Stable) 다운로드
3. 원하는 위치에 압축 해제 (예: `C:\src\flutter`)

## 2. 환경 변수 설정

### PowerShell에서 설정 (관리자 권한)

```powershell
# 사용자 환경 변수에 추가
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")
```

또는 수동으로:

1. Windows 검색에서 "환경 변수" 검색
2. "시스템 환경 변수 편집" 선택
3. "환경 변수" 버튼 클릭
4. 사용자 변수 또는 시스템 변수에서 "Path" 선택
5. "편집" 클릭 → "새로 만들기" → Flutter bin 경로 추가 (예: `C:\src\flutter\bin`)
6. 확인 클릭

## 3. 설치 확인

새 PowerShell 창을 열고:

```bash
flutter doctor
```

필요한 추가 도구들이 표시됩니다:
- Android Studio (Android 개발용)
- Visual Studio (Windows 개발용, 선택사항)
- VS Code 또는 Android Studio (에디터)

## 4. Android Studio 설치 (Android 앱 개발용)

1. [Android Studio 다운로드](https://developer.android.com/studio)
2. 설치 중 Android SDK, Android SDK Platform, Android Virtual Device 포함
3. Flutter 플러그인 설치:
   - Android Studio → File → Settings → Plugins
   - "Flutter" 검색 후 설치 (Dart 플러그인도 자동 설치됨)

## 5. Android 라이선스 동의

```bash
flutter doctor --android-licenses
```

모든 라이선스에 "y" 입력

## 6. 설치 완료 확인

```bash
flutter doctor -v
```

모든 항목이 체크되어 있으면 완료!

## 7. 프로젝트 설정

Flutter 설치 후 프로젝트 디렉토리에서:

```bash
# 의존성 설치
flutter pub get

# Android 에뮬레이터 또는 실제 기기 연결 확인
flutter devices

# 앱 실행
flutter run
```

## 문제 해결

### Flutter 명령어를 찾을 수 없음

- PowerShell을 재시작하거나
- 환경 변수가 제대로 설정되었는지 확인:
  ```powershell
  $env:Path
  ```

### Android SDK를 찾을 수 없음

- Android Studio에서 SDK 경로 확인
- `local.properties` 파일에 SDK 경로 추가:
  ```
  sdk.dir=C\:\\Users\\USERNAME\\AppData\\Local\\Android\\Sdk
  flutter.sdk=C\:\\src\\flutter
  ```

### Gradle 오류

- Android Studio에서 Gradle 동기화
- 또는 `android/gradle/wrapper/gradle-wrapper.properties` 확인
