# 프로젝트 설정 가이드

## 1. Flutter 프로젝트 초기화

프로젝트가 아직 Flutter 프로젝트로 초기화되지 않았다면 다음 명령어를 실행하세요:

```bash
flutter create .
```

## 2. Firebase 프로젝트 설정

### 2.1 Firebase Console에서 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 새 프로젝트 생성
3. 프로젝트 이름: "HowAreYou" 또는 원하는 이름

### 2.2 Android 앱 추가

1. Firebase Console에서 Android 앱 추가
2. 패키지 이름: `com.example.how_are_you` (또는 원하는 패키지 이름)
3. `google-services.json` 파일 다운로드
4. 파일을 `android/app/` 디렉토리에 복사

### 2.3 iOS 앱 추가 (선택사항)

1. Firebase Console에서 iOS 앱 추가
2. 번들 ID: `com.example.howAreYou` (또는 원하는 번들 ID)
3. `GoogleService-Info.plist` 파일 다운로드
4. 파일을 `ios/Runner/` 디렉토리에 복사

### 2.4 Firebase CLI로 설정 파일 생성

```bash
# Firebase CLI 설치 (없는 경우)
npm install -g firebase-tools

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 설정
flutterfire configure
```

이 명령어는 `lib/firebase_options.dart` 파일을 자동 생성합니다.

## 3. Firestore 데이터베이스 설정

1. Firebase Console에서 Firestore Database 생성
2. 테스트 모드로 시작 (개발 중)
3. 보안 규칙 설정:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 문서
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 보호대상 문서
    match /subjects/{subjectId} {
      allow read, write: if request.auth != null && request.auth.uid == subjectId;
      
      // 지정자는 읽기만 가능 (응답 내역은 볼 수 없음)
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.pairedGuardianUids;
      
      // 알림 문서
      match /alerts/{alertId} {
        allow read: if request.auth != null && 
          request.auth.uid in resource.data.guardianUids;
      }
      
      // 응답 문서 (지정자는 접근 불가)
      match /prompts/{promptId} {
        allow read, write: if request.auth != null && request.auth.uid == subjectId;
      }
    }
    
    // 알림 컬렉션
    match /alerts/{alertId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.guardianUids;
    }
  }
}
```

## 4. Firebase Authentication 설정

1. Firebase Console > Authentication > Sign-in method
2. 전화번호 인증 활성화
3. 테스트 전화번호 추가 (개발 중)

## 5. Firebase Cloud Messaging 설정

1. Firebase Console > Cloud Messaging
2. Android: 서버 키 확인 (나중에 Cloud Functions에서 사용)
3. iOS: APNs 인증 키 업로드 (필요한 경우)

## 6. 의존성 설치

```bash
flutter pub get
```

## 7. Android 추가 설정

### 7.1 최소 SDK 버전 확인

`android/app/build.gradle`에서 `minSdkVersion`이 21 이상인지 확인하세요.

### 7.2 알림 채널 설정

Android 8.0 이상에서는 알림 채널이 필요합니다. `NotificationService`에서 이미 설정되어 있습니다.

## 8. iOS 추가 설정 (선택사항)

### 8.1 알림 권한 설정

`ios/Runner/Info.plist`에 다음 추가:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 8.2 푸시 알림 Capability 추가

Xcode에서:
1. 프로젝트 열기: `open ios/Runner.xcworkspace`
2. Signing & Capabilities 탭
3. + Capability 클릭
4. Push Notifications 추가

## 9. 실행

```bash
# 디바이스 연결 확인
flutter devices

# 실행
flutter run
```

## 10. 다음 단계

- [ ] Firebase Cloud Functions 설정 (미회신 판단 로직)
- [ ] 테스트 코드 작성
- [ ] 앱 아이콘 및 스플래시 화면 설정
- [ ] 프로덕션 빌드 설정

## 문제 해결

### Firebase 초기화 오류

- `firebase_options.dart` 파일이 올바르게 생성되었는지 확인
- `google-services.json` 및 `GoogleService-Info.plist` 파일 위치 확인

### 알림이 작동하지 않음

- Android: 알림 권한이 허용되었는지 확인
- iOS: 푸시 알림 Capability가 추가되었는지 확인
- 로컬 알림: 시간대 설정 확인

### OTP 인증 실패

- Firebase Console에서 전화번호 인증이 활성화되었는지 확인
- 테스트 전화번호가 추가되었는지 확인 (개발 중)
