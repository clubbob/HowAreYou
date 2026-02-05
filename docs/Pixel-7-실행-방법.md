# Pixel 7 실행 방법

## Pixel 7 기기 ID

**Pixel 7 = `emulator-5556`**

## 실행 방법

### 방법 1: 직접 기기 ID 지정 (가장 빠름)

```powershell
.\run-android.ps1 -d emulator-5556
```

또는

```powershell
flutter run -d emulator-5556
```

**주의**: `flutter run`을 직접 사용하면 EGL 로그가 출력됩니다. `.\run-android.ps1` 사용을 권장합니다.

### 방법 2: 번호로 선택 (추천)

```powershell
.\flutter-devices.ps1
```

실행하면:
```
사용 가능한 에뮬레이터:

  [1] sdk gphone64 x86 64 (에뮬레이터) - emulator-5554
  [2] sdk gphone64 x86 64 (에뮬레이터) - emulator-5556

기기를 선택하세요 (1-2): 
```

**Pixel 7을 선택하려면 `2` 입력**

### 방법 3: 에뮬레이터 선택 스크립트

```powershell
.\run-select-device.ps1
```

에뮬레이터 목록이 표시되면 Pixel 7을 선택하세요.

## 기기 구분

| 기기 | 기기 ID | 역할 |
|------|---------|------|
| Pixel 6 | emulator-5554 | 보호자 |
| Pixel 7 | emulator-5556 | 보호 대상자 |

## 빠른 참고

### Pixel 7에서 실행:
```powershell
.\run-android.ps1 -d emulator-5556
```

### Pixel 6에서 실행:
```powershell
.\run-android.ps1 -d emulator-5554
```

## 참고

- `flutter devices` 출력에서 두 번째 에뮬레이터가 Pixel 7입니다
- 기기 ID는 `emulator-5556`입니다
- 스크립트를 사용하면 번호로 쉽게 선택할 수 있습니다
