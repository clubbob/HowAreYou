# Vercel을 활용한 Git 업로드 절차

> **흐름:** 코드를 Git(GitHub)에 올리고, Vercel이 그 저장소에 연결되어 푸시할 때마다 자동 배포합니다.

---

## 1. 준비: Git 설치·확인

**Windows (PowerShell 또는 명령 프롬프트):**

```powershell
git --version
```

- 버전이 나오면 이미 설치된 것.
- `'git' is not recognized`면 [git-scm.com](https://git-scm.com/download/win)에서 설치 후 터미널을 다시 연다.

---

## 2. GitHub에 저장소 만들기

1. [github.com](https://github.com) 로그인
2. 오른쪽 상단 **+** → **New repository**
3. 설정 예시:
   - **Repository name**: `HowAreYou` (원하는 이름)
   - **Public** 선택
   - **Add a README file** 등은 체크 안 해도 됨 (로컬에 이미 코드가 있으므로)
4. **Create repository** 클릭
5. 생성 후 나오는 페이지에서 **저장소 URL** 복사  
   - 예: `https://github.com/내아이디/HowAreYou.git`

---

## 3. 로컬 프로젝트를 Git으로 관리하고 GitHub에 올리기

### 3-1. 프로젝트 폴더로 이동

```powershell
cd d:\project\HowAreYou
```

### 3-2. Git 저장소로 초기화 (한 번만)

```powershell
git init
```

### 3-3. 원격 저장소 연결

```powershell
git remote add origin https://github.com/내아이디/HowAreYou.git
```

- `내아이디/HowAreYou` 부분을 2단계에서 만든 저장소 URL에 맞게 바꾼다.

### 3-4. 올리지 않을 파일 정리 (.gitignore)

프로젝트에 `.gitignore`가 있는지 확인한다.

```powershell
Get-Content .gitignore
```

- Flutter 기본 항목(`build/`, `.dart_tool/`, `*.iml` 등)이 있어야 한다.

### 3-5. 전체 파일 스테이징

```powershell
git add .
```

### 3-6. 첫 커밋

```powershell
git commit -m "Initial commit: HowAreYou Flutter app"
```

### 3-7. 브랜치 이름 맞추기 (필요할 때)

GitHub 기본 브랜치가 `main`이면:

```powershell
git branch -M main
```

### 3-8. GitHub에 올리기 (푸시)

```powershell
git push -u origin main
```

- 처음이라면 GitHub 로그인 창 또는 브라우저 인증이 뜰 수 있다.
- 푸시가 끝나면 GitHub 저장소 페이지에서 코드가 보여야 한다.

---

## 4. Vercel을 통해 "Git에 올릴 때마다 배포" 하기

### 4-1. Vercel 로그인

- [vercel.com](https://vercel.com) 접속 → **Sign Up** / **Log In**
- **Continue with GitHub** 선택해 GitHub 계정으로 로그인

### 4-2. 새 프로젝트 = GitHub 저장소 연결

1. 대시보드에서 **Add New…** → **Project**
2. **Import Git Repository**에서 방금 푸시한 **HowAreYou** 저장소 선택
3. **Import** 클릭

### 4-3. Flutter Web용 빌드 설정

- **Framework Preset**: **Other**
- **Root Directory**: 비워 두거나 프로젝트 루트(`.`)
- **Build Command**: `flutter build web`
- **Output Directory**: `build/web`

> **참고:** Vercel 기본 환경에는 Flutter가 없을 수 있어 빌드가 실패할 수 있다.  
> 그럴 경우 **로컬에서 `flutter build web` 실행 후 `build/web` 폴더만 배포**하거나, Vercel에서 Flutter 설치 스크립트를 **Install Command**에 넣는 방식으로 설정해야 한다.

### 4-4. 환경 변수 (선택)

- Firebase 등 쓰는 경우 **Environment Variables**에 필요한 값 추가

### 4-5. Deploy

- **Deploy** 클릭
- 끝나면 **Visit**로 배포된 웹 주소로 이동

---

## 5. 이후: "Git에 올릴 때마다" 반복하는 절차

코드 수정 후 다시 Git에 올리면 Vercel이 자동으로 새 배포를 시작한다.

```powershell
cd d:\project\HowAreYou

git add .
git commit -m "수정 내용 한 줄 요약"
git push origin main
```

- 푸시가 완료되면 Vercel이 자동으로 새 배포를 시작한다.
- Vercel 대시보드 → 해당 프로젝트 → **Deployments**에서 진행 상황 확인

---

## 요약 표

| 단계 | 하는 일 | 어디서? |
|------|----------|--------|
| 1 | Git 설치·확인 | 로컬 터미널 |
| 2 | GitHub에 빈 저장소 생성 | GitHub 웹 |
| 3 | `git init` → `remote add` → `add` → `commit` → `push` | 로컬 터미널 (프로젝트 폴더) |
| 4 | Vercel에서 "Import"로 해당 Git 저장소 연결 + Build/Output 설정 | Vercel 웹 |
| 5 | 이후 수정 시 `add` → `commit` → `push` | 로컬 터미널 |

---

## 정리

- **Git에 올리는 것** = 로컬에서 `git add` → `commit` → `push` (3단계).
- **Vercel** = 그 GitHub 저장소를 연결해 두면, 푸시할 때마다 자동으로 빌드·배포해 준다.
- "Vercel을 통해 Git에 올린다"기보다 **"Git에 올리면 Vercel이 그걸 받아서 배포한다"**라고 이해하면 된다.
