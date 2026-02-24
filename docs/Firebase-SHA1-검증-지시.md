# Firebase SHA-1 검증 지시

> Firebase에 등록된 SHA-1이 현재 사용 중인 release keystore와 일치하는지 확인

---

## 현재 Firebase Android 설정 값

| 항목 | 값 |
|------|-----|
| **패키지명** | `com.andy.howareyou` |
| **등록된 SHA-1** | `a6:77:f6:d5:c0:57:3f:ee:5a:90:17:c9:58:79:7c:b7:d7:68:c8:8f` |

---

## 확인 요청

1. **이 SHA-1이 현재 사용 중인 release keystore에서 생성된 SHA-1과 일치하는지 확인**
   ```powershell
   keytool -list -v -keystore android/upload-keystore.jks -alias upload
   ```
   - 비밀번호 입력 시 `key.properties`의 `storePassword` 사용

2. **debug keystore SHA-1이 아니라는 것 확인**
   - debug keystore: `%USERPROFILE%\.android\debug.keystore`
   - release keystore: `android/upload-keystore.jks` (또는 `storeFile` 값)

3. **만약 새 keystore 생성했다면**
   - SHA-1 다시 추출
   - Firebase Console에 추가
   - Google-services.json 재다운로드
   - `android/app/google-services.json` 교체

---

## 왜 지금 확인하냐면

- keystore를 새로 만들었으면 **SHA-1도 바뀜**
- SHA-1이 다르면:
  - Firebase Auth 실패
  - Google 로그인 실패
  - Play 내부 테스트 시 인증 오류 발생 가능

---

## 핵심

지금은 **비밀번호 문제 + SHA 불일치 가능성** 두 축.

**keystore 새로 만들었다면 반드시:**

1. SHA 다시 등록
2. google-services.json 다시 받기

이 두 단계까지 해야 완전 종료.
