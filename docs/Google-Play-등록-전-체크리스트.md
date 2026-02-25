# Google Play Store 등록 전 체크리스트

> 사이트 개발 완료 후, 앱 출시 전에 확인·준비할 사항

---

## 1. 필수 준비 (반드시 해야 함)

### 1.1 Release 서명 키 생성
**현재**: `key.properties`가 없음 → release 빌드 시 debug 키로 서명됨. Play Store는 **전용 upload 키** 필요.

**작업**:
1. 키스토어 생성:
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. `android/key.properties` 생성 (git 제외됨):
   ```properties
   storePassword=비밀번호
   keyPassword=비밀번호
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. **upload-keystore.jks, key.properties** 절대 git에 커밋하지 말 것 (백업은 별도 안전한 곳에)

### 1.2 AAB (Android App Bundle) 빌드
```bash
flutter build appbundle
```
출력: `build/app/outputs/bundle/release/app-release.aab` → Play Console에 업로드

**signReleaseBundle NullPointerException 발생 시**:
- `key.properties` 오타 확인 (storePassword, keyPassword, keyAlias, storeFile)
- 로컬 터미널에서 직접 실행 (일부 환경에서는 key.properties 접근 제한 있을 수 있음)
- `android/gradle.properties`에 `android.newDsl=false` 확인

### 1.3 개인정보처리방침 URL 확인
- **필수**: Play Store는 개인정보처리방침 URL 필수
- **현재 설정**: `https://오늘어때.com/privacy`
- **확인**: `https://오늘어때.com/privacy` 접속 시 로그인 없이 문서가 보이는지 확인
- **Vercel 도메인**: 오늘어때.com이 Vercel에 연결되어 있는지 확인 (how-are-you-nu.vercel.app이 아닌 실제 도메인)

### 1.4 이용약관 URL
- **현재 설정**: `https://오늘어때.com/terms`
- 스토어 등록 시 필요 시 입력

---

## 2. Play Console 설정 (등록 시 입력)

### 2.1 개발자 계정
- Google Play Console 가입: https://play.google.com/console
- **비용**: 1회 $25 (약 3만원)

### 2.2 앱 정보
| 항목 | 현재 값 |
|------|---------|
| **패키지명** | com.andy.howareyou |
| **앱 이름** | 오늘 어때? |
| **버전** | 1.0.0 (versionCode: 1) |

### 2.3 스토어 등록 정보
- **짧은 설명** (80자): 예) "매일 전화 대신 3초로 안부 확인. 보호대상자와 보호자를 연결합니다."
- **전체 설명** (4000자): 서비스 소개, 기능, 사용 방법
- **앱 아이콘** 512×512 px (PNG, 투명 배경 없음)
- **기능 그래픽** 1024×512 px (스토어 상단 배너)
- **스크린샷** 최소 2장 (폰/태블릿, 실제 앱 화면)

### 2.4 콘텐츠 등급
- **IARC 설문** 완료 (Play Console에서 자동 안내)
- 예상: 3세 이상 (Everyone) 또는 12세 이상

### 2.5 데이터 보안
- **데이터 수집** 신고: 전화번호, Firebase Analytics, FCM 토큰 등
- **개인정보처리방침 URL** 입력 필수

### 2.6 타겟층
- **대상 연령**: 앱 성격에 맞게 선택
- **대상 국가**: 한국 등 출시할 국가 선택

---

## 3. 권장 확인 사항

### 3.1 URL 도메인 확인
- `constants.dart`의 `privacyUrl`, `termsUrl`이 실제 접근 가능한 URL인지
- `오늘어때.com`이 Vercel에 연결되어 있다면 `https://오늘어때.com` 또는 `https://xn--wh1b84c83w0ma.com` 둘 다 동작하는지 확인

### 3.2 앱 내 테스트
- Release 빌드로 실제 기기에서 테스트
- 로그인·로그아웃·알림·보호자 연결 등 핵심 흐름 검증

### 3.3 내부 테스트 트랙
- 출시 전 Play Console **내부 테스트**로 먼저 배포
- 테스터 이메일 추가 후 설치·동작 확인

---

## 4. 이미 완료된 항목

| 항목 | 상태 |
|------|------|
| Application ID | com.andy.howareyou (example 아님) |
| 앱 이름 | 오늘 어때? |
| 약관·개인정보처리방침 페이지 | /terms, /privacy 존재 |
| 권한 선언 | AndroidManifest 적절 |
| 딥링크 | /invite 설정됨 |
| Firebase | Auth, Firestore, FCM, Functions 연결 |
| 버전 | 1.0.0+1 |

---

## 5. 요약 순서

1. **키스토어 생성** + key.properties 설정
2. **flutter build appbundle** 실행
3. **Play Console** 가입 → 앱 생성
4. **스토어 등록 정보** 입력 (설명, 아이콘, 스크린샷)
5. **개인정보처리방침 URL** 입력
6. **콘텐츠 등급·데이터 보안** 설문 완료
7. **내부 테스트**로 먼저 배포
8. **프로덕션** 출시
