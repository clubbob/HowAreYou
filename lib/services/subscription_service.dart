/// 보호자 구독 상태
/// - 프리미엄(isRestricted: false): 보호대상자 무제한
/// - 무료(isRestricted: true): 보호대상자 2명까지
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

  /// 구독 상태 평가. 프리미엄이면 isRestricted: false (보호대상자 무제한)
  static SubscriptionState evaluate({
    String subscriptionStatus = '',
    DateTime? createdAt,
    DateTime? subscriptionExpiry,
  }) {
    final now = DateTime.now();
    final status = (subscriptionStatus ?? '').toString().toLowerCase();
    final isActive = status == 'active' || status == 'premium';
    final notExpired = subscriptionExpiry == null || subscriptionExpiry.isAfter(now);

    if (isActive && notExpired) {
      return SubscriptionState._(
        phase: SubscriptionPhase.active,
        isRestricted: false,
        message: '프리미엄 이용 중',
      );
    }
    return SubscriptionState._(
      phase: SubscriptionPhase.active,
      isRestricted: true,
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
