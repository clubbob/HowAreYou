# SHA-1 인증서 지문 확인 가이드

Firebase 전화 인증을 사용하려면 Android 앱의 SHA-1 지문을 Firebase Console에 추가해야 합니다.

## 방법 1: Gradle로 확인 (권장)

### Windows PowerShell에서:

```powershell
cd d:\project\HowAreYou\android
.\gradlew signingReport
```

출력에서 다음을 찾으세요:
```
Variant: debug
Config: debug
Store: C:\Users\사용자명\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**SHA1:** 뒤의 값(콜론 포함)을 복사하세요.

## 방법 2: keytool로 직접 확인

### Windows PowerShell에서:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

출력에서 다음을 찾으세요:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**SHA1:** 뒤의 값(콜론 포함)을 복사하세요.

## 방법 3: Android Studio에서 확인

1. Android Studio에서 프로젝트 열기
2. 오른쪽 사이드바에서 "Gradle" 탭 클릭
3. `android` → `Tasks` → `android` → `signingReport` 더블클릭
4. 하단 "Run" 탭에서 SHA-1 값 확인

## Firebase Console에 추가하기

1. Firebase Console → 프로젝트 설정 → 내 앱 → Android 앱 선택
2. "SHA 인증서 지문" 섹션으로 스크롤
3. "인증서 지문" 입력 필드에 SHA-1 값 붙여넣기
   - 예: `A1:B2:C3:D4:E5:F6:...`
4. "SHA1" 버튼이 선택되어 있는지 확인
5. "저장" 버튼 클릭

## 주의사항

- **Debug 키스토어**: 개발 중에는 debug keystore의 SHA-1을 추가
- **Release 키스토어**: 앱을 배포할 때는 release keystore의 SHA-1도 추가해야 함
- SHA-1 지문은 콜론(`:`)을 포함한 전체 값을 입력해야 합니다

## 문제 해결

### Java 경로 오류가 발생하는 경우:
- Java가 설치되어 있는지 확인
- JAVA_HOME 환경 변수가 올바르게 설정되어 있는지 확인

### keystore를 찾을 수 없는 경우:
- Flutter가 자동으로 debug keystore를 생성할 수 있습니다
- 먼저 `flutter build apk --debug` 명령을 실행해보세요
