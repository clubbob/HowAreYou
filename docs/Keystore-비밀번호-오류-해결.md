# Keystore 비밀번호 오류 해결

> `Keystore was tampered with, or password was incorrect` 발생 시

---

## ⚠️ 원인 (맨 위에 확인)

**key.properties의 storeFile 경로가 실제 keystore 위치와 다르면** 같은 파일을 수정/삭제해도 계속 실패합니다. **먼저 storeFile이 가리키는 keystore를 확인하세요.**

---

## 1. 원인 진단 (추가 체크)

에러 메시지의 90%는 아래 둘 중 하나입니다.

| 원인 | 설명 |
|------|------|
| **경로 불일치** | `key.properties`가 읽는 파일과, 삭제/생성하는 파일이 서로 다름. 예: `android/`에서 만들었는데 `storeFile=../upload-keystore.jks` 같은 다른 경로를 보고 있음 |
| **비밀번호 불일치** | 키 비밀번호를 Enter로 동일하게 안 맞췄거나, `key.properties`에 다르게 적힘. **storePassword ≠ keyPassword** 이면 바로 이 에러가 나기 쉬움 |

✅ **새로 만들기**를 하더라도 반드시 `key.properties`의 **storeFile 경로부터 확정**해야 합니다.

---

## 2. 안전한 해결 절차 (첫 배포 전 기준, 추천 루트)

아래 순서 그대로 하면 거의 안 꼬입니다.

### A. key.properties 먼저 확인 (가장 중요)

`android/key.properties` 열어서 아래 4개가 어떻게 돼있는지 확인:

```
storeFile=...      ← 이 경로가 핵심
storePassword=...
keyAlias=...
keyPassword=...
```

✅ `storeFile`이 `upload-keystore.jks`를 **정확히** 가리키게 맞추세요.  
- 예: `storeFile=upload-keystore.jks` 이면 keystore는 `android/upload-keystore.jks` 여야 함  
- 예: `storeFile=../upload-keystore.jks` 이면 keystore는 `android/` 기준 상위(프로젝트 루트)에 있어야 함

### B. "그 경로의 keystore"를 삭제

`storeFile`이 가리키는 위치로 이동해서 삭제해야 합니다.

**⚠️ 삭제 실패 시 (Windows 파일 잠금)** — 다른 프로세스가 파일을 잡고 있으면 `del`이 실패합니다. 아래 순서로 파일 핸들 해제 후 삭제:

```powershell
cd D:\project\HowAreYou
.\android\gradlew.bat --stop
# 필요 시 (java.exe 전체 종료가 부담되면 gradlew --stop만 먼저 시도)
taskkill /F /IM java.exe
taskkill /F /IM studio64.exe

# 그 다음 삭제
cd android
del /F upload-keystore.jks
```

**예시1)** `storeFile=upload-keystore.jks` 라면:

```powershell
cd D:\project\HowAreYou\android
del /F upload-keystore.jks
```

**예시2)** `storeFile=../upload-keystore.jks` 라면:

```powershell
cd D:\project\HowAreYou\android
del /F ..\upload-keystore.jks
```

### C. 새 keystore 생성 (비번 통일 확실 버전)

```powershell
cd D:\project\HowAreYou\android
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

입력할 때:

- **Keystore password**: 예) `Hru2026!`
- **Key password**: **그냥 Enter** (keystore와 동일하게)
- 나머지(이름, 조직 등): Enter 또는 입력
- `맞습니까? [아니오]:` → **yes**

⚠️ **키 비밀번호를 따로 만들지 말고 그냥 Enter** 눌러서 동일하게 맞추세요.

### C-2. 생성 직후 즉시 검증 (필수)

생성 후 **바로** 아래 명령으로 keystore가 정상인지 확인. 실패하면 빌드 전에 중단.

```powershell
keytool -list -v -keystore android\upload-keystore.jks -alias upload
```

- 비밀번호 입력 후 출력 성공 → keystore 정상
- 실패 → 비번/경로/alias 문제. build 전에 수정 필요

### D. key.properties를 "동일 비번"으로 맞춤

```properties
storePassword=Hru2026!
keyPassword=Hru2026!
keyAlias=upload
storeFile=upload-keystore.jks
```

- `storeFile`은 B/C에서 사용한 **실제 keystore 경로**와 일치하게 설정
- `storePassword`와 `keyPassword`는 **반드시 동일**하게

### E. 바로 검증 (여기서 걸리면 100% 경로/비번 문제)

```powershell
cd D:\project\HowAreYou
flutter clean
flutter build appbundle --release
```

---

## 3. 이미 배포한 앱이면? (중요)

Play Console에 이미 **프로덕션/내부테스트/클로즈드/오픈** 중 어디든 한 번이라도 올렸다면:

- 같은 `applicationId`로 **업데이트**하려면 **기존 업로드 키(keystore)**가 반드시 필요
- 비번을 잃어버렸다면 우선 Play Console의 **App Signing** 상태를 확인해야 함  
  (Google Play App Signing을 켰는지 여부에 따라 **업로드 키 재설정** 경로가 달라짐)

**첫 배포 전**이라면 위 "새 keystore" 루트가 제일 빠릅니다.

---

## 4. 🔐 안전 규칙

| 규칙 | 설명 |
|------|------|
| **keyPassword = storePassword** | 두 비밀번호는 반드시 동일하게 유지 |
| **key.properties Git 금지** | `.gitignore`에 포함, 절대 커밋하지 말 것 |
| **keystore 백업** | USB + 클라우드 암호화 보관 (별도 백업 필수) |
| **첫 배포 후 재생성 금지** | Play Console 업로드 후 keystore 재생성 시 기존 앱 업데이트 불가 |

---

## 5. 실행 체크리스트 (리셋 시)

당장 할 순서:

1. **Android Studio / Cursor 완전 종료**
2. `.\android\gradlew.bat --stop` 실행
3. `android\upload-keystore.jks` 삭제
4. `.\scripts\keystore-reset.ps1` 실행
5. `keytool -list -v -keystore android\upload-keystore.jks -alias upload`로 생성 직후 검증
6. SHA-1 Firebase 등록 → google-services.json 재다운로드 → `android/app/`에 덮어쓰기
7. `flutter clean` → `flutter build appbundle --release`

**Play Console에 "내부 테스트"라도 업로드한 적 없으면** 지금 리셋 진행이 최적.  
**있으면** 리셋 시 업데이트 막히므로 경로를 바꿔야 함.

---

## 6. 관련 문서

- [스토어-서명-키-준비.md](./스토어-서명-키-준비.md) — 기본 keystore 생성
- [Firebase-Android-앱-등록-및-SHA-등록.md](./Firebase-Android-앱-등록-및-SHA-등록.md) — key.properties 설정

---

## 7. 경로 표준화 (v2)

`storeFile`은 **android/ 기준**으로 고정됩니다. `key.properties.example` 참고:

```properties
storeFile=upload-keystore.jks
```

- keystore 위치: `android/upload-keystore.jks`
- 빌드 시 `validateKeystore` 태스크가 파일 존재 여부를 자동 검증

**기존 `storeFile=../upload-keystore.jks` 사용 중이면** → `upload-keystore.jks`로 변경 필요.
