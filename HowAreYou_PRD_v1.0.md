# PRD – HowAreYou (지금 어때?)

## 1. 프로젝트 개요
- 프로젝트 폴더명: **HowAreYou**
- 서비스명: **지금 어때? (How Are You?)**
- 목적:
  - 하루 3번(아침/점심/저녁) 사용자의 상태를 간단히 확인
  - 완전 무응답 상태가 일정 기간 지속될 경우 지정자에게만 “연락이 닿지 않음”을 통지
- 핵심 원칙:
  - 감시하지 않는다
  - 판단하지 않는다
  - 사용 내역은 시스템에만 저장되고, 지정자에게는 전달하지 않는다

## 2. 타겟 사용자
- 보호대상: 아이, 어르신, 또는 혼자 지내는 사용자
- 지정자(Guardian): 부모, 자녀, 배우자 등 연락 담당자

## 3. 플랫폼 & 기술 스택
- App: Flutter
- Auth: Firebase Auth (전화번호 OTP)
- Database: Cloud Firestore
- Push:
  - 로컬 알림: flutter_local_notifications
  - 원격 푸시: Firebase Cloud Messaging (FCM)
- Backend:
  - 별도 서버 없음
  - Firebase Cloud Functions + Scheduler 1개만 사용

## 4. 기본 동작 흐름

### 4.1 일상 알림 (보호대상)
- 매일 3회 로컬 알림
  - 아침 08:00
  - 점심 12:00
  - 저녁 18:00
- 알림은 소리 ON (앱 설정에서 무음 가능)
- 알림 클릭 시 앱 열리고 질문 표시

### 4.2 질문 화면
- 질문 문구: **“지금 어때?”**
- 아이콘 5개 한 줄 배치 (필수 선택)
  - 😊 좋아
  - 🙂 괜찮아
  - 😐 보통
  - 🙁 별로
  - 😞 힘들어
- 아이콘 크기: 72px 이상, 터치 영역 96px 이상

### 4.3 응답 규칙
- 아이콘 선택은 필수
- 😊🙂😐🙁 선택 시: 즉시 응답 완료
- 😞 선택 시:
  - “어떤 게 힘드세요?” 텍스트 입력창 표시
  - 입력은 선택
  - 확인 버튼 클릭 시 응답 완료
- 응답 완료 후:
  - “고마워요.” 또는 “알려줘서 고마워요.” 한 줄 표시 후 종료

## 5. 데이터 저장 원칙 (B안: 가족 공유형)
- 저장 대상 (Firestore):
  - 선택한 기분(mood: 1~3)
  - 응답 시간대(slot: 아침/점심/저녁)
  - 응답 시각(answeredAt)
- 공유 범위:
  - 보호 대상자 본인: 모든 이력 조회 가능
  - 보호자: 최근 7일까지만 조회 가능 (연결된 경우에만)
  - 보호자는 prompts 읽기만 가능, 쓰기 불가
  - 공유 제한: 정확한 시각(예: 08:13)은 공유하지 않음, 슬롯(아침/점심/저녁)만 공유

## 6. 미회신 판단 로직

### 6.1 기준
- Day 1:
  - 아침 ❌ / 점심 ❌ / 저녁 ❌
- Day 2:
  - 아침 ❌

### 6.2 통지 시점
- Day 2 점심(12:00)에 1회 판정
- 조건 충족 시 지정자에게 알림 발송

### 6.3 알림 문구
- 푸시 알림 + 소리
- 클릭 시 앱에서 표시:
  - **“OO님과 연락이 닿지 않고 있어요.”**

## 7. 지정자 규칙
- 지정자는 사용자 응답 내역을 볼 수 없음
- 지정자는 오직 “연락이 닿지 않음” 알림만 수신

## 8. 계정 & 로그인
- 보호대상/지정자 모두 전화번호 OTP 로그인
- subjectId = Firebase Auth uid
- 지정자-보호대상 연결:
  - subject 문서에 guardian uid 배열로 관리

## 9. Firestore 컬렉션 구조 (요약)

### /users/{uid}
- role: guardian | subject | both
- phone
- fcmTokens[]

### /subjects/{subjectId}
- displayName
- pairedGuardianUids[]

### /subjects/{subjectId}/prompts/{YYYY-MM-DD_slot}
- slot: morning | noon | evening
- answeredAt
- mood
- note

### /alerts/{alertId}
- type: UNREACHABLE
- subjectId
- guardianUids[]
- triggerDate
- triggeredAt

## 10. 비범위 (MVP에서 하지 않는 것)
- 위치 추적
- 감정 분석/판정
- 지정자 대시보드
- 유료 결제

## 11. 성공 기준 (MVP)
- 로컬 알림 3회 안정적 동작
- 응답 Firestore 정상 저장
- 미회신 조건 충족 시 보호자에게 1회만 알림 발송
- 보호자가 보호 대상자의 최근 7일 상태를 조회 가능 (B안: 가족 공유형)
- 공유 범위 제한 준수 (7일까지만, 슬롯 기준만, 정확한 시각 공유 없음)
