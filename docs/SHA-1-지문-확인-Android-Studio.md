# Android Studio에서 SHA-1 지문 확인하기

## 문제 상황
Gradle 탭에서 `app → Tasks → android` 그룹이 보이지 않는 경우

## 해결 방법

### 1단계: Gradle 동기화 (필수)

Android Studio에서:
1. 상단 메뉴: **File** → **Sync Project with Gradle Files**
2. 또는 단축키: `Ctrl + Shift + O` (Windows/Linux) 또는 `Cmd + Shift + O` (Mac)
3. 동기화가 완료될 때까지 기다리기 (하단 진행 표시줄 확인)

**중요**: "Task list not built..." 메시지가 사라질 때까지 기다려야 합니다.

### 2단계: Gradle 탭 새로고침

1. Gradle 탭 상단의 **새로고침** 아이콘 클릭 (원형 화살표 아이콘)
2. 또는 Gradle 탭 우클릭 → **Refresh Gradle Project**

### 3단계: signingReport 찾기

#### 방법 A: 검색 기능 사용 (가장 빠름)
1. Gradle 탭 상단의 **검색 아이콘** 클릭 (돋보기 아이콘)
2. `signingReport` 입력
3. 검색 결과에서 `app` → `Tasks` → `android` → `signingReport` 선택
4. 더블클릭하여 실행

#### 방법 B: 수동으로 찾기
1. `app` 모듈 확장
2. `app` → `Tasks` 확장
3. `android` 그룹 찾기 (없으면 다음 단계로)
4. `android` → `signingReport` 더블클릭

### 4단계: 결과 확인

하단 **Run** 탭에서 출력 확인:
```
> Task :app:signingReport
Variant: debug
Config: debug
Store: C:\Users\사용자명\.android\debug.keystore
Alias: AndroidDebugKey
MD5: ...
SHA1: A1:B2:C3:D4:E5:F6:... ← 이 값을 복사!
SHA-256: ...
```

## 여전히 보이지 않는 경우

### 대안 1: Gradle 명령어 직접 실행

Android Studio의 **Terminal** 탭에서:

```bash
cd android
./gradlew signingReport
```

Windows의 경우:
```powershell
cd android
.\gradlew signingReport
```

### 대안 2: Flutter 빌드 명령어 사용

터미널에서:
```powershell
cd d:\project\HowAreYou
flutter build apk --debug
```

빌드 로그에서 SHA-1 지문을 찾을 수 있습니다.

### 대안 3: Android Studio의 Build Variants 확인

1. 왼쪽 사이드바에서 **Build Variants** 탭 클릭
2. `app` 모듈의 Variant가 `debug`로 설정되어 있는지 확인
3. `debug`로 설정 후 다시 `signingReport` 실행

## Gradle 동기화 문제 해결

### "Task list not built..." 메시지가 계속 보이는 경우:

1. **프로젝트 재시작**:
   - **File** → **Invalidate Caches / Restart** → **Invalidate and Restart**

2. **Gradle 설정 확인**:
   - **File** → **Settings** → **Build, Execution, Deployment** → **Gradle**
   - **Use Gradle from** 옵션 확인
   - **Gradle JDK** 설정 확인 (Java 17 권장)

3. **오프라인 모드 해제**:
   - Gradle 탭 상단 설정 아이콘 클릭
   - "Offline work" 체크 해제

## 빠른 확인 (명령어)

Android Studio의 Terminal에서:

```powershell
cd android
.\gradlew signingReport | Select-String "SHA1"
```

SHA-1 지문만 바로 확인할 수 있습니다.

## 다음 단계

SHA-1 지문을 확인한 후:
1. Firebase Console 접속
2. 프로젝트 설정 → 내 앱 → Android 앱 선택
3. SHA 인증서 지문 → 지문 추가
4. 확인한 SHA-1 지문 입력
5. 저장
