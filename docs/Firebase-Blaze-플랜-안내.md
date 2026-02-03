# Firebase Blaze 플랜 안내

## 에러 메시지

```
Error: Your project howareyou-1c5de must be on the Blaze (pay-as-you-go) plan
```

## 해결 방법

### Cloud Functions를 사용하려면 Blaze 플랜 필요

Cloud Functions를 사용하려면 Firebase 프로젝트를 **Blaze (pay-as-you-go)** 플랜으로 업그레이드해야 합니다.

### 업그레이드 링크

https://console.firebase.google.com/project/howareyou-1c5de/usage/details

위 링크에서 업그레이드를 진행하세요.

## 비용 걱정?

### 무료 할당량 (매월)

- **Cloud Functions**: 200만 호출/월 무료
- **Cloud Build**: 120 빌드-분/일 무료
- **FCM**: 무제한 무료
- **Cloud Scheduler**: 3개 작업 무료

### 예상 사용량

- 보호 대상 1명이 하루 3번 응답 = 월 90회 호출
- 보호 대상 10명 = 월 900회 호출
- 미회신 판단 = 월 30회 호출

**→ 무료 할당량 내에서 충분히 사용 가능합니다!**

## 업그레이드 후

1. 업그레이드 완료
2. 다시 배포:
   ```bash
   firebase deploy --only functions
   ```

## 대안 (Blaze 플랜 없이 사용하려면)

Blaze 플랜 업그레이드가 어렵다면, 앱에서 직접 FCM 알림을 보내는 방법도 있지만 **제한적**입니다:
- 앱이 실행 중일 때만 알림 발송 가능
- 백그라운드/앱 종료 시 알림 불가
- 미회신 판단 로직 구현 어려움

**권장: Blaze 플랜 업그레이드** (무료 할당량으로 충분)
