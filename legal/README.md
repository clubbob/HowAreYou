# 이용약관·개인정보처리방침 (단일 소스)

**이 폴더만 수정하면 앱·웹·설정 화면 모두 동일한 내용이 표시됩니다.**

## 수정 방법

1. 이 폴더에서만 수정하세요.
   - `terms.txt` : 이용약관
   - `privacy.txt` : 개인정보처리방침

2. **자동 반영**
   - 홈페이지: `cd homepage && npm run dev` → legal sync + 감시(watch) 자동 실행
   - 앱: VS Code/Cursor에서 F5(Flutter 실행) → 실행 전 sync-legal 자동 실행
   - 앱(터미널): `npm run flutter-run` (sync 후 flutter run)
   - Flutter 개발(감시): `npm run flutter-dev` (저장 시 자동 sync)
   - 수동: `npm run sync-legal`

## 수동 동기화
- `npm run sync-legal` : 수정 후 한 번만 실행

## 다른 경로에서 수정한 경우
- `assets/` 수정 후: `npm run sync-legal:from-assets`
- `homepage/lib/legal-content.ts` 수정 후: `npm run sync-legal:from-web`
