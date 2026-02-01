# 다음 단계 체크리스트

## ✅ 완료된 항목
- [x] Android 앱 등록 및 google-services.json
- [x] iOS 앱 등록 및 GoogleService-Info.plist
- [x] FlutterFire 설정 (firebase_options.dart)
- [x] 전화 인증 활성화 + 테스트 전화번호
- [x] SHA-1 인증서 지문 등록

---

## 🔲 지금 진행할 것

### 1. Firestore 데이터베이스 생성 (Firebase Console)
1. Firebase Console → **Firestore Database** 클릭
2. **데이터베이스 만들기** 클릭
3. **테스트 모드로 시작** 선택 (개발 중)
4. 위치: **asia-northeast3 (서울)** 선택
5. **사용 설정** 클릭
6. 생성 완료 후 **규칙** 탭에서 `firestore.rules` 내용 복사해 붙여넣기 → **게시**

### 2. Android 에뮬레이터 만들기 (PC에서 전화 인증 테스트용)
- **ANDROID_EMULATOR_GUIDE.md** 참고
- Android Studio → Device Manager → Create Device → Phone 선택 → 시스템 이미지 다운로드 → Finish → 재생 버튼으로 실행

### 3. 앱 실행 및 로그인 테스트
```bash
cd d:\project\HowAreYou
C:\src\flutter\bin\flutter pub get
C:\src\flutter\bin\flutter run
```
- **에뮬레이터를 먼저 실행한 뒤** `flutter run` 실행 (또는 Android 기기 USB 연결)
- 테스트 전화번호: `010-6391-4520`, 인증 코드: `123456`

### 4. (선택) Cloud Messaging
- Firebase Console → 프로젝트 설정 → Cloud Messaging
- 나중에 지정자 알림 구현 시 서버 키 등 확인

---

## 📁 참고 파일
- **ANDROID_EMULATOR_GUIDE.md** - Android 에뮬레이터 만들기 (PC에서 전화 인증 테스트)
- **firestore.rules** - Firestore 보안 규칙 (Console에 복사용)
- **FIREBASE_SETUP_GUIDE.md** - 전체 Firebase 설정 가이드
