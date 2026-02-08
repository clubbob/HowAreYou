# JIGUM EOTTAE — FULL REBUILD SPEC v1.0.1
(Flutter + Firebase + Android Studio)

재개발의 **유일한 기준 문서**입니다.  
기존 구현을 폐기하고 재구현할 때 이 SPEC과 이 SPEC이 참조하는 PRD만 따릅니다.  
명시되지 않은 기능은 구현하지 않습니다.

---

## 기준 PRD

- **HowAreYou_PRD_v1.0.md**  
  위 PRD 전체가 적용되며, 특히 **§9 데이터 모델 (설계 고정 조건)** 은 설계 고정 조건입니다.

### 설계 고정 조건 (PRD §9 요약)

- `subjects/{subjectUid}` 의 문서 ID = 보호대상자의 Firebase Auth UID
- `users/{uid}` 의 문서 ID = Auth UID
- subjectUid === users 문서의 uid, 별도 subject 식별자 없음
- Guardian / Mood / 조회 로직은 위 규칙 전제

---

## 재편성 시

- 기능·데이터 구조·화면·API는 PRD와 이 문서에 맞춥니다.
- 앱 변경 단계와 수정 범위는 **docs/앱-변경-단계-및-수정범위.md** (또는 동일 명의 문서)를 참고합니다.
