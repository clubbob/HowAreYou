# Firebase 배포 가이드

## 📋 배포 전 확인 사항

### 1. Firebase CLI 설치 확인
터미널에서 다음 명령어로 확인:
```powershell
firebase --version
```

**설치되어 있지 않다면**:
```powershell
npm install -g firebase-tools
```

### 2. Firebase 로그인 확인
```powershell
firebase login
```
- 브라우저가 열리면 Google 계정으로 로그인
- 이미 로그인되어 있으면 "Already logged in" 메시지 표시

### 3. 프로젝트 확인
```powershell
firebase projects:list
```
- `howareyou-1c5de` 프로젝트가 목록에 있는지 확인

---

## 🚀 배포 방법

### 방법 1: Cursor/VS Code 터미널 사용 (권장)

#### 1단계: 터미널 열기
- **Cursor/VS Code**: `Ctrl + `` (백틱) 또는 `터미널` 메뉴 → `새 터미널`
- 또는 상단 메뉴: `터미널` → `새 터미널`

#### 2단계: 프로젝트 디렉토리로 이동
터미널에 자동으로 프로젝트 루트(`d:\project\HowAreYou`)에 있을 것입니다.
확인:
```powershell
pwd
# 또는
cd
```
출력 예: `d:\project\HowAreYou`

#### 3단계: Firestore Rules 배포
```powershell
firebase deploy --only firestore:rules
```

**예상 출력**:
```
=== Deploying to 'howareyou-1c5de'...

i  deploying firestore
i  firestore: checking firestore.rules for compilation errors...
✔  firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

#### 4단계: Cloud Functions 배포
```powershell
firebase deploy --only functions
```

**예상 출력** (처음 배포 시):
```
=== Deploying to 'howareyou-1c5de'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudresourcemanager.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudresourcemanager.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 20 function onResponseCreated(us-central1)...
i  functions: creating Node.js 20 function checkUnreachableSubjects(us-central1)...
✔  functions[onResponseCreated(us-central1)]: Successful create operation.
✔  functions[checkUnreachableSubjects(us-central1)]: Successful create operation.

✔  Deploy complete!
```

**이미 배포된 경우**:
```
=== Deploying to 'howareyou-1c5de'...

i  deploying functions
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: updating Node.js 20 function onResponseCreated(us-central1)...
i  functions: updating Node.js 20 function checkUnreachableSubjects(us-central1)...
✔  functions[onResponseCreated(us-central1)]: Successful update operation.
✔  functions[checkUnreachableSubjects(us-central1)]: Successful update operation.

✔  Deploy complete!
```

---

### 방법 2: Windows PowerShell 직접 실행

#### 1단계: PowerShell 열기
- `Win + X` → `Windows PowerShell` 또는 `터미널`
- 또는 시작 메뉴에서 "PowerShell" 검색

#### 2단계: 프로젝트 디렉토리로 이동
```powershell
cd d:\project\HowAreYou
```

#### 3단계: 배포 명령어 실행
```powershell
# Firestore Rules 배포
firebase deploy --only firestore:rules

# Cloud Functions 배포
firebase deploy --only functions
```

---

## 🔍 배포 확인

### Firestore Rules 확인
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `howareyou-1c5de`
3. 왼쪽 메뉴: `Firestore Database` → `규칙` 탭
4. 배포된 규칙이 표시되는지 확인

### Cloud Functions 확인
1. Firebase Console → `Functions` 메뉴
2. 함수 목록에서 확인:
   - `onResponseCreated` (Firestore 트리거)
   - `checkUnreachableSubjects` (Scheduler 트리거)
3. 각 함수 클릭 → `로그` 탭에서 실행 로그 확인

---

## ⚠️ 주의 사항

### 1. 배포 중 오류 발생 시

**오류 예시**:
```
Error: Functions did not deploy properly.
```

**해결 방법**:
1. `functions` 폴더로 이동
2. 의존성 재설치:
   ```powershell
   cd functions
   npm install
   cd ..
   ```
3. 다시 배포:
   ```powershell
   firebase deploy --only functions
   ```

### 2. Firestore Rules 문법 오류 시

**오류 예시**:
```
Error: Syntax error in firestore.rules
```

**해결 방법**:
1. `firestore.rules` 파일 문법 확인
2. Firebase Console → Firestore → 규칙에서 "테스트" 버튼으로 검증

### 3. 배포 권한 오류 시

**오류 예시**:
```
Error: Permission denied
```

**해결 방법**:
1. Firebase 로그인 확인:
   ```powershell
   firebase login
   ```
2. 프로젝트 확인:
   ```powershell
   firebase use howareyou-1c5de
   ```

---

## 📝 배포 체크리스트

배포 전:
- [ ] `firestore.rules` 파일 문법 확인
- [ ] `functions/index.js` 파일 문법 확인
- [ ] Firebase CLI 설치 및 로그인 확인
- [ ] 프로젝트 디렉토리 확인

배포 중:
- [ ] Firestore Rules 배포 성공 확인
- [ ] Cloud Functions 배포 성공 확인

배포 후:
- [ ] Firebase Console에서 Rules 확인
- [ ] Firebase Console에서 Functions 확인
- [ ] Functions 로그 확인 (선택 사항)

---

## 🎯 빠른 배포 명령어 (한 번에)

두 가지를 한 번에 배포하려면:
```powershell
firebase deploy --only firestore:rules,functions
```

---

## 💡 추가 팁

### 배포 전 테스트 (선택 사항)
```powershell
# Firestore Rules 테스트
firebase emulators:start --only firestore

# Functions 테스트 (로컬)
firebase emulators:start --only functions
```

### 배포 로그 확인
배포 후 Firebase Console에서:
- Functions → 각 함수 → `로그` 탭
- Firestore → `사용량` 탭

---

**작성일**: 2026-01-27
