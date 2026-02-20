/// 보호자 구독 상태 판별 (1개월 무료 체험 + 7일 유예)
///
/// - 활성/만료 예정: 유료 구독 중 → 전체 기능 사용
/// - 무료 체험 중 + createdAt 기준 1개월 이내: trial → 전체 기능 사용
/// - 무료 체험 만료 후 7일 이내: gracePeriod → 전체 기능 + 경고 배너
/// - 그 이후: expired → 알림·기록 열람 제한 + 업그레이드 유도
class SubscriptionState {
  const SubscriptionState._({
    required this.phase,
    required this.isRestricted,
    required this.message,
    this.daysLeftInTrial,
    this.daysLeftInGrace,
  });

  final SubscriptionPhase phase;
  final bool isRestricted;
  final String message;
  final int? daysLeftInTrial;
  final int? daysLeftInGrace;

  bool get isGracePeriod => phase == SubscriptionPhase.gracePeriod;
  bool get isTrial => phase == SubscriptionPhase.trial;
  bool get isActive => phase == SubscriptionPhase.active;
  bool get isExpired => phase == SubscriptionPhase.expired;

  /// 계정 정보로부터 구독 상태 산출
  static SubscriptionState evaluate({
    required String subscriptionStatus,
    required DateTime? createdAt,
    DateTime? subscriptionExpiry,
  }) {
    final now = DateTime.now();

    // 유료 구독 중 (Firestore: active, expiring_soon)
    if (subscriptionStatus == '활성' || subscriptionStatus == '만료 예정') {
      return SubscriptionState._(
        phase: SubscriptionPhase.active,
        isRestricted: false,
        message: '연 결제 이용 중',
      );
    }

    // Firestore에서 만료됨으로 명시된 경우
    if (subscriptionStatus == '만료됨') {
      return SubscriptionState._(
        phase: SubscriptionPhase.expired,
        isRestricted: true,
        message: '구독이 만료되었습니다. 연 결제를 진행해 주세요.',
      );
    }

    // 무료 체험 또는 상태 미지정 → createdAt 기준으로 판별
    if (createdAt == null) {
      // createdAt 없으면 제한하지 않음 (기존 사용자 호환)
      return SubscriptionState._(
        phase: SubscriptionPhase.active,
        isRestricted: false,
        message: '무료 체험 중',
      );
    }

    final trialEnd = DateTime(createdAt.year, createdAt.month + 1, createdAt.day);
    final graceEnd = trialEnd.add(const Duration(days: 7));

    if (!now.isAfter(trialEnd)) {
      final daysLeft = trialEnd.difference(now).inDays.clamp(0, 31);
      return SubscriptionState._(
        phase: SubscriptionPhase.trial,
        isRestricted: false,
        message: '무료 체험 중',
        daysLeftInTrial: daysLeft,
      );
    }

    if (now.isBefore(graceEnd)) {
      final daysLeft = graceEnd.difference(now).inDays;
      return SubscriptionState._(
        phase: SubscriptionPhase.gracePeriod,
        isRestricted: false,
        message: '$daysLeft일 후 알림·기록 열람이 제한됩니다. 연 결제를 권장합니다.',
        daysLeftInGrace: daysLeft.clamp(0, 7),
      );
    }

    // 유예 기간 이후 → 제한
    return SubscriptionState._(
      phase: SubscriptionPhase.expired,
      isRestricted: true,
      message: '무료 체험이 종료되었습니다. 연 결제를 진행해 주세요.',
    );
  }
}

enum SubscriptionPhase {
  active,
  trial,
  gracePeriod,
  expired,
}
