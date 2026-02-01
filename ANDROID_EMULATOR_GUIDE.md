# Android 에뮬레이터 만들기 가이드

PC에서 전화 인증(OTP)을 테스트하려면 Android 에뮬레이터에서 앱을 실행해야 합니다.  
Android Studio로 에뮬레이터를 만드는 단계를 정리했습니다.

---

## 사전 요구사항

- **Android Studio** 설치 완료
- **Android SDK** 설치 완료 (Android Studio 설치 시 함께 설치됨)

---

## 1단계: Device Manager 열기

1. **Android Studio** 실행
2. 상단 메뉴에서 **Tools** → **Device Manager** 클릭  
   - 또는 오른쪽 사이드바의 **Device Manager** 아이콘(휴대폰 모양) 클릭
3. **Device Manager** 창이 열리면 **"Create Device"** 버튼 클릭

---

## 2단계: 하드웨어 선택 (Phone)

1. **Category**에서 **Phone** 선택 (기본 선택됨)
2. 목록에서 기기 선택 (권장: **Pixel 6** 또는 **Pixel 5**)
   - API 레벨이 너무 낮은 기기는 건너뛰기
3. **Next** 클릭

---

## 3단계: 시스템 이미지 다운로드 및 선택

1. **Release Name** 열에서 사용할 Android 버전 선택
   - **권장: "Tiramisu" (API 33)** 또는 **"UpsideDownCake" (API 34)**
   - 옆에 **Download** 링크가 있으면 클릭해 다운로드 (처음 한 번만)
2. 다운로드 완료 후 해당 행 선택
3. **Next** 클릭

**다운로드가 필요한 경우:**
- "Download" 클릭 → 라이선스 동의 → 다운로드 완료 대기 (수 분 소요)

---

## 4단계: AVD 설정 확인

1. **AVD Name**: 원하는 이름 입력 (예: `Pixel_6_API_33`) 또는 기본값 유지
2. **Startup orientation**: **Portrait** (세로) 권장
3. **Advanced Settings** (선택 사항)
   - RAM: 2048 MB 이상 권장
   - 내부 저장소: 기본값 유지
4. **Finish** 클릭

---

## 5단계: 에뮬레이터 실행

1. **Device Manager** 목록에 방금 만든 기기가 보임
2. 해당 기기 오른쪽의 **▶ (재생)** 버튼 클릭
3. 에뮬레이터 창이 켜질 때까지 대기 (첫 실행은 1~2분 걸릴 수 있음)
4. Android 홈 화면이 보이면 준비 완료

---

## 6단계: Flutter 앱을 에뮬레이터에서 실행

### 방법 1: 터미널에서 실행

1. 에뮬레이터가 **실행 중인 상태**에서 터미널(PowerShell 또는 CMD) 열기
2. 다음 명령어 실행:

```powershell
cd d:\project\HowAreYou
C:\src\flutter\bin\flutter devices
```

- 목록에 **emulator-5554** 같은 항목이 보이면 에뮬레이터가 인식된 것입니다.

3. 앱 실행:

```powershell
C:\src\flutter\bin\flutter run
```

- 에뮬레이터가 하나만 있으면 자동으로 그 기기에 설치·실행됩니다.
- 여러 기기가 있으면 `flutter run -d emulator-5554` 처럼 `-d` 뒤에 기기 ID를 지정할 수 있습니다.

### 방법 2: Cursor/VS Code에서 실행

1. 에뮬레이터 실행
2. Cursor 하단 **디버그** 영역에서 실행 구성 선택 후 **실행(F5)** 또는 **Run** 버튼 클릭
3. 기기 목록에서 **에뮬레이터** 선택

---

## 7단계: 전화 인증(OTP) 테스트

1. 에뮬레이터에서 앱이 실행되면 **로그인** 화면으로 이동
2. 전화번호 입력: **010-6391-4520** (Firebase Console에 등록한 테스트 번호)
3. **인증 코드 전송** 클릭
4. 인증 코드 입력: **123456** (Firebase Console에 등록한 테스트 코드)
5. **인증 확인** 클릭 → 로그인 완료 확인

---

## 문제 해결

### 에뮬레이터가 목록에 안 보일 때

- **flutter doctor** 실행 후 Android 관련 항목 확인:
  ```powershell
  C:\src\flutter\bin\flutter doctor
  ```
- Android Studio에서 **Tools** → **SDK Manager** → **SDK Tools** 탭에서 **Android SDK Command-line Tools** 설치 여부 확인
- `ANDROID_HOME` 환경 변수가 설정되어 있는지 확인  
  (일반적으로 `C:\Users\사용자명\AppData\Local\Android\Sdk`)

### 에뮬레이터가 느릴 때

- **Device Manager** → 해당 AVD **연필(편집)** 아이콘 클릭
- **Graphics**: **Hardware - GLES 2.0** 선택
- **RAM** 2048 MB 이상으로 설정 후 저장

### "인증 코드 전송" 후에도 코드가 안 오는 경우

- Firebase Console에서 **테스트 전화번호**가 **+82 10-6391-4520**, 인증 코드 **123456**으로 등록되어 있는지 확인
- 전화번호는 **010-6391-4520**으로 입력해도 앱에서 **+821063914520**으로 변환되어 전송됨

### HAXM / Hyper-V 관련 오류 (Windows)

- Windows 10/11에서는 **Windows Hypervisor Platform** 또는 **Hyper-V** 사용
- **제어판** → **프로그램 및 기능** → **Windows 기능 켜기/끄기**에서  
  **Hyper-V** 또는 **Windows Hypervisor Platform** 활성화 후 PC 재부팅

---

## 요약 체크리스트

- [ ] Android Studio에서 Device Manager 열기
- [ ] Create Device → Phone → 기기 선택 (예: Pixel 6)
- [ ] 시스템 이미지 다운로드 후 선택 (API 33 이상 권장)
- [ ] AVD 이름 설정 후 Finish
- [ ] 에뮬레이터 재생 버튼으로 실행
- [ ] `flutter run`으로 앱을 에뮬레이터에서 실행
- [ ] 테스트 전화번호 + 인증 코드로 로그인 테스트

이 순서대로 진행하면 PC에서 Android 에뮬레이터를 만들고, 그 위에서 전화 인증까지 테스트할 수 있습니다.
