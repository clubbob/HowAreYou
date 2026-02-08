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

---

## Pixel 6은 되는데 Pixel 7만 작동하지 않을 때

### 1. Pixel 7 에뮬레이터가 켜져 있는지 확인

- **Device Manager**에서 Pixel 7 AVD를 **실행**한 뒤, 다시 `flutter run -d emulator-5556` 실행.
- 터미널에서 `flutter devices` 입력 시 `emulator-5556`이 목록에 있어야 합니다. 없으면 해당 AVD를 먼저 실행하세요.

### 2. 기기 ID로 Pixel 7만 지정해서 실행

- 실행 시 반드시 **Pixel 7 기기 ID**를 넣어서 실행하세요.  
  (기본으로 Pixel 6이 선택되면 Pixel 7에서는 안 뜹니다.)

```powershell
.\run-android.ps1 -d emulator-5556
```

또는

```powershell
flutter run -d emulator-5556
```

### 3. Pixel 7 AVD가 “Google Play 포함” 이미지인지 확인

- Firebase 전화번호 인증 등은 **Google Play 서비스**가 있는 시스템 이미지가 필요합니다.
- **Device Manager** → Pixel 7 AVD 편집(연필 아이콘) → **System image**가 **Google Play** 표시가 있는 이미지(예: “Tiramisu” API 33, “Upside Down Cake” API 34)인지 확인하세요.
- “Google APIs”만 있고 Play 표시가 없으면, **Google Play 포함** 이미지를 선택한 새 AVD를 만들어 Pixel 7처럼 사용하는 것을 권장합니다.

### 4. 에뮬레이터 초기화 (한 번 시도)

- Pixel 7 에뮬레이터가 느리거나 앱이 아예 안 뜨면:
  - **Device Manager** → Pixel 7 AVD 옆 **▼** → **Wipe Data** 또는 **Cold Boot Now** 후 다시 실행해 보세요.

### 5. 앱만 다시 설치해서 실행

- Pixel 7에서만 크래시하거나 설치가 꼬인 것 같으면, 해당 기기에만 앱을 지우고 다시 실행하세요.

```powershell
flutter run -d emulator-5556
```

(실행 시 기존 앱이 있으면 덮어쓰기 설치됩니다. 그래도 문제면 위 4번처럼 에뮬레이터 Wipe Data 후 다시 시도.)

### 요약

| 확인 항목 | 내용 |
|-----------|------|
| 에뮬레이터 실행 | Pixel 7(emulator-5556)이 켜져 있는지 |
| 실행 시 기기 지정 | `-d emulator-5556` 으로 Pixel 7 지정 |
| 시스템 이미지 | Google Play 포함 이미지 사용 |
| 이상 시 | Wipe Data / Cold Boot 후 재실행 |
