# EGL 로그 완전 제거 가이드

## 문제
터미널에 `D/EGL_emulation` 및 `app_time_stats` 로그가 계속 반복되어 화면이 지저분해집니다.

## 해결 방법

### ⚠️ 중요: flutter run을 직접 실행하지 마세요!

**절대 하지 말아야 할 것:**
```powershell
flutter run  # ❌ 이렇게 하면 EGL 로그가 계속 출력됩니다!
```

### ✅ 올바른 실행 방법

#### 방법 1: 기본 스크립트 사용 (권장)

```powershell
.\run-android.ps1 -d emulator-5554
```

#### 방법 2: 에뮬레이터 선택 스크립트 사용

```powershell
.\run-select-device.ps1
```

#### 방법 3: CMD에서 실행

```cmd
run.bat -d emulator-5554
```

## 현재 실행 중인 앱이 있다면

1. **터미널에서 `q` 입력하여 앱 종료**
2. **스크립트로 다시 실행**:
   ```powershell
   .\run-android.ps1 -d emulator-5554
   ```

## 필터링되는 로그

다음 로그들이 자동으로 필터링됩니다:
- ✅ `D/EGL_emulation`
- ✅ `app_time_stats`
- ✅ `FrameTracker.*force finish`
- ✅ `PRIMARY FOCUS`
- ✅ `FocusScopeNode`
- ✅ `FocusNode`
- ✅ `FocusManager`
- ✅ `Root Focus Scope`
- ✅ `_ModalScopeState`

## VSCode/Cursor에서 실행하는 경우

### 방법 1: 작업(Tasks) 사용
1. `Ctrl+Shift+B` (빌드 작업 실행)
2. 또는 `Ctrl+Shift+P` → "Tasks: Run Task" → **"Flutter Run (EGL 로그 제외)"** 선택

### 방법 2: F5 디버그 실행
1. **F5** 키 눌러서 디버그 모드로 실행
2. 하단 **디버그 콘솔** 탭 클릭
3. 우측 상단 필터 입력란에 `!EGL_emulation` 입력

## 문제 해결

### 여전히 로그가 보이는 경우

1. **현재 앱 종료**: 터미널에서 `q` 입력
2. **스크립트로 재실행**: `.\run-android.ps1 -d emulator-5554`
3. **터미널 재시작**: 기존 터미널 닫고 새로 열기
4. **더 강력한 필터링**: `.\run-android-filtered.ps1 -d emulator-5554`

### 스크립트가 작동하지 않는 경우

PowerShell 실행 정책 확인:
```powershell
Get-ExecutionPolicy
```

제한된 경우:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 체크리스트

- [ ] `flutter run`을 직접 실행하지 않았는가?
- [ ] `.\run-android.ps1` 스크립트를 사용했는가?
- [ ] 현재 실행 중인 앱을 종료(`q`)하고 다시 시작했는가?
- [ ] 터미널을 재시작했는가?

## 참고

- EGL 로그는 Android 에뮬레이터의 그래픽 렌더링 관련 로그입니다
- 개발에는 필요 없으며 화면만 지저분하게 만듭니다
- 제공된 스크립트를 사용하면 자동으로 필터링됩니다
- **핫 리로드(r), 핫 리스타트(R), 종료(q) 등은 정상 작동합니다**
