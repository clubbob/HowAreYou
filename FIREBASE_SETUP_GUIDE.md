# Firebase 설정 가이드 (상세)

이 가이드는 Flutter 앱에 Firebase를 연결하는 전체 과정을 단계별로 설명합니다.

## 목차
1. [Firebase 프로젝트 생성](#1-firebase-프로젝트-생성)
2. [Android 앱 등록](#2-android-앱-등록)
3. [iOS 앱 등록 (선택사항)](#3-ios-앱-등록-선택사항)
4. [FlutterFire CLI 설치](#4-flutterfire-cli-설치)
5. [FlutterFire 설정](#5-flutterfire-설정)
6. [Firestore 데이터베이스 설정](#6-firestore-데이터베이스-설정)
7. [Authentication 설정](#7-authentication-설정)
8. [Cloud Messaging 설정](#8-cloud-messaging-설정)
9. [보안 규칙 설정](#9-보안-규칙-설정)
10. [테스트](#10-테스트)

---

## 1. Firebase 프로젝트 생성

### 1.1 Firebase Console 접속
1. 웹 브라우저에서 [Firebase Console](https://console.firebase.google.com/) 접속
2. Google 계정으로 로그인

### 1.2 새 프로젝트 추가
1. "프로젝트 추가" 또는 "Add project" 클릭
2. 프로젝트 이름 입력: `HowAreYou` (또는 원하는 이름)
3. "계속" 클릭

### 1.3 Google Analytics 설정 (선택사항)
1. Google Analytics 사용 여부 선택
   - 개발 단계에서는 비활성화해도 됨
   - 활성화하려면 Google Analytics 계정 선택 또는 새로 만들기
2. "프로젝트 만들기" 클릭

### 1.4 프로젝트 생성 완료 대기
- 몇 초 정도 소요됩니다
- 완료되면 "계속" 클릭

---

## 2. Android 앱 등록

### 2.1 Android 앱 추가
1. Firebase Console에서 프로젝트 선택
2. 프로젝트 개요 화면에서 Android 아이콘 클릭 (또는 "앱 추가" > "Android")
3. Android 패키지 이름 입력:
   ```
   com.example.how_are_you
   ```
   > **참고**: `android/app/build.gradle` 파일의 `applicationId`와 동일해야 합니다.

4. 앱 닉네임 입력 (선택사항): `지금 어때?`
5. 디버그 서명 인증서 SHA-1 (선택사항): 나중에 추가 가능
6. "앱 등록" 클릭

### 2.2 google-services.json 다운로드
1. "google-services.json 다운로드" 버튼 클릭
2. 파일을 다운로드합니다

### 2.3 google-services.json 파일 배치
1. 다운로드한 `google-services.json` 파일을 다음 위치에 복사:
   ```
   android/app/google-services.json
   ```
   > **중요**: `android/app/` 폴더에 직접 배치해야 합니다.

2. 파일이 올바른 위치에 있는지 확인:
   ```
   android/
   └── app/
       ├── build.gradle
       ├── google-services.json  ← 여기에 있어야 함
       └── src/
   ```

### 2.4 Android 프로젝트 설정 확인
`android/app/build.gradle` 파일을 열어서 다음이 있는지 확인:

```gradle
apply plugin: 'com.google.gms.google-services'
```

이미 추가되어 있어야 합니다. 없다면 파일 하단에 추가하세요.

---

## 3. iOS 앱 등록 (선택사항)

### ⚠️ 중요: iOS 앱 등록이 필요한 경우

**iOS 앱 등록이 필요한 경우:**
- iOS(iPhone/iPad)에도 앱을 배포할 계획이 있는 경우
- iOS 시뮬레이터나 실제 iOS 기기에서 테스트할 계획이 있는 경우

**iOS 앱 등록이 불필요한 경우:**
- Android만 배포할 계획인 경우
- Windows/웹만 사용할 계획인 경우
- 현재는 Android만 테스트할 계획인 경우

> **참고**: Flutter는 크로스 플랫폼 프레임워크이지만, Firebase는 각 플랫폼(Android, iOS, Web 등)별로 앱을 등록해야 합니다. 나중에 iOS 배포가 필요하면 그때 추가해도 됩니다.

iOS 개발을 하지 않는다면 이 단계는 건너뛰어도 됩니다.

### 3.1 iOS 앱 추가
1. Firebase Console에서 "앱 추가" > "iOS" 클릭
2. iOS 번들 ID 입력:
   ```
   com.example.howAreYou
   ```
3. 앱 닉네임 입력 (선택사항)
4. App Store ID (선택사항)
5. "앱 등록" 클릭

### 3.2 GoogleService-Info.plist 다운로드
1. "GoogleService-Info.plist 다운로드" 버튼 클릭
2. 파일을 다운로드합니다

### 3.3 GoogleService-Info.plist 파일 배치
1. Xcode에서 프로젝트 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. 다운로드한 `GoogleService-Info.plist` 파일을 `ios/Runner/` 폴더에 드래그 앤 드롭
3. "Copy items if needed" 체크
4. Runner 타겟에 추가 확인

---

## 4. FlutterFire CLI 설치

FlutterFire CLI는 Flutter 프로젝트에 Firebase 설정을 자동으로 연결해주는 도구입니다.

### 4.1 Dart Pub Global 활성화 확인
```bash
dart pub global activate flutterfire_cli
```

### 4.2 설치 확인
```bash
flutterfire --version
```

설치가 완료되면 버전이 표시됩니다.

---

## 5. FlutterFire 설정

### 5.1 Firebase 로그인
```bash
firebase login
```

브라우저가 열리면 Google 계정으로 로그인합니다.

### 5.2 프로젝트 디렉토리로 이동
```bash
cd D:\project\HowAreYou
```

### 5.3 FlutterFire 설정 실행
```bash
flutterfire configure
```

### 5.4 설정 과정
1. **Firebase 프로젝트 선택**
   - 목록에서 `HowAreYou` 프로젝트 선택
   - 방향키로 이동하고 Enter로 선택

2. **플랫폼 선택**
   - Android: `y` ✅ (필수 - 이미 등록했으므로)
   - iOS: `n` (iOS 배포 안 하면 건너뛰기)
   - Web: `n` (웹 배포 안 하면 건너뛰기)
   - Windows: `y` (Windows에서 테스트하려면, 선택사항)
   - macOS: `n` (macOS 배포 안 하면)
   - Linux: `n` (Linux 배포 안 하면)
   
   > **참고**: 
   > - Android는 이미 Firebase Console에서 등록했으므로 `y` 선택
   > - iOS는 나중에 배포할 계획이 있으면 그때 추가 가능
   > - Windows는 개발/테스트용으로 선택 가능 (실제 배포는 Android/iOS가 주 타겟)

3. **Android 패키지 이름 확인**
   - 기본값: `com.example.how_are_you`
   - 맞으면 Enter, 다르면 수정

4. **설정 완료**
   - `lib/firebase_options.dart` 파일이 자동 생성됩니다

### 5.5 생성된 파일 확인
```bash
# 파일이 생성되었는지 확인
cat lib/firebase_options.dart
```

파일이 생성되고 실제 Firebase 설정 값이 들어가 있어야 합니다.

---

## 6. Firestore 데이터베이스 설정

### 6.1 Firestore 생성
1. Firebase Console에서 "Firestore Database" 메뉴 클릭
2. "데이터베이스 만들기" 클릭

### 6.2 보안 규칙 선택
1. **테스트 모드로 시작** 선택 (개발 중)
   - 30일 후 자동으로 거부됩니다
   - 개발 중에는 이 모드로 시작

2. **위치 선택**
   - `asia-northeast3` (서울) 또는 가까운 지역 선택
   - "사용 설정" 클릭

### 6.3 데이터베이스 생성 완료
- 몇 분 정도 소요될 수 있습니다

---

## 7. Authentication 설정

### 7.1 Authentication 활성화
1. Firebase Console에서 "Authentication" 메뉴 클릭
2. "시작하기" 클릭

### 7.2 전화번호 인증 활성화
1. "Sign-in method" 탭 클릭
2. "전화번호" 또는 "Phone" 클릭
3. "사용 설정" 토글을 켜기
4. "저장" 클릭

### 7.3 테스트 전화번호 추가 (개발 중)
1. "전화번호" 인증 설정 화면에서
2. "테스트 전화번호" 섹션으로 스크롤
3. "전화번호 추가" 클릭
4. 테스트용 전화번호 입력 (예: `+82 10-1234-5678`)
5. 인증 코드 입력 (예: `123456`)
6. "추가" 클릭

> **참고**: 테스트 전화번호는 개발 중에만 사용합니다. 실제 SMS는 전송되지 않습니다.

---

## 8. Cloud Messaging 설정

### 8.1 Cloud Messaging 활성화
1. Firebase Console에서 "Cloud Messaging" 메뉴 클릭
2. 자동으로 활성화됩니다

### 8.2 서버 키 확인 (나중에 Cloud Functions에서 사용)
1. 프로젝트 설정 (톱니바퀴 아이콘) 클릭
2. "Cloud Messaging" 탭 클릭
3. "서버 키" 복사 (나중에 필요할 수 있음)

---

## 9. 보안 규칙 설정

### 9.1 Firestore 보안 규칙 설정
1. Firebase Console에서 "Firestore Database" > "규칙" 탭 클릭
2. 다음 규칙을 복사하여 붙여넣기:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 문서 - 본인만 읽기/쓰기 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 보호대상 문서
    match /subjects/{subjectId} {
      // 본인은 읽기/쓰기 가능
      allow read, write: if request.auth != null && request.auth.uid == subjectId;
      
      // 지정자는 읽기만 가능 (응답 내역은 볼 수 없음)
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.pairedGuardianUids;
      
      // 알림 문서
      match /alerts/{alertId} {
        allow read: if request.auth != null && 
          request.auth.uid in resource.data.guardianUids;
      }
      
      // 응답 문서 (prompts) - 지정자는 접근 불가
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

3. "게시" 클릭

---

## 10. 테스트

### 10.1 의존성 설치
```bash
flutter pub get
```

### 10.2 Android 앱 실행
```bash
flutter run
```

또는 특정 디바이스 지정:
```bash
flutter devices  # 사용 가능한 디바이스 확인
flutter run -d <device-id>
```

### 10.3 테스트 체크리스트
- [ ] 앱이 정상적으로 실행되는가?
- [ ] 로그인 화면이 표시되는가?
- [ ] 전화번호 인증이 작동하는가? (테스트 전화번호 사용)
- [ ] Firestore에 데이터가 저장되는가?
- [ ] 알림이 표시되는가? (Android)

---

## 문제 해결

### google-services.json 파일을 찾을 수 없음
- 파일이 `android/app/` 폴더에 있는지 확인
- 파일 이름이 정확히 `google-services.json`인지 확인 (대소문자 구분)

### Firebase 초기화 오류
```bash
# FlutterFire 재설정
flutterfire configure
```

### 패키지 이름 불일치
- `android/app/build.gradle`의 `applicationId` 확인
- Firebase Console의 패키지 이름과 일치하는지 확인

### 인증이 작동하지 않음
- Firebase Console에서 전화번호 인증이 활성화되었는지 확인
- 테스트 전화번호가 추가되었는지 확인 (개발 중)

### Firestore 접근 오류
- 보안 규칙이 올바르게 설정되었는지 확인
- 테스트 모드로 시작했는지 확인

---

## 다음 단계

Firebase 설정이 완료되면:
1. 앱을 실행하여 테스트
2. 실제 전화번호로 인증 테스트 (테스트 전화번호 외)
3. Firestore에 데이터 저장 테스트
4. Cloud Functions 설정 (미회신 판단 로직)

---

## 참고 자료

- [Firebase 공식 문서](https://firebase.google.com/docs)
- [FlutterFire 문서](https://firebase.flutter.dev/)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)
