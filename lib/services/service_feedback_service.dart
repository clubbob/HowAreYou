import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// 만족도 평가 옵션
enum SatisfactionLevel {
  verySatisfied('매우 만족', 5),
  satisfied('만족', 4),
  neutral('보통', 3),
  unsatisfactory('아쉬움', 2),
  veryUnsatisfied('많이 불편함', 1);

  final String label;
  final int value;
  const SatisfactionLevel(this.label, this.value);
}

/// 계속 사용 의향 옵션
enum ContinueIntent {
  willContinue('계속 사용할 예정입니다'),
  considering('고민 중입니다'),
  willNotContinue('사용하지 않을 것 같습니다');

  final String label;
  const ContinueIntent(this.label);
}

/// 서비스 개선 피드백 모델
class ServiceFeedbackModel {
  final String userId;
  final String? userPhone;
  final String? userDisplayName;
  final int satisfaction; // 1~5
  final String? inconvenience;
  final String? improvementIdea;
  final String? continueIntent;
  final DateTime createdAt;

  ServiceFeedbackModel({
    required this.userId,
    this.userPhone,
    this.userDisplayName,
    required this.satisfaction,
    this.inconvenience,
    this.improvementIdea,
    this.continueIntent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'satisfaction': satisfaction,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (userPhone != null && userPhone!.isNotEmpty) map['userPhone'] = userPhone;
    if (userDisplayName != null && userDisplayName!.isNotEmpty) map['userDisplayName'] = userDisplayName;
    if (inconvenience != null && inconvenience!.isNotEmpty) map['inconvenience'] = inconvenience;
    if (improvementIdea != null && improvementIdea!.isNotEmpty) map['improvementIdea'] = improvementIdea;
    if (continueIntent != null && continueIntent!.isNotEmpty) map['continueIntent'] = continueIntent;
    return map;
  }
}

/// 서비스 개선 피드백 서비스
class ServiceFeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 피드백 제출
  Future<void> submitFeedback(ServiceFeedbackModel feedback) async {
    await _firestore
        .collection(AppConstants.serviceFeedbackCollection)
        .add(feedback.toMap());
  }
}
