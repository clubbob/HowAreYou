# Keystore 리셋 실행 가이드

> ⚠️ **Play Console에 한 번도 업로드하지 않은 경우에만** 실행하세요.  
> 내부 테스트라도 올렸다면 **리셋 금지**.

---

## 현재 상태

- `key.properties` → `Hru2026!`, `storeFile=upload-keystore.jks` 로 이미 업데이트됨
- 기존 `upload-keystore.jks`는 **다른 프로세스에서 사용 중**이라 삭제되지 않았을 수 있음

---

## 실행 순서

### 0. 사전 확인 (필수)

1. **Android Studio** 완전 종료
2. **Cursor**에서 Gradle/빌드 중이면 중지
3. 터미널에서 `cd D:\project\HowAreYou`

### 1. 기존 keystore 삭제

```powershell
cd android
del upload-keystore.jks
```

- `다른 프로세스에서 사용 중` 오류 → 다른 앱/프로세스 종료 후 다시 실행

### 2. 새 keystore 생성

```powershell
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

입력:

- **Keystore password**: `Hru2026!`
- **Key password**: **Enter** (저장소 비밀번호와 동일)
- 나머지: Enter 또는 입력
- `맞습니까? [아니오]:` → **yes**

성공 시: `[Storing upload-keystore.jks]` 출력

### 3. SHA-1 추출

```powershell
cd ..
keytool -list -v -keystore android/upload-keystore.jks -alias upload -storepass "Hru2026!"
```

출력에서 `SHA1:` 줄 찾기 → Firebase Console → Android 앱 → SHA 인증서 지문에 추가

### 4. google-services.json 재다운로드

Firebase Console에서 다운로드 → `android/app/google-services.json` 덮어쓰기

### 5. 클린 빌드

```powershell
flutter clean
flutter build appbundle --release
```

---

## 스크립트 사용 (권장)

```powershell
cd D:\project\HowAreYou
.\scripts\keystore-reset.ps1
```

위 순서를 자동으로 진행합니다. 2단계에서만 비밀번호 입력이 필요합니다.
