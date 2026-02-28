/** 베타 신청 정책 (정식 출시 + 베타 1기 1년 무료 혜택) */
export const BETA = {
  /** 기수 (1기, 2기, ...) - 추후 2기 운영 시 '2'로 변경 */
  cohort: '1',
  /** 기수 표시명 */
  cohortName: '베타 1기',
  /** CTA 버튼 문구 */
  cohortActionLabel: '1년 무료 혜택 신청',
  /** 선착순 제한 인원 */
  limit: 100,
  /** Google Play 앱 상세 페이지 (정식 출시) */
  playStoreUrl: 'https://play.google.com/store/apps/details?id=com.andy.howareyou',
} as const;
