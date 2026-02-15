# Vercel 404 해결 - 홈페이지 배포

## 현상
`how-are-you-nu.vercel.app` 접속 시 **404: NOT_FOUND**

## 체크리스트

### 1. Root Directory = `homepage` (필수)
- Settings → General → Root Directory → `homepage`

### 2. Framework Preset = Next.js
- Settings → Build and Deployment → Framework Preset → **Next.js** 선택
- "Other" 이면 404 발생 가능 → Next.js로 변경 후 Redeploy

### 3. Build & Development Settings 확인
- **Build Command**: 비워두거나 `npm run build` (homepage/vercel.json이 우선)
- **Output Directory**: 비움 (Next.js는 자동 처리)
- **Install Command**: 비워두거나 `npm install`

### 4. Next.js 빌드 출력을 build/web에 맞춤
- `next.config.ts`에 `distDir: 'build/web'` 설정
- Vercel Output Directory가 `build/web`으로 고정된 상태에서도 동작하도록 조정

### 5. 루트 vercel.json 제거됨
- `vercel.json` 삭제 완료 → `vercel.flutter-backup.json`으로 백업만 존재
- 루트 설정이 homepage 빌드를 덮어쓰지 않음

### 6. 배포 로그 확인
- Deployments → 최신 배포 클릭 → **Building** 로그 확인
- `npm run build` 또는 `next build` 가 실행되는지 확인
- Flutter/dart 관련 로그가 보이면 → Framework Preset 또는 Root Directory 재확인

### 7. 재배포
- Deployments → ⋮ → Redeploy
- **Use existing Build Cache** 체크 해제 권장
