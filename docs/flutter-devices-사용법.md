# flutter-devices 사용법

## 개요
`flutter devices` 명령어를 번호로 선택할 수 있게 해주는 스크립트입니다.

## 사용 방법

### PowerShell에서:
```powershell
.\flutter-devices.ps1
```

### CMD에서:
```cmd
flutter-devices.bat
```

## 실행 화면 예시

```
연결된 기기 확인 중...

Found 5 connected devices:

  [1] sdk gphone64 x86 64 (에뮬레이터)
      ID: emulator-5554
      플랫폼: android-x64
      버전: Android 14 (API 34)

  [2] sdk gphone64 x86 64 (에뮬레이터)
      ID: emulator-5556
      플랫폼: android-x64
      버전: Android 14 (API 34)

  [3] Windows (desktop)
      ID: windows
      플랫폼: windows-x64
      버전: Microsoft Windows [Version 10.0.18363.720]

  [4] Chrome (web)
      ID: chrome
      플랫폼: web-javascript
      버전: Google Chrome 144.0.7559.110

  [5] Edge (web)
      ID: edge
      플랫폼: web-javascript
      버전: Microsoft Edge 144.0.3719.104

============================================================

기기를 선택하세요 (1-5) 또는 Enter로 목록만 보기: 
```

번호를 입력하면 선택한 기기의 정보가 표시됩니다.

## 선택 후

선택한 기기 ID가 환경 변수 `FLUTTER_DEVICE_ID`에 저장되며, 다음 명령어로 앱을 실행할 수 있습니다:

```powershell
flutter run -d emulator-5554
```

## 기기별 역할

- **Pixel 6 (emulator-5554)**: 보호자
- **Pixel 7 (emulator-5556)**: 보호 대상자

## 다른 스크립트와의 차이

- **`flutter-devices.ps1`**: 모든 기기를 번호로 선택 (목록만 보기)
- **`run-select-device.ps1`**: 에뮬레이터만 선택하고 앱 실행 (EGL 로그 필터링 포함)

## 별칭 설정 (선택사항)

PowerShell 프로필에 다음을 추가하면 `flutter-devices`로 바로 실행할 수 있습니다:

```powershell
# PowerShell 프로필 편집: notepad $PROFILE
function flutter-devices {
    & "d:\project\HowAreYou\flutter-devices.ps1"
}
```
