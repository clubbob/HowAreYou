# 빠른 시작 가이드

## Flutter가 설치되어 있는 경우

```bash
# 1. 의존성 설치
flutter pub get

# 2. Firebase 설정 (필수)
# SETUP.md 파일 참고하여 Firebase 프로젝트 설정

# 3. 앱 실행
flutter run
```

## Flutter가 설치되어 있지 않은 경우

1. **Flutter 설치**
   - `INSTALL_FLUTTER.md` 파일 참고
   - 또는 [공식 설치 가이드](https://docs.flutter.dev/get-started/install)

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **Firebase 설정**
   - `SETUP.md` 파일의 2번 항목부터 진행
   - Firebase Console에서 프로젝트 생성
   - `flutterfire configure` 실행

4. **앱 실행**
   ```bash
   flutter run
   ```

## 현재 프로젝트 상태

✅ **완료된 작업:**
- 프로젝트 구조 및 기본 파일 생성
- 주요 화면 구현 (인증, 홈, 질문, 지정자 관리)
- Firebase 서비스 클래스 구현
- 로컬 알림 설정
- FCM 푸시 알림 기본 설정

⏳ **다음 단계:**
1. Flutter 설치 (없는 경우)
2. Firebase 프로젝트 설정
3. `flutterfire configure` 실행
4. `google-services.json` 파일 추가
5. 앱 테스트

## 주요 파일 위치

- **앱 진입점**: `lib/main.dart`
- **화면**: `lib/screens/`
- **서비스**: `lib/services/`
- **모델**: `lib/models/`
- **Firebase 설정**: `lib/firebase_options.dart` (자동 생성 필요)

## 문제가 발생하면?

1. `SETUP.md` - Firebase 설정 가이드
2. `INSTALL_FLUTTER.md` - Flutter 설치 가이드
3. `README.md` - 프로젝트 개요
