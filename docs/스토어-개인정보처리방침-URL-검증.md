# 스토어 개인정보처리방침 URL 검증 가이드

> Play Store / App Store 심사 시 개인정보처리방침 URL 요구사항 및 현재 상태

---

## 📋 스토어 요구사항

| 항목 | 설명 |
|------|------|
| **완전한 URL** | `https://` 포함, 외부에서 접근 가능 |
| **로그인 없음** | 비회원·비로그인 사용자도 열람 가능 |
| **모바일 대응** | 스마트폰에서 잘 열리고 읽기 편해야 함 |
| **정책 문서 형태** | 섹션, 날짜, 회사 정보 등이 있는 정책 페이지 느낌 |
| **안정적 접속** | robots 차단, 리다이렉트 루프, 404 없음 |

---

## ✅ 현재 URL

```
https://how-are-you-nu.vercel.app/privacy
```

**constants.dart**: `privacyUrl = 'https://how-are-you-nu.vercel.app/privacy'`

---

## ✅ 검증 결과 (코드 기준)

| 체크 항목 | 상태 | 비고 |
|----------|------|------|
| **robots.txt** | ✅ 허용 | `Allow: /` → /privacy 포함 |
| **리다이렉트** | ✅ 없음 | next.config에 redirect 없음 |
| **404** | ✅ 아님 | `app/privacy/page.tsx` 존재 |
| **로그인 요구** | ✅ 없음 | middleware는 `/admin`만 적용 |
| **앱 설치 유도** | ✅ 없음 | privacy 페이지에 앱 다운로드/설치 안내 없음 |
| **페이지 구조** | ✅ 적합 | 제목, 본문(whitespace-pre-line), 홈 링크 |
| **모바일 대응** | ✅ | max-w-3xl, px-6, Tailwind responsive |
| **정책 문서 내용** | ✅ | 수집 항목, 목적, 보관 기간, Firebase 등 |

---

## 🧪 수동 검증 (배포 후 매번 확인 권장)

1. **PC 브라우저 시크릿 모드**
   - `https://how-are-you-nu.vercel.app/privacy` 접속
   - 로그인 없이 문서만 보이는지 확인

2. **모바일 브라우저**
   - 스마트폰에서 동일 URL 접속
   - 레이아웃·글자 크기·스크롤이 자연스러운지 확인

3. **리다이렉트 여부**
   - 주소창에 위 URL 직접 입력 후 엔터
   - 다른 도메인/경로로 바뀌지 않는지 확인

4. **네트워크 탭**
   - 200 OK 응답
   - 3xx 리다이렉트 없음

---

## ⚠️ 흔한 함정 (배포·환경 변경 시 점검)

| 함정 | 확인 방법 |
|------|----------|
| robots 차단 | `/robots.txt` 확인 후 `/privacy` Disallow 여부 |
| 리다이렉트 루프 | 개발자 도구 Network 탭에서 3xx 반복 여부 |
| 404 | 직접 URL 접속 후 404 페이지 여부 |
| 앱 설치 유도 | privacy 전용 페이지에서 Play/App Store 링크 노출 여부 |
| 로그인 요구 | 비로그인 상태로 접속 시 로그인 화면으로 이동하는지 |
| 느린 로딩/깨짐 | LCP, CLS 등 성능 및 레이아웃 깨짐 여부 |

---

## 📌 스토어 등록 시 입력 값

- **개인정보처리방침 URL**: `https://how-are-you-nu.vercel.app/privacy`
- **이용약관 URL** (필요 시): `https://how-are-you-nu.vercel.app/terms`

---

## 🔄 도메인 변경 시

`privacyUrl`은 `lib/utils/constants.dart`에 정의되어 있음.

Vercel 커스텀 도메인(예: howareyou.kr)으로 옮기면:

1. `constants.dart`의 `privacyUrl`, `termsUrl` 수정
2. 웹 `NEXT_PUBLIC_SITE_URL` 등 환경 변수 동기화
3. 위 수동 검증 다시 수행
