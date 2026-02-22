class AppConstants {
  /// 보호대상자 초대 링크 베이스 (딥링크 + 미설치 시 웹에서 Play Store 유도)
  static const String inviteBaseUrl = 'https://howareyou-1c5de.web.app/invite';

  /// 약관/개인정보처리방침 URL (홈페이지)
  static const String termsUrl = 'https://how-are-you-nu.vercel.app/terms';
  static const String privacyUrl = 'https://how-are-you-nu.vercel.app/privacy';
  /// 1:1 문의 (홈페이지 또는 문의 페이지)
  static const String inquiryUrl = 'https://how-are-you-nu.vercel.app';
  /// 공지사항 (홈페이지 공지 섹션)
  static const String announcementsUrl = 'https://how-are-you-nu.vercel.app/#announcements';

  // 알림 채널 ID
  static const String dailyMoodCheckChannelId = 'daily_mood_check';
  static const String dailyMoodCheckChannelName = '일일 상태 확인';
  static const String dailyMoodCheckChannelDescription =
      '하루 1번 상태를 확인하는 알림';

  // 알림 시간
  static const int morningHour = 8;
  static const int morningMinute = 0;
  static const int noonHour = 12;
  static const int noonMinute = 0;
  static const int eveningHour = 18;
  static const int eveningMinute = 0;

  // 알림 ID
  static const int morningNotificationId = 1;
  static const int noonNotificationId = 2;
  static const int eveningNotificationId = 3;

  // Firestore 컬렉션 이름
  static const String usersCollection = 'users';
  static const String subjectsCollection = 'subjects';
  static const String promptsCollection = 'prompts';
  /// mood, note — 본인(보호대상자)만 접근. prompts는 answeredAt만 (보호자 "기록 여부" 공개)
  static const String privatePromptsCollection = 'private_prompts';
  static const String alertsCollection = 'alerts';

  /// 보호자→대상자 대기 초대 (가입 시 자동 연결)
  static const String pendingGuardianInvitesCollection = 'pending_guardian_invites';
  /// 대상자→보호자 대기 초대 (가입 시 자동 연결)
  static const String pendingSubjectInvitesCollection = 'pending_subject_invites';

  /// 1:1 문의 컬렉션
  static const String inquiriesCollection = 'inquiries';

  /// 서비스 개선 피드백 컬렉션
  static const String serviceFeedbackCollection = 'service_feedback';

  /// 업그레이드(연 결제) 안내 페이지
  static const String upgradeUrl = 'https://how-are-you-nu.vercel.app/#pricing';
}
