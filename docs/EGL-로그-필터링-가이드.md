# EGL 로그 필터링 가이드

## 문제 상황
터미널에 `D/EGL_emulation` 및 `app_time_stats` 로그가 계속 출력되어 화면이 지저분해집니다.

## 해결 방법

### 방법 1: 제공된 스크립트 사용 (권장)

**절대 `flutter run`을 직접 실행하지 마세요!** 항상 다음 스크립트를 사용하세요:

#### PowerShell에서:
```powershell
.\run-android.ps1
```

#### 특정 에뮬레이터 지정:
```powershell
.\run-android.ps1 -d emulator-5554
```

#### CMD에서:
```cmd
run.bat
```

### 방법 2: 에뮬레이터 선택 스크립트 사용

에뮬레이터를 선택하고 실행:
```powershell
.\run-select-device.ps1
```

이 스크립트도 자동으로 EGL 로그를 필터링합니다.

### 방법 3: 더 강력한 필터링 (필요시)

더 많은 로그를 필터링하려면:
```powershell
.\run-android-filtered.ps1
```

## 필터링되는 로그

다음 로그들이 자동으로 필터링됩니다:
- `D/EGL_emulation`
- `app_time_stats`
- `FrameTracker.*force finish`
- `PRIMARY FOCUS`
- `FocusScopeNode`
- `FocusNode`
- `FocusManager`
- `Root Focus Scope`
- `_ModalScopeState`

## 주의사항

### ❌ 하지 말아야 할 것:
```powershell
flutter run  # 직접 실행하면 EGL 로그가 그대로 출력됨!
```

### ✅ 올바른 방법:
```powershell
.\run-android.ps1  # 스크립트 사용
```

## VSCode에서 실행하는 경우

VSCode의 작업(Tasks)을 사용하면 자동으로 필터링됩니다:
1. `Ctrl+Shift+P` → "Tasks: Run Task"
2. **"Flutter Run (EGL 로그 제외)"** 선택

## 문제 해결

### 여전히 로그가 보이는 경우:

1. **스크립트를 사용하고 있는지 확인**
   - `flutter run`을 직접 실행하지 않았는지 확인

2. **스크립트 재실행**
   ```powershell
   .\run-android.ps1 -d emulator-5554
   ```

3. **터미널 재시작**
   - 기존 터미널을 닫고 새로 열기

4. **더 강력한 필터링 사용**
   ```powershell
   .\run-android-filtered.ps1
   ```

## 참고

- EGL 로그는 Android 에뮬레이터의 그래픽 렌더링 관련 로그입니다
- 개발에는 필요 없으며 화면만 지저분하게 만듭니다
- 제공된 스크립트를 사용하면 자동으로 필터링됩니다
