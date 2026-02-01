# Vercel을 통해 올리는 방법

> 다른 웹 프로젝트처럼 이 앱도 **Git에 올리고 + Vercel에 연결**하면, **한 페이지(Vercel 대시보드)**에서 프로젝트·버전·배포 이력을 같이 볼 수 있습니다.

---

## 전체 흐름

1. **Cursor 터미널**에서 코드를 **Git(GitHub)** 에 올린다. (`git add` → `commit` → `push`)
2. **Vercel**에서 그 **GitHub 저장소를 Import** 해서 프로젝트로 추가한다.
3. 이후 **푸시할 때마다** Vercel이 자동으로 빌드·배포하고, 대시보드에서 이력 확인.

---

## 1. Git 설치 여부 확인

Cursor에서 **터미널**을 연다. (Terminal → New Terminal, 또는 `` Ctrl+` ``)

**이 터미널**에서:

```
git --version
```

- 버전이 나오면 다음 단계로.
- `'git' is not recognized`면 [git-scm.com](https://git-scm.com/download/win)에서 설치 후 Cursor를 다시 연다.

---

## 2. GitHub에 저장소 만들기 (한 번만)

1. [github.com](https://github.com) 로그인
2. 오른쪽 상단 **+** → **New repository**
3. 설정:
   - **Repository name**: `HowAreYou` (또는 원하는 이름)
   - **Public** 선택
   - **Add a README file** 등은 **체크하지 않음**
4. **Create repository** 클릭
5. 생성된 페이지에서 **저장소 URL** 복사  
   - 예: `https://github.com/내아이디/HowAreYou.git`

---

## 3. Cursor 터미널에서 GitHub에 올리기

### 3-1. 프로젝트 폴더로 이동

```
cd d:\project\HowAreYou
```

### 3-2. Git 초기화 (한 번만)

```
git init
```

### 3-3. 원격 저장소 연결

`내아이디`, `HowAreYou`를 2단계에서 만든 저장소에 맞게 바꾼다.

```
git remote add origin https://github.com/내아이디/HowAreYou.git
```

- 이미 `origin`이 있다는 오류면:  
  `git remote set-url origin https://github.com/내아이디/HowAreYou.git`

### 3-4. 전체 스테이징 → 커밋 → 푸시

```
git add .
git commit -m "Initial commit: HowAreYou Flutter app"
git branch -M main
git push -u origin main
```

- 처음 푸시 시 GitHub 로그인/인증 창이 뜰 수 있다.
- 끝나면 GitHub 저장소 페이지에서 코드가 보여야 한다.

---

## 4. Vercel에 연결해서 "한 페이지에서 관리"

### 4-1. Vercel 로그인

- [vercel.com](https://vercel.com) 접속 → **Log In**
- **Continue with GitHub** 로 GitHub 계정 연결

### 4-2. 프로젝트 추가 (GitHub 저장소 Import)

1. 대시보드에서 **Add New…** → **Project**
2. **Import Git Repository**에서 **HowAreYou** 저장소 선택
3. **Import** 클릭

### 4-3. 빌드 설정 (Flutter Web 배포할 경우)

- **Framework Preset**: **Other**
- **Root Directory**: 비워 두기 (또는 `.`)
- **Build Command**: `flutter build web`
- **Output Directory**: `build/web`

> Vercel 기본 환경에 Flutter가 없으면 빌드가 실패할 수 있다.  
> 그럴 때는 **로컬에서 `flutter build web` 실행 후 `build/web` 결과만 배포**하거나, Vercel **Install Command**에 Flutter 설치 스크립트를 넣는 방식으로 설정한다.

### 4-4. 환경 변수 (필요할 때만)

- Firebase 등 쓰면 **Environment Variables**에 값 추가

### 4-5. Deploy

- **Deploy** 클릭
- 완료되면 **Visit**로 배포된 주소 확인

---

## 5. 이후: 수정할 때마다 올리는 방법

코드 수정 후 **이 터미널**에서:

```
cd d:\project\HowAreYou

git add .
git commit -m "수정 내용 한 줄 요약"
git push
```

- 푸시가 끝나면 **Vercel이 자동으로 새 배포**를 시작한다.
- **Vercel 대시보드** → 해당 프로젝트 → **Deployments**에서 진행 상황·버전 확인.

---

## 6. 한 번에 복사해서 쓸 수 있는 예시 (처음 한 번)

**Cursor 터미널**에서 순서대로 실행. `내아이디`, `HowAreYou`만 본인 저장소에 맞게 바꾼다.

```
cd d:\project\HowAreYou
git init
git remote add origin https://github.com/내아이디/HowAreYou.git
git add .
git commit -m "Initial commit: HowAreYou Flutter app"
git branch -M main
git push -u origin main
```

그 다음 **Vercel** → Add New → Project → **HowAreYou** 저장소 Import → 설정 후 Deploy.

---

## 요약 표

| 단계 | 하는 일 | 어디서? |
|------|----------|--------|
| 1 | Git 설치·확인 | Cursor 터미널 |
| 2 | GitHub에 저장소 생성 | GitHub 웹 |
| 3 | `git init` → `remote add` → `add` → `commit` → `push` | Cursor 터미널 |
| 4 | Vercel에서 해당 저장소 Import + 빌드 설정 → Deploy | Vercel 웹 |
| 5 | 이후 수정 시 `add` → `commit` → `push` | Cursor 터미널 |

---

## 정리

- **올리는 행위** = Cursor 터미널에서 `git add` → `git commit` → `git push` (Vercel 없이도 동일).
- **Vercel을 통해 올린다** = 같은 방식으로 Git에 푸시하고, **그 저장소를 Vercel에 연결**해 두면, **한 페이지(대시보드)**에서 이 앱 포함 여러 프로젝트·버전·배포 이력을 같이 볼 수 있다.
