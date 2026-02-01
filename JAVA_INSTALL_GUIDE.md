# Java JDK 설치 가이드 (SHA-1 지문 확인용)

## 1. Java JDK 다운로드

### ⭐ 옵션 1: OpenJDK (무료, 권장)
**왜 OpenJDK를 권장하나요?**
- Oracle JDK와 동일한 기능
- **완전 무료** (상업적 사용 포함)
- Oracle JDK 17은 상업적 사용 시 유료이지만, OpenJDK는 무료입니다
1. **https://adoptium.net/** 접속
2. "Latest LTS Release" 선택 (Java 17 또는 21)
3. "Windows" → "x64" 선택
4. "JDK" 선택
5. "Installer" 다운로드

### 옵션 2: Oracle JDK (주의: 라이선스 확인 필요)
**⚠️ 중요: Oracle JDK 17은 상업적 프로덕션 사용 시 유료입니다**
- Oracle JDK 21 이상: 무료 (상업적 사용 포함)
- Oracle JDK 17, 11, 8: 개인/개발은 무료, 상업적 프로덕션은 유료

1. https://www.oracle.com/java/technologies/downloads/#java17 접속
2. "Windows" 탭 선택
3. "x64 Installer" 다운로드 (`jdk-17_windows-x64_bin.exe`)

## 2. Java 설치

1. 다운로드한 설치 파일 실행
2. "Next" 클릭하여 기본 설정으로 설치
3. 설치 경로 확인 (기본: `C:\Program Files\Java\jdk-17` 또는 `C:\Program Files\Eclipse Adoptium\jdk-17...`)

## 3. 환경 변수 설정

### 방법 1: 자동 설정 (설치 시 옵션)
- 설치 시 "Set JAVA_HOME variable" 옵션이 있으면 체크

### 방법 2: 수동 설정
1. Windows 검색에서 "환경 변수" 검색
2. "시스템 환경 변수 편집" 클릭
3. "환경 변수" 버튼 클릭
4. "시스템 변수"에서 "새로 만들기" 클릭
   - 변수 이름: `JAVA_HOME`
   - 변수 값: `C:\Program Files\Java\jdk-17` (실제 설치 경로)
5. "Path" 변수 선택 → "편집" 클릭
6. "새로 만들기" 클릭 → `%JAVA_HOME%\bin` 추가
7. 모든 창 "확인" 클릭

## 4. 설치 확인

PowerShell을 새로 열고 다음 명령어 실행:

```powershell
java -version
```

출력 예시:
```
openjdk version "17.0.x" 2023-xx-xx
OpenJDK Runtime Environment (build 17.0.x+x)
OpenJDK 64-Bit Server VM (build 17.0.x+x, mixed mode, sharing)
```

## 5. SHA-1 지문 확인

Java 설치가 완료되면 다음 명령어로 SHA-1 지문을 확인할 수 있습니다:

```powershell
cd d:\project\HowAreYou\android
.\gradlew signingReport
```

또는:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

출력에서 `SHA1:` 뒤의 값을 복사하세요.

## 문제 해결

### Java가 인식되지 않는 경우:
1. PowerShell을 완전히 종료하고 다시 열기
2. 환경 변수가 제대로 설정되었는지 확인:
   ```powershell
   $env:JAVA_HOME
   echo $env:PATH
   ```

### keystore를 찾을 수 없는 경우:
- Flutter가 아직 빌드를 하지 않아서 keystore가 생성되지 않았을 수 있습니다
- 다음 명령어로 빌드 실행:
  ```powershell
  cd d:\project\HowAreYou
  C:\src\flutter\bin\flutter build apk --debug
  ```
