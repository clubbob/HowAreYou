# Vercel을 통해 Git으로 올리기 — 지금 따라하기

아래 순서대로 **1 → 2 → 3 → 4**만 하면 됩니다.

---

## 1단계: GitHub에 저장소 만들기 (브라우저)

1. [github.com](https://github.com) 접속 후 로그인
2. 오른쪽 상단 **+** → **New repository**
3. **Repository name**: `HowAreYou` (또는 원하는 이름)
4. **Public** 선택
5. **Add a README file** / **Add .gitignore** — **체크하지 않음**
6. **Create repository** 클릭
7. 생성된 페이지에서 **저장소 URL** 복사  
   - 예: `https://github.com/내아이디/HowAreYou.git`  
   - **이 URL을 2단계에서 씁니다.**

---

## 2단계: Cursor 터미널에서 Git에 올리기

Cursor에서 **터미널**을 연다. (`` Ctrl+` `` 또는 Terminal → New Terminal)

**아래 명령을 순서대로 한 줄씩 입력한다.**  
`내아이디`와 `HowAreYou`는 **1단계에서 만든 저장소 URL에 맞게** 바꾼다.

```bash
cd d:\project\HowAreYou
```

```bash
git init
```

- 이미 Git 저장소라는 메시지가 나와도 다음으로 진행한다.

```bash
git remote add origin https://github.com/내아이디/HowAreYou.git
```

- `origin`이 이미 있다는 오류가 나오면:
  ```bash
  git remote set-url origin https://github.com/내아이디/HowAreYou.git
  ```

```bash
git add .
```

```bash
git commit -m "Initial commit: HowAreYou Flutter app"
```

```bash
git branch -M main
```

```bash
git push -u origin main
```

- 처음이면 GitHub **로그인/인증** 창이 뜰 수 있다. 완료하면 푸시가 끝난다.
- 끝나면 **GitHub 저장소 페이지**에서 코드가 보여야 한다.

---

## 3단계: Vercel에 연결 (브라우저)

1. [vercel.com](https://vercel.com) 접속 → **Log In**
2. **Continue with GitHub** 로 GitHub 계정 연결
3. 대시보드에서 **Add New…** → **Project**
4. **Import Git Repository**에서 방금 푸시한 **HowAreYou** 저장소 선택
5. **Import** 클릭
6. **Framework Preset**: **Other** (또는 그대로)
7. **Build Command**: `flutter build web`  
   **Output Directory**: `build/web`  
   (Flutter 웹 배포 안 할 거면 비워 두어도 됨)
8. **Deploy** 클릭
9. 끝나면 **Visit**로 배포 주소 확인 (또는 대시보드에서만 관리해도 됨)

---

## 4단계: 확인

- **GitHub**: 저장소 페이지에 HowAreYou 코드가 보이면 성공
- **Vercel**: 대시보드에 HowAreYou 프로젝트가 보이면 성공

이후 코드 수정할 때마다 **Cursor 터미널**에서:

```bash
cd d:\project\HowAreYou
git add .
git commit -m "수정 내용 한 줄"
git push
```

만 실행하면 GitHub에 올라가고, Vercel에 연결해 두었으면 자동으로 새 배포가 뜰 수 있다.

---

## 한 번에 복사해서 쓸 때 (2단계용)

아래 블록 전체를 복사한 뒤 Cursor 터미널에 붙여 넣고 실행한다.

```bash
cd d:\project\HowAreYou
git init
git remote add origin https://github.com/clubbob/HowAreYou.git
git add .
git commit -m "Initial commit: HowAreYou Flutter app"
git branch -M main
git push -u origin main
```

---

## 막히는 경우

| 상황 | 해결 |
|------|------|
| `git`을 찾을 수 없음 | [git-scm.com](https://git-scm.com/download/win)에서 Git 설치 후 Cursor 재시작 |
| `origin`이 이미 있음 | `git remote set-url origin https://github.com/내아이디/HowAreYou.git` 실행 |
| 푸시 시 인증 실패 | GitHub에서 Personal Access Token 생성 후 비밀번호 자리에 토큰 입력 |
| Vercel에 HowAreYou가 안 보임 | Vercel 로그인 시 사용한 GitHub 계정과 저장소 소유 계정이 같은지 확인 |
