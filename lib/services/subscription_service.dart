/// 보호자 구독 상태 (무료 전환: 모든 사용자 전체 기능 사용)
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

  /// 무료 전환: 항상 전체 기능 사용 가능
  static SubscriptionState evaluate({
    String subscriptionStatus = '',
    DateTime? createdAt,
    DateTime? subscriptionExpiry,
  }) {
    return SubscriptionState._(
      phase: SubscriptionPhase.active,
      isRestricted: false,
      message: '무료 이용 중',
    );
  }
}

enum SubscriptionPhase {
  active,
  trial,
  gracePeriod,
  expired,
}
