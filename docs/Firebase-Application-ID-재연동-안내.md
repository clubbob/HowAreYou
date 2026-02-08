# Firebase 재연동 안내 (Application ID 변경 후)

**배포 전: Firebase Android 앱 재등록 → google-services.json 교체 → flutterfire configure → release 빌드**

Android Application ID를 `com.andy.howareyou`로 변경한 뒤에는 Firebase와 다시 연동해야 합니다.

---

## 한 번에 따라 하기 (체크리스트)

| # | 할 일 | 비고 |
|---|--------|------|
| 1 | [Firebase Console](https://console.firebase.google.com/) 접속 → 프로젝트 **howareyou-1c5de** 선택 | 브라우저 |
| 2 | **프로젝트 설정** → **일반** → **Android 앱 추가** (패키지: `com.andy.howareyou`) | 기존 `com.example.how_are_you` 있으면 앱을 **추가**로 하나 더 등록 |
| 3 | **google-services.json** 다운로드 후 `android/app/google-services.json` 에 덮어쓰기 | 프로젝트 폴더 기준 |
| 4 | 터미널에서: `flutter pub global activate flutterfire_cli` | 한 번만 |
| 5 | 터미널에서: `flutterfire configure` → Android 앱 **com.andy.howareyou** 선택 | `lib/firebase_options.dart` 자동 생성 |
| 6 | `flutter clean` 후 `flutter build appbundle --release` | 빌드 성공 여부 확인 |

---

## 1. Firebase Console에서 Android 앱 등록

1. [Firebase Console](https://console.firebase.google.com/) → 프로젝트 **howareyou-1c5de** 선택
2. **프로젝트 설정** (휴지통 옆 톱니바퀴) → **일반** 탭
3. **내 앱**에서:
   - **방법 A**: 기존 Android 앱(`com.example.how_are_you`)이 있다면, **패키지 이름 변경**은 불가하므로 **Android 앱 추가**로 새로 등록
   - **방법 B**: 아직 Android 앱을 안 만들었다면 **Android 앱 추가** 후 패키지 이름에 `com.andy.howareyou` 입력
4. **앱 등록** 후 **google-services.json** 다운로드

---

## 2. google-services.json 교체

- Application ID 변경 후 **빌드가 되도록** 기존 `android/app/google-services.json`의 `package_name`을 `com.andy.howareyou`로 임시 수정해 두었습니다.
- **실제 배포/연동**을 위해 Firebase Console에서 패키지 `com.andy.howareyou`로 Android 앱을 추가한 뒤, 새로 받은 **google-services.json**으로 **`android/app/google-services.json`** 을 덮어쓰세요.
- 이 파일이 있어야 `flutter build appbundle` 시 Firebase가 정상 연동됩니다.

---

## 3. FlutterFire CLI로 firebase_options.dart 재생성

터미널에서 프로젝트 루트(`HowAreYou`)에서 실행:

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

- **flutterfire configure** 실행 시, 새 패키지명 `com.andy.howareyou` 기준으로 Android 앱을 선택하면 **lib/firebase_options.dart**가 자동 재생성됩니다.
- 재생성 후 `flutter run` / `flutter build appbundle --release` 로 동작을 한 번 확인하면 됩니다.

---

## 4. 요약 체크리스트

| 단계 | 작업 |
|------|------|
| 1 | Firebase Console에서 패키지 `com.andy.howareyou` 로 Android 앱 추가(또는 새로 등록) |
| 2 | **google-services.json** 다운로드 후 `android/app/google-services.json` 에 배치 |
| 3 | `flutterfire configure` 실행 → `lib/firebase_options.dart` 재생성 |
| 4 | `flutter clean` 후 `flutter build appbundle --release` 로 빌드 확인 |

---

**참고**: `google-services.json`은 프로젝트에 포함되어 있으면 Git에 커밋될 수 있습니다. 비공개 저장소가 아니면 `.gitignore`에 넣고, CI/배포 시에만 주입하는 방식도 고려하세요.
