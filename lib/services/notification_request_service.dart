import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_response_model.dart';

/// 알림 요청 서비스 (Cloud Functions가 처리하도록 Firestore에 요청 문서 생성)
class NotificationRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 보호 대상이 응답했을 때 보호자에게 알림 요청
  /// Cloud Functions가 이 문서를 감지하여 실제 알림 발송
  Future<void> requestResponseNotification({
    required String subjectId,
    required String subjectDisplayName,
    required TimeSlot slot,
    required List<String> guardianUids,
  }) async {
    if (guardianUids.isEmpty) return; // 보호자가 없으면 알림 불필요

    try {
      final slotLabel = slot.label; // '아침', '점심', '저녁'
      
      await _firestore.collection('notification_requests').add({
        'type': 'RESPONSE_RECEIVED',
        'subjectId': subjectId,
        'subjectDisplayName': subjectDisplayName,
        'slot': slot.value,
        'slotLabel': slotLabel,
        'guardianUids': guardianUids,
        'message': '$subjectDisplayName님이 $slotLabel 상태를 확인했습니다',
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
    } catch (e) {
      // 알림 요청 실패는 무시 (응답 저장은 성공했으므로)
      print('알림 요청 실패: $e');
    }
  }

  /// 미회신 알림 요청 (Cloud Functions에서 사용)
  Future<void> requestUnreachableNotification({
    required String subjectId,
    required String subjectDisplayName,
    required List<String> guardianUids,
  }) async {
    if (guardianUids.isEmpty) return;

    try {
      await _firestore.collection('notification_requests').add({
        'type': 'UNREACHABLE',
        'subjectId': subjectId,
        'subjectDisplayName': subjectDisplayName,
        'guardianUids': guardianUids,
        'message': '$subjectDisplayName님이 상태를 확인하지 않고 있습니다',
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
    } catch (e) {
      print('미회신 알림 요청 실패: $e');
    }
  }
}
