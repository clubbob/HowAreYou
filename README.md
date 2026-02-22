# 오늘 어때? (How Are You?)

**부모님과 떨어져 살다 보니 괜히 마음 쓰이는 분을 위한 앱입니다.**

하루에 한 번, 보호대상자(부모님 등)가 "괜찮아/보통/별로"만 골라 주시면, 보호자(자녀 등)가 안부를 확인할 수 있게 돕습니다.

## 주요 기능

- **일일 상태 확인**: 아침(08:00), 점심(12:00), 저녁(18:00)에 알림으로 상태 확인
- **간단한 응답**: 5가지 이모지로 상태 선택
- **지정자 알림**: 일정 기간 응답이 없을 경우 지정자에게만 알림 발송
- **프라이버시 보호**: 사용자 응답 내역은 지정자에게 공유되지 않음

## 기술 스택

- **Flutter**: 크로스 플랫폼 앱 개발
- **Firebase Auth**: 전화번호 OTP 인증
- **Cloud Firestore**: 데이터 저장
- **Firebase Cloud Messaging**: 푸시 알림
- **flutter_local_notifications**: 로컬 알림

## 프로젝트 설정

### 0. Flutter 설치 (필요한 경우)

Flutter가 설치되어 있지 않다면:

1. [Flutter 공식 사이트](https://flutter.dev/docs/get-started/install)에서 Flutter SDK 다운로드
2. 압축 해제 후 원하는 위치에 배치
3. 환경 변수 PATH에 Flutter bin 디렉토리 추가
4. 설치 확인:
   ```bash
   flutter doctor
   ```

### 1. Flutter 프로젝트 초기화

프로젝트가 이미 생성되어 있지만, Flutter 명령어를 사용하려면:

```bash
flutter pub get
```

또는 처음부터 시작하려면:

```bash
flutter create .
```

### 2. Firebase 프로젝트 설정

1. [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 생성
2. Android/iOS 앱 추가
3. `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS) 파일 다운로드
4. Android: `android/app/google-services.json`에 배치
5. iOS: `ios/Runner/GoogleService-Info.plist`에 배치

### 3. Firebase 설정 파일 생성

프로젝트 루트에 `firebase_options.dart` 파일을 생성하거나 Firebase CLI를 사용:

```bash
flutterfire configure
```

### 4. 의존성 설치

```bash
flutter pub get
```

### 5. 실행

```bash
flutter run
```

**Android 에뮬레이터에서 EGL 로그가 반복될 때**

- **`flutter run`을 직접 실행하면 EGL 로그가 반복됩니다.** 아래 방법 중 하나만 사용하세요.
- **Cursor/VS Code**: **Ctrl+Shift+B** (빌드 작업) → EGL 로그 제외 실행
- **터미널**: `.\run-android.ps1` (PowerShell) 또는 `.\run.bat` (CMD/PowerShell)
- **디버그 실행(F5)** 시: 디버그 콘솔 필터에 `!EGL_emulation` 입력 시 해당 로그 숨김

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── user_model.dart
│   └── mood_response_model.dart
├── services/                 # 비즈니스 로직
│   ├── auth_service.dart
│   ├── mood_service.dart
│   └── notification_service.dart
└── screens/                  # 화면
    ├── splash_screen.dart
    ├── auth_screen.dart
    ├── home_screen.dart
    ├── question_screen.dart
    └── guardian_screen.dart
```

## 다음 단계

- [ ] Firebase Cloud Functions 설정 (미회신 판단 로직)
- [ ] FCM 푸시 알림 완전 구현
- [ ] 알림 설정 화면 (무음 모드)
- [ ] 테스트 코드 작성
