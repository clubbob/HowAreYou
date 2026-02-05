# SHA-1 지문 확인 방법 (Flutter 프로젝트)

## 문제 상황
Android Studio의 Gradle 탭에서 `android → Tasks → android` 경로에 `signingReport`가 보이지 않는 경우

## 해결 방법

### 방법 1: app 모듈에서 확인 (권장)

Flutter 프로젝트에서는 `signingReport`가 `app` 모듈 아래에 있습니다:

1. Android Studio의 **Gradle** 탭에서
2. `app` 모듈 확장
3. `app` → `Tasks` → `android` → **signingReport** 더블클릭
4. 하단 **Run** 탭에서 출력 확인:
   ```
   Variant: debug
   Config: debug
   Store: C:\Users\사용자명\.android\debug.keystore
   Alias: AndroidDebugKey
   SHA1: A1:B2:C3:D4:E5:F6:... (이 값을 복사)
   ```

### 방법 2: Gradle 명령줄 사용

터미널에서 직접 실행:

```powershell
cd d:\project\HowAreYou\android
.\gradlew signingReport
```

출력에서 `SHA1:` 라인을 찾으세요.

### 방법 3: app 모듈의 signingReport 직접 실행

Android Studio에서:
1. **Gradle** 탭 열기
2. `app` 모듈 확장 (왼쪽 화살표 클릭)
3. `app` → `Tasks` → `android` 확장
4. **signingReport** 더블클릭
5. 하단 **Run** 탭에서 결과 확인

### 방법 4: 검색 기능 사용

Android Studio Gradle 탭에서:
1. 상단 검색 아이콘 클릭
2. `signingReport` 입력
3. 검색 결과에서 `app` → `Tasks` → `android` → `signingReport` 선택

## Flutter 프로젝트 구조

Flutter 프로젝트의 Gradle 구조:
```
android (루트 프로젝트)
  └── app (앱 모듈)
      └── Tasks
          └── android
              └── signingReport ← 여기에 있음!
```

일반 Android 프로젝트와 다르게, Flutter는 `app` 모듈이 별도로 있습니다.

## 빠른 확인 명령어

PowerShell에서 한 줄로:

```powershell
cd d:\project\HowAreYou\android; .\gradlew signingReport | Select-String "SHA1"
```

또는 전체 출력 보기:

```powershell
cd d:\project\HowAreYou\android; .\gradlew signingReport
```

## 출력 예시

정상적으로 실행되면 다음과 같은 출력이 나옵니다:

```
> Task :app:signingReport
Variant: debug
Config: debug
Store: C:\Users\사용자명\.android\debug.keystore
Alias: AndroidDebugKey
MD5: 12:34:56:78:90:AB:CD:EF:...
SHA1: A1:B2:C3:D4:E5:F6:... ← 이 값을 복사!
SHA-256: AA:BB:CC:DD:EE:FF:...
Valid until: ...
```

## 다음 단계

SHA-1 지문을 확인한 후:
1. Firebase Console 접속
2. 프로젝트 설정 → 내 앱 → Android 앱 선택
3. SHA 인증서 지문 → 지문 추가
4. 확인한 SHA-1 지문 입력
5. 저장

## 문제 해결

### "Task list not built..." 메시지가 보이는 경우:
1. Gradle 탭 상단의 **새로고침** 아이콘 클릭
2. 프로젝트 동기화: **File** → **Sync Project with Gradle Files**
3. 잠시 기다린 후 다시 확인

### gradlew가 실행되지 않는 경우:
1. Java 환경 확인: `java -version`
2. JAVA_HOME 환경 변수 확인
3. Android Studio의 내장 JDK 사용: **File** → **Project Structure** → **SDK Location** → **JDK location** 확인
