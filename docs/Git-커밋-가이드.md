# Git 커밋 가이드

## 질문: 터미널이 2개인데 Git에 올리려면 터미널별로 해야 하나요?

**답변: 아니요! 터미널별로 따로 할 필요 없습니다.**

## Git은 프로젝트 단위로 관리됩니다

- Git은 **프로젝트 폴더 전체**를 관리합니다
- 터미널이 몇 개든 상관없이 **한 번만** 커밋하면 됩니다
- 두 터미널에서 작업한 모든 변경사항이 하나의 커밋에 포함됩니다

## 커밋 방법

### 1단계: 변경사항 확인

```powershell
git status
```

### 2단계: 변경사항 스테이징

```powershell
git add .
```

또는 특정 파일만:

```powershell
git add lib/screens/guardian_screen.dart
git add lib/screens/subject_mode_screen.dart
```

### 3단계: 커밋

```powershell
git commit -m "보호 대상자 화면에 로그아웃 버튼 추가 및 보호자 이름 입력 문제 수정"
```

### 4단계: 푸시

```powershell
git push
```

## 터미널별로 따로 할 필요가 없는 이유

### 예시 상황:
- **터미널 1 (보호자)**: `guardian_screen.dart` 수정
- **터미널 2 (보호 대상자)**: `subject_mode_screen.dart` 수정

### 올바른 방법:
```powershell
# 어느 터미널에서든 한 번만 실행
git add .
git commit -m "보호자 및 보호 대상자 화면 수정"
git push
```

### 잘못된 방법:
```powershell
# 터미널 1에서
git add guardian_screen.dart
git commit -m "보호자 화면 수정"
git push

# 터미널 2에서
git add subject_mode_screen.dart
git commit -m "보호 대상자 화면 수정"
git push
```
→ 이렇게 해도 되지만, 한 번에 하는 것이 더 간단합니다!

## 권장 방법

### 한 번에 커밋 (권장):
```powershell
git add .
git commit -m "변경사항 설명"
git push
```

### 파일별로 나누어 커밋 (선택사항):
```powershell
# 관련된 변경사항끼리 묶어서 커밋
git add lib/screens/guardian_screen.dart lib/screens/subject_mode_screen.dart
git commit -m "로그아웃 버튼 추가"

git add lib/screens/question_screen.dart lib/services/guardian_service.dart
git commit -m "보호자 지정 확인 로직 추가"
```

## 주의사항

### 커밋하지 말아야 할 파일들:
- 터미널 로그 파일 (`terminals/*.txt`)
- 빌드 결과물 (`build/`, `.dart_tool/`)
- IDE 설정 (`.idea/`, `.vscode/` - 선택사항)
- 환경 변수 파일 (`.env`)

이런 파일들은 `.gitignore`에 포함되어 있어야 합니다.

## 요약

- ✅ **한 번만 커밋**: 터미널 개수와 관계없이 프로젝트 전체를 한 번에 커밋
- ✅ **어느 터미널에서든**: 어떤 터미널에서 커밋해도 동일합니다
- ❌ **터미널별로 따로**: 필요 없습니다

## 빠른 커밋 명령어

```powershell
# 변경사항 확인
git status

# 모든 변경사항 추가
git add .

# 커밋
git commit -m "변경사항 설명"

# 푸시
git push
```

터미널이 몇 개든 상관없이, **한 번만 커밋하면 됩니다!**
