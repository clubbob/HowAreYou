# Cursor 터미널에서 Git(GitHub)에 바로 올리는 절차

> Vercel 없이, Cursor 안에 열려 있는 **그 터미널**만 사용해서 코드를 GitHub에 올리는 방법입니다.  
> (PowerShell이든 cmd든 Git Bash든, Cursor에서 열린 **이 터미널**에서 아래 명령을 그대로 입력하면 됩니다.)

---

## 1. Git 설치 여부 확인

Cursor에서 **터미널**을 연다.  
(메뉴: Terminal → New Terminal, 또는 `` Ctrl+` ``)

**이 터미널**에서 아래를 입력한다.

```
git --version
```

- **버전이 나오면** (예: `git version 2.43.0.windows.1`) → 다음 단계로 진행
- **`'git' is not recognized`** 나오면:
  - [git-scm.com/download/win](https://git-scm.com/download/win) 에서 설치
  - 설치 후 **Cursor를 한 번 닫았다가 다시 열고** 터미널에서 다시 `git --version` 실행

---

## 2. GitHub에 저장소(Repository) 만들기 (한 번만)

1. 브라우저에서 [github.com](https://github.com) 접속 후 로그인
2. 오른쪽 상단 **+** 클릭 → **New repository**
3. 다음처럼 설정:
   - **Repository name**: `HowAreYou` (또는 원하는 이름)
   - **Public** 선택
   - **Add a README file**, **Add .gitignore** 등은 **체크하지 않음** (로컬에 이미 코드가 있음)
4. **Create repository** 클릭
5. 생성된 페이지에서 **저장소 URL**을 복사해 둔다.
   - HTTPS 예: `https://github.com/내아이디/HowAreYou.git`
   - `내아이디`를 본인 GitHub 아이디로 바꾸면 된다.

---

## 3. Cursor 터미널에서 프로젝트 폴더로 이동

**이 터미널**에서 아래를 입력한다.  
(이미 `d:\project\HowAreYou`에서 작업 중이면 생략해도 된다.)

```
cd d:\project\HowAreYou
```

---

## 4. 처음 한 번만: Git 초기화 및 원격 저장소 연결

### 4-1. 이 폴더를 Git 저장소로 만든다 (한 번만)

```
git init
```

- `Initialized empty Git repository in d:/project/HowAreYou/.git/` 같은 메시지가 나오면 성공

### 4-2. GitHub 저장소를 "원격(origin)"으로 등록한다

아래에서 **반드시 `내아이디`와 `HowAreYou`를 2단계에서 만든 저장소에 맞게 바꾼다.**

```
git remote add origin https://github.com/내아이디/HowAreYou.git
```

- 이미 `origin`이 있다는 오류가 나오면:
  - 주소를 바꿀 때: `git remote set-url origin https://github.com/내아이디/HowAreYou.git`
  - 확인: `git remote -v`

### 4-3. .gitignore 확인 (선택)

Git에 올리지 않을 파일은 `.gitignore`에 있어야 한다.  
Flutter 프로젝트에는 보통 이미 있다. **이 터미널**에서 아래 중 하나로 확인하면 된다.

```
type .gitignore
```

- PowerShell 쓰는 터미널이면 `Get-Content .gitignore` 도 가능하다.
- `build/`, `.dart_tool/` 등이 보이면 괜찮다.  
- 없다면 Flutter 기본 `.gitignore`를 추가하는 것이 좋다.

---

## 5. 파일 올리기: add → commit → push

### 5-1. 변경된 파일 전부 스테이징

```
git add .
```

- `.` 은 "현재 폴더 전체"를 의미한다.  
- 특정 파일만 올리려면: `git add lib/screens/guardian_screen.dart` 처럼 경로 지정

### 5-2. 커밋 (이번에 올리는 내용에 대한 설명)

```
git commit -m "지정자 이름 저장/수정 기능 반영"
```

- `"..."` 안의 메시지는 원하는 대로 바꾼다.  
- 예: `"Initial commit"`, `"버그 수정"`, `"UI 개선"` 등

### 5-3. 브랜치 이름을 main으로 맞추기 (처음 한 번, 필요할 때만)

GitHub 기본 브랜치가 `main`인 경우:

```
git branch -M main
```

### 5-4. GitHub로 푸시 (실제로 "올리기")

**처음 푸시할 때:**

```
git push -u origin main
```

- `-u origin main` 은 "앞으로 `git push`만 쳐도 `origin`의 `main`으로 보낸다"는 의미라서, 처음 한 번만 쓰면 된다.

**이후부터는:**

```
git push
```

만 입력해도 된다.

---

## 6. 푸시 시 로그인/인증

- **HTTPS** (`https://github.com/...`) 로 연결한 경우:
  - 처음 `git push` 할 때 GitHub **사용자명**과 **비밀번호**를 물을 수 있다.
  - 비밀번호 자리에는 **Personal Access Token(PAT)** 을 넣어야 할 수 있다.  
    (GitHub → Settings → Developer settings → Personal access tokens 에서 생성)
  - 또는 브라우저가 뜨면서 GitHub 로그인으로 인증하는 경우도 있다.

- **SSH** 로 쓰고 싶다면:
  - SSH 키를 만들고 GitHub 계정에 등록한 뒤
  - `git remote set-url origin git@github.com:내아이디/HowAreYou.git` 로 바꾸고
  - `git push -u origin main` 사용

---

## 7. 이후 수정할 때마다 반복하는 절차

코드를 고친 다음, 다시 GitHub에 올리려면 **이 터미널**에서:

```
cd d:\project\HowAreYou

git add .
git commit -m "수정 내용을 한 줄로 요약"
git push
```

- `git add .` → 변경 파일 전부 스테이징  
- `git commit -m "..."` → 이번에 올리는 내용 설명  
- `git push` → GitHub에 반영  

이 세 단계만 반복하면 된다.

---

## 8. 자주 쓰는 명령어 정리

| 목적           | 명령어 |
|----------------|--------|
| 상태 확인      | `git status` |
| 올릴 파일 지정 | `git add .` (전체) / `git add 파일경로` (일부) |
| 커밋           | `git commit -m "메시지"` |
| 푸시           | `git push` (또는 `git push origin main`) |
| 원격 주소 확인 | `git remote -v` |
| 최근 커밋 목록 | `git log --oneline` |

---

## 9. 한 번에 복사해서 쓸 수 있는 예시 (처음 한 번)

아래는 **처음 이 프로젝트를 GitHub에 올릴 때** Cursor에 열린 **이 터미널**에서 순서대로 실행하는 예시다.  
`내아이디`와 `HowAreYou`를 본인 저장소에 맞게 바꾼다.

```
cd d:\project\HowAreYou
git init
git remote add origin https://github.com/내아이디/HowAreYou.git
git add .
git commit -m "Initial commit: HowAreYou Flutter app"
git branch -M main
git push -u origin main
```

---

## 10. 요약

- **Vercel은 사용하지 않는다.** Cursor 터미널 + Git + GitHub만 사용한다.
- **처음:** GitHub에 저장소 생성 → `git init` → `git remote add origin ...` → `git add .` → `git commit` → `git push -u origin main`
- **이후:** 수정할 때마다 `git add .` → `git commit -m "..."` → `git push` 만 반복하면 된다.
