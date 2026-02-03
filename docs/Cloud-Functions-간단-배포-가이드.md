# Cloud Functions 간단 배포 가이드

## Cloud Functions 배포란?

**Git에 올리는 것이 아닙니다!**  
Firebase 서버에 함수 코드를 업로드하여 실행되도록 하는 것입니다.

## 왜 필요한가요?

- 보호 대상이 응답할 때마다 보호자에게 알림을 보내려면 서버가 필요합니다.
- 앱만으로는 다른 사용자에게 푸시 알림을 보낼 수 없습니다.
- Cloud Functions가 서버 역할을 합니다.

## 배포 방법 (3단계)

### 1단계: Firebase CLI 설치 (한 번만)

```bash
npm install -g firebase-tools
```

### 2단계: Firebase 로그인 (한 번만)

```bash
firebase login
```

브라우저가 열리면 Google 계정으로 로그인하세요.

### 3단계: Functions 배포

```bash
cd d:\project\HowAreYou
firebase deploy --only functions
```

이 명령어가 Firebase 서버에 함수 코드를 업로드합니다.

## 배포 후

- Functions가 Firebase 서버에서 실행됩니다.
- 보호 대상이 응답하면 자동으로 보호자에게 알림이 갑니다.
- 매일 12:00에 미회신 판단이 실행됩니다.

## Git과의 관계

- **Git**: 코드 버전 관리 (선택사항)
- **Firebase 배포**: 서버에 코드 업로드 (필수)

Git에 올리지 않아도 Firebase 배포는 가능합니다.

## 문제 해결

### "firebase: command not found"
→ Firebase CLI가 설치되지 않았습니다. `npm install -g firebase-tools` 실행

### "Firebase login required"
→ `firebase login` 실행

### "Functions directory not found"
→ `firebase init functions` 먼저 실행 (처음 한 번만)

## 참고

- 배포는 **Firebase Console**에서도 확인 가능합니다.
- Firebase Console → Functions → 함수 목록에서 실행 상태 확인
- 로그는 Firebase Console → Functions → Logs에서 확인
