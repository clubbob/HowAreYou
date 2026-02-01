# Vercel Flutter Web 빌드 실패 해결

Vercel 기본 환경에는 Flutter가 없어서 `flutter build web`이 실패합니다. 아래 두 방법 중 하나를 쓰면 됩니다.

---

## 방법 A: 로컬에서 빌드 후 `build/web`만 푸시 (권장)

Vercel에서는 **빌드를 하지 않고**, 이미 만든 `build/web` 폴더만 배포합니다.

### 1. Vercel 프로젝트 설정 변경

Vercel 대시보드 → **HowAreYou** 프로젝트 → **Settings** → **General** → **Build & Output Settings**:

- **Build Command**: 비우기 또는 `echo "Using pre-built web"`  
  (Flutter를 실행하지 않도록)
- **Output Directory**: `build/web` (그대로)
- **Install Command**: 비우기

저장 후 **Redeploy** 하지 말고, 아래 2단계를 먼저 진행합니다.

### 2. 로컬에서 웹 빌드 후 푸시

Cursor 터미널에서:

```powershell
cd D:\project\HowAreYou
flutter build web
git add -f build/web
git commit -m "deploy: Flutter web build"
git push
```

- `build/`는 `.gitignore`에 있으므로 `git add -f build/web`으로 강제 추가합니다.
- 푸시 후 Vercel이 자동으로 새 배포를 하며, **Output Directory**가 `build/web`이므로 그 안의 파일을 배포합니다.

### 3. 이후 웹 배포할 때마다

코드 수정 후 웹도 다시 배포하려면:

```powershell
flutter build web
git add -f build/web
git commit -m "deploy: web update"
git push
```

---

## 방법 B: Vercel에서 Flutter 설치 후 빌드

Vercel **Install Command**에서 Flutter를 설치한 뒤, 기존처럼 `flutter build web`을 쓰는 방법입니다.  
빌드 시간이 길고(수 분), 타임아웃이 날 수 있습니다.

### Vercel 설정

**Settings** → **General** → **Build & Output Settings** → **Override** 켜기:

- **Install Command** (Override):
  ```bash
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable && export PATH="$PATH:$(pwd)/flutter/bin" && flutter precache --web
  ```
- **Build Command**: `flutter build web --release`
- **Output Directory**: `build/web`

그 다음 **Deployments**에서 **Redeploy** 합니다.

- Flutter 클론·설치 때문에 첫 배포는 5~10분 걸릴 수 있고, 타임아웃이 나면 방법 A를 쓰는 것이 좋습니다.

---

## 요약

| 방법 | 장점 | 단점 |
|------|------|------|
| **A. 로컬 빌드 후 푸시** | 설정 단순, 배포 안정적 | 웹 배포할 때마다 로컬에서 `flutter build web` 필요 |
| **B. Vercel에서 Flutter 설치** | 푸시만 하면 Vercel이 빌드 | 첫 빌드 느림, 타임아웃 가능 |

**추천:** 방법 A.
