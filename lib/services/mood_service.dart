import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/mood_response_model.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 한국 시간(Asia/Seoul) 기준 현재 시각
  static DateTime _nowKorea() {
    try {
      final k = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
      return DateTime(k.year, k.month, k.day, k.hour, k.minute, k.second);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> saveMoodResponse({
    required String subjectId,
    required TimeSlot slot,
    required Mood mood,
    String? note,
  }) async {
    final now = _nowKorea();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final dateSlot = '${dateStr}_${slot.value}';

    final response = MoodResponseModel(
      subjectId: subjectId,
      dateSlot: dateSlot,
      slot: slot,
      answeredAt: now,
      mood: mood,
      note: note,
    );

    // 응답 저장 (Firestore 트리거가 자동으로 보호자에게 알림 발송)
    await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(dateSlot)
        .set(response.toMap());
    
    // 최적화: notification_requests 컬렉션 제거
    // Firestore 트리거(onResponseCreated)가 자동으로 보호자에게 알림 발송
  }

  Future<bool> hasRespondedToday({
    required String subjectId,
    required TimeSlot slot,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final dateSlot = '${dateStr}_${slot.value}';

    final doc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(dateSlot)
        .get();

    return doc.exists;
  }

  Future<TimeSlot?> getCurrentTimeSlot() async {
    final now = _nowKorea();
    final hour = now.hour;

    if (hour >= 6 && hour < 11) {
      return TimeSlot.morning;
    } else if (hour >= 11 && hour < 16) {
      return TimeSlot.noon;
    } else if (hour >= 16) {
      return TimeSlot.evening;
    }

    return null;
  }

  /// 오늘 아침/점심/저녁 각 시간대별 응답 여부·내용 (보호자 대시보드용)
  Future<Map<TimeSlot, MoodResponseModel?>> getTodayResponses(
    String subjectId,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final result = <TimeSlot, MoodResponseModel?>{};

    for (final slot in TimeSlot.values) {
      final dateSlot = '${dateStr}_${slot.value}';
      final doc = await _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('prompts')
          .doc(dateSlot)
          .get();

      if (doc.exists && doc.data() != null) {
        result[slot] = MoodResponseModel.fromMap(
          doc.data() as Map<String, dynamic>,
          dateSlot,
        );
      } else {
        result[slot] = null;
      }
    }
    return result;
  }

  /// 최근 7일 응답 이력 (보호자 대시보드용). 날짜 문자열(YYYY-MM-DD) → (시간대별 응답)
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getLast7DaysResponses(
    String subjectId,
  ) async {
    final now = _nowKorea();
    final result = <String, Map<TimeSlot, MoodResponseModel?>>{};

    for (var d = 0; d < 7; d++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayResponses = <TimeSlot, MoodResponseModel?>{};

      for (final slot in TimeSlot.values) {
        final dateSlot = '${dateStr}_${slot.value}';
        final doc = await _firestore
            .collection('subjects')
            .doc(subjectId)
            .collection('prompts')
            .doc(dateSlot)
            .get();

        if (doc.exists && doc.data() != null) {
          dayResponses[slot] = MoodResponseModel.fromMap(
            doc.data() as Map<String, dynamic>,
            dateSlot,
          );
        } else {
          dayResponses[slot] = null;
        }
      }
      result[dateStr] = dayResponses;
    }
    return result;
  }
}
