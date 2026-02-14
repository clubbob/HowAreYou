# Vercel 404 해결 - 홈페이지 배포

## 현상
`how-are-you-nu.vercel.app` 접속 시 **404: NOT_FOUND**

## 원인
Vercel이 **레포 루트**(Flutter)를 빌드하고 있음:
- 루트 `vercel.json`: `buildCommand: "echo pre-built"` → 실제 빌드 없음
- `outputDirectory: "build/web"` → 비어 있거나 없음 (gitignore됨)
- 결과: 배포할 파일 없음 → 404

## 해결: Root Directory를 homepage로 설정

### 1. Vercel Dashboard
1. https://vercel.com/dashboard 접속
2. 프로젝트 **how-are-you-nu** 선택
3. **Settings** 탭

### 2. Root Directory 수정
1. 왼쪽 **General** 메뉴
2. **Root Directory** 섹션 → **Edit** 클릭
3. `homepage` 입력 (저장 시 기존 값이 비어 있으면 새로 입력)
4. **Save** 클릭

### 3. 재배포
- **Deployments** 탭
- 최신 배포 오른쪽 **⋮** → **Redeploy**
- "Use existing Build Cache" **체크 해제** 후 Redeploy

### 4. 확인
- 배포 완료 후 `how-are-you-nu.vercel.app` 접속
- 정상 시: "하루 한 번, 안부를 남기세요" 랜딩 페이지 표시
