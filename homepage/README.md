# 지금 어때 - 홈페이지

Next.js 15 + TypeScript + Tailwind CSS 기반 랜딩 페이지.

## 개발

```bash
npm install
npm run dev
```

## 환경 변수

`.env.local.example`을 참고해 `.env.local`을 생성하고 Firebase Web SDK 값을 채우세요.

Firebase Console → 프로젝트 설정 → 일반 → 내 앱 → 웹 앱 추가 후 config 복사

## 배포 (Vercel)

1. Vercel에 프로젝트 연결
2. **Root Directory**: `homepage` 설정
3. 환경 변수 추가 (NEXT_PUBLIC_FIREBASE_*)
4. 배포

## Firestore 컬렉션

- **waitlist**: 베타 신청 이메일 (`email`, `createdAt`)
- **announcements**: 공지사항 (`title`, `content`, `createdAt`, `pinned`)

Firestore 보안 규칙은 프로젝트 루트의 `firestore.rules`에 포함되어 있습니다.
배포: `firebase deploy --only firestore:rules`
