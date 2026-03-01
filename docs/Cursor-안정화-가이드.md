# Cursor 안정화 가이드

> OOM(메모리 부족) 방지를 위한 설정 및 사용 가이드

## 1. node_modules 인덱싱 차단 (필수)

`.vscode/settings.json`에 적용됨:

```json
"files.watcherExclude": {
  "**/node_modules/**": true,
  "**/.git/**": true,
  "**/build/**": true,
  "**/.next/**": true
},
"search.exclude": {
  "**/node_modules": true,
  "**/build": true,
  "**/.next": true
}
```

## 2. AI 요청 시 주의

- ❌ "현재까지 구현된 모든 프로그램 요약해줘"
- ✅ "아래 코드만 기준으로 정리해줘" (파일 내용 붙여넣기)

전체 workspace 스캔 요청은 OOM 유발 가능.

## 3. 메모리 제한 해제 (Windows)

Cursor 바로가기 → 속성 → 대상(Target)에 추가:

```
--max-old-space-size=4096
```

RAM 16GB 이상이면 `8192` 가능.

## 4. Git diff 줄이기

- 기능별로 commit
- 대규모 리팩토링 한 번에 금지

## 5. 확장프로그램 정리

Flutter, Firebase, GitLens 외 불필요한 Extension 정리.
