# Firebase Android 앱 등록 및 SHA 지문 등록

> Release 빌드 및 Play Store 배포 전 필수 설정

---

## 1. key.properties 설정

### 1.1 파일 생성

`key.properties`가 없으면 다음 스크립트로 생성:

```powershell
cd android
.\setup-key-properties.ps1
```

또는 수동으로:

```powershell
cd android
Copy-Item key.properties.example key.properties
```

### 1.2 값 설정

`key.properties`를 열어 아래 항목을 실제 값으로 수정:

| 항목 | 설명 | 예시 |
|------|------|------|
| `storePassword` | Keystore 비밀번호 | 실제 비밀번호 |
| `keyPassword` | 키 비밀번호 (보통 storePassword와 동일) | 실제 비밀번호 |
| `keyAlias` | 키 별칭 | `upload` (고정) |
| `storeFile` | Keystore 파일 경로 (android/app 기준) | `../upload-keystore.jks` |

- `upload-keystore.jks`는 `docs\스토어-서명-키-준비.md` 참고해 먼저 생성
- `key.properties`는 `.gitignore` 대상 → Git에 커밋 금지
- **Keystore 비밀번호 오류** (`Keystore was tampered with...`) → [Keystore-비밀번호-오류-해결.md](./Keystore-비밀번호-오류-해결.md)

---

## 2. Firebase에 Android 앱 등록

### 2.1 Firebase Console 접속

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 **howareyou-1c5de** 선택
3. **프로젝트 설정** (톱니바퀴 아이콘) → **일반** 탭

### 2.2 Android 앱 추가

1. **내 앱** 섹션에서 **Android 앱 추가** (또는 **앱 추가** → Android)
2. **Android 패키지 이름** 입력: `com.andy.howareyou`
3. 앱 닉네임(선택): `HowAreYou` 등
4. **앱 등록** 클릭

### 2.3 google-services.json 다운로드

1. 등록 후 **google-services.json** 다운로드
2. `android/app/google-services.json`에 덮어쓰기

### 2.4 FlutterFire 설정 (선택)

```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

- `com.andy.howareyou` 앱 선택 → `lib/firebase_options.dart` 자동 생성

---

## 3. Release SHA-1 지문 등록

Play Integrity, reCAPTCHA, Firebase Auth 등이 Release 빌드에서 동작하려면 **Release SHA-1**을 Firebase에 등록해야 합니다.

### 3.1 Release SHA-1 확인

프로젝트 루트에서:

```powershell
.\get-release-sha1.ps1
```

- `key.properties`의 비밀번호를 자동 로드
- 출력된 SHA-1 지문을 복사

### 3.2 Firebase에 SHA-1 등록

1. [Firebase Console](https://console.firebase.google.com/) → 프로젝트 설정
2. **내 앱** → Android 앱 (`com.andy.howareyou`) 선택
3. **SHA 인증서 지문** 섹션으로 스크롤
4. **지문 추가** → SHA-1 선택
5. `get-release-sha1.ps1` 출력값 붙여넣기
6. **저장** 클릭

### 3.3 디버그 빌드용 (개발 시)

디버그 빌드에서 Firebase Auth 테스트 시 **디버그 SHA-1**도 등록:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
```

---

## 4. 체크리스트

| # | 작업 | 완료 |
|---|------|:----:|
| 1 | `android/upload-keystore.jks` 생성 | ☐ |
| 2 | `android/key.properties` 생성 및 비밀번호 설정 | ☐ |
| 3 | Firebase Console에서 Android 앱 `com.andy.howareyou` 등록 | ☐ |
| 4 | `google-services.json` 다운로드 → `android/app/` 배치 | ☐ |
| 5 | `.\get-release-sha1.ps1`로 Release SHA-1 확인 | ☐ |
| 6 | Firebase Console에 Release SHA-1 등록 | ☐ |
| 7 | `flutter build appbundle --release` 빌드 확인 | ☐ |

---

## 관련 문서

- `docs/스토어-서명-키-준비.md` — Keystore 생성
- `docs/Firebase-Application-ID-재연동-안내.md` — Application ID 변경 시
- `docs/Firebase-SHA-지문-등록-가이드.md` — SHA 지문 상세
