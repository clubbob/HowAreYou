# Release SHA-1 등록 가이드

---

## 1단계: SHA-1 값 확인

PowerShell에서 실행:

```powershell
cd d:\project\HowAreYou
.\get-release-sha1.ps1
```

> ⚠️ `\get-release-sha1.ps1` (백슬래시만) ❌  
> ✅ `.\get-release-sha1.ps1` (점+백슬래시) — 현재 폴더의 스크립트 실행

- 비밀번호 입력 요청 시 → `key.properties`의 **storePassword** 입력
- 출력된 `AA:BB:CC:DD:...` 형식 값을 **복사**

---

## 2단계: Firebase에 붙여넣기

1. https://console.firebase.google.com/ 접속
2. 프로젝트 **howareyou-1c5de** 선택
3. ⚙️ **프로젝트 설정** → **내 앱**
4. Android 앱 **com.andy.howareyou** 선택 (없으면 com.example.how_are_you 확인)
5. **디지털 지문 추가** 클릭
6. **SHA-1** 선택 후 1단계에서 복사한 값 붙여넣기
7. **저장** 클릭

---

## 막히는 경우

| 상황 | 해결 |
|------|------|
| 비밀번호 모름 | `android/key.properties` 열어서 storePassword 확인 |
| keytool 오류 | Android Studio 설치 후 `jbr\bin\keytool.exe` 경로 사용 |
| com.andy.howareyou 앱 없음 | com.example.how_are_you 앱에 추가해도 됨 (패키지명이 맞는 앱 선택) |
