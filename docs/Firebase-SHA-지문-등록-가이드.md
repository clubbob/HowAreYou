# Firebase SHA 지문 등록 가이드

## 문제 상황
"Play Integrity checks, and reCAPTCHA checks were unsuccessful" 오류가 발생하는 경우, SHA-1/SHA-256 지문이 Firebase Console에 등록되지 않았을 가능성이 높습니다.

## 해결 방법

### 1단계: SHA-1 지문 확인

#### Windows에서 디버그 키스토어의 SHA-1 지문 가져오기:

```powershell
cd android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

또는 간단하게 SHA-1만:

```powershell
cd android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
```

#### 출력 예시:
```
SHA1: A1:B2:C3:D4:E5:F6:...
SHA256: AA:BB:CC:DD:EE:FF:...
```

### 2단계: Firebase Console에 SHA 지문 등록

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택 (`howareyou-1c5de`)
3. 왼쪽 메뉴에서 **프로젝트 설정** (톱니바퀴 아이콘) 클릭
4. **내 앱** 섹션에서 Android 앱 선택
5. **SHA 인증서 지문** 섹션으로 스크롤
6. **지문 추가** 버튼 클릭
7. 위에서 확인한 **SHA-1** 지문 입력 (콜론 포함 또는 제외 모두 가능)
8. **저장** 클릭

### 3단계: google-services.json 다운로드 (필요시)

SHA 지문을 등록한 후, 필요하면:
1. Firebase Console → 프로젝트 설정 → 내 앱
2. Android 앱의 **google-services.json** 다운로드
3. `android/app/google-services.json` 파일 교체

### 4단계: 앱 재빌드 및 테스트

```powershell
flutter clean
flutter pub get
flutter run
```

## 프로덕션 키스토어의 경우

나중에 프로덕션 앱을 배포할 때는 릴리스 키스토어의 SHA 지문도 등록해야 합니다:

```powershell
keytool -list -v -keystore "경로/키스토어파일.jks" -alias 키스토어별칭
```

## 자동화 스크립트

SHA-1 지문을 쉽게 확인하기 위한 스크립트:

### get-sha1.ps1
```powershell
Write-Host "디버그 키스토어 SHA-1 지문 확인 중..." -ForegroundColor Cyan
$sha1 = keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>&1 | Select-String "SHA1:" | ForEach-Object { ($_ -split ":")[1].Trim() }
Write-Host "`nSHA-1: $sha1" -ForegroundColor Green
Write-Host "`n이 값을 Firebase Console에 등록하세요:" -ForegroundColor Yellow
Write-Host "Firebase Console → 프로젝트 설정 → 내 앱 → SHA 인증서 지문 추가" -ForegroundColor Yellow
```

## 확인 사항

- ✅ SHA-1 지문이 Firebase Console에 등록되었는지 확인
- ✅ `google-services.json` 파일이 최신인지 확인
- ✅ 앱 패키지 이름이 `com.example.how_are_you`로 일치하는지 확인
- ✅ 앱을 완전히 재빌드했는지 확인 (`flutter clean` 후 재빌드)

## 추가 문제 해결

### 여전히 오류가 발생하는 경우:

1. **Firebase Console에서 앱 삭제 후 재등록**
   - 프로젝트 설정 → 내 앱 → Android 앱 삭제
   - 새로 추가 (패키지 이름: `com.example.how_are_you`)
   - SHA 지문 등록
   - `google-services.json` 다운로드 및 교체

2. **테스트 전화번호 재등록**
   - Authentication → Sign-in method → 전화번호
   - 테스트 전화번호 삭제 후 재등록

3. **앱 완전 재설치**
   ```powershell
   flutter clean
   flutter pub get
   adb uninstall com.example.how_are_you
   flutter run
   ```
