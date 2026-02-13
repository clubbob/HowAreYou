import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/mood_response_model.dart';

/// 일일 상태(기분) 응답 저장·조회. PRD §9: subjects/{subjectUid} 문서 ID = 보호대상자 Auth UID.
///
/// **"오늘" 기준**: 한국 시간(KST, Asia/Seoul) **00:00 ~ 24:00** (자정을 넘기면 새 날로 리셋).
class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 한국 시간(Asia/Seoul) 기준 현재 시각. "오늘" 판단은 이 기준으로 함.
  static DateTime _nowKorea() {
    try {
      final k = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
      return DateTime(k.year, k.month, k.day, k.hour, k.minute, k.second);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// 응답 저장. 24시 기준 하루 1회 → 문서 id = yyyy-MM-dd, slot = daily.
  Future<void> saveMoodResponse({
    required String subjectId,
    required TimeSlot slot,
    required Mood mood,
    String? note,
  }) async {
    final now = _nowKorea();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final docId = dateStr;
    final response = MoodResponseModel(
      subjectId: subjectId,
      dateSlot: docId,
      slot: TimeSlot.daily,
      answeredAt: now,
      mood: mood,
      note: note,
    );

    await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(docId)
        .set(response.toMap());
  }

  /// 오늘 이미 응답했는지 (24시 기준 하루 1회)
  Future<bool> hasRespondedToday({required String subjectId}) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final doc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(dateStr)
        .get();
    return doc.exists;
  }

  /// 오늘 응답을 삭제하여 다시 응답할 수 있게 함 (24시 기준 오늘 문서만 삭제)
  Future<void> deleteTodayResponse(String subjectId) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(dateStr)
        .delete();
  }

  /// 현재 응답 가능한 슬롯. 24시 기준 하루 1회이므로 오늘 아직 안 했으면 daily, 했으면 null.
  Future<TimeSlot?> getCurrentTimeSlot() async {
    return TimeSlot.daily;
  }

  /// 오늘 상태 1건 (하루 1회). 키는 TimeSlot.daily 하나.
  /// [excludeNote] = true면 note 필드를 제외 (보호자용)
  Future<Map<TimeSlot, MoodResponseModel?>> getTodayResponses(
    String subjectId, {
    bool excludeNote = false,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final result = <TimeSlot, MoodResponseModel?>{};
    final doc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(dateStr)
        .get();

    if (doc.exists && doc.data() != null) {
      result[TimeSlot.daily] = MoodResponseModel.fromMap(
        doc.data() as Map<String, dynamic>,
        dateStr,
        subjectUid: subjectId,
        excludeNote: excludeNote,
      );
    } else {
      result[TimeSlot.daily] = null;
    }
    return result;
  }

  /// 최근 7일 이력. 날짜별로 1건씩, 키는 TimeSlot.daily.
  /// [excludeNote] = true면 note 필드를 제외 (보호자용)
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getLast7DaysResponses(
    String subjectId, {
    bool excludeNote = false,
  }) async {
    return _getLastNDaysResponses(subjectId, 7, excludeNote: excludeNote);
  }

  /// 최근 30일 이력. 날짜별로 1건씩, 키는 TimeSlot.daily.
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getLast30DaysResponses(
    String subjectId,
  ) async {
    return _getLastNDaysResponses(subjectId, 30);
  }

  /// 최근 N일 이력 조회 (내부 헬퍼 메서드)
  /// [excludeNote] = true면 note 필드를 제외 (보호자용)
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> _getLastNDaysResponses(
    String subjectId,
    int days, {
    bool excludeNote = false,
  }) async {
    final now = _nowKorea();
    final result = <String, Map<TimeSlot, MoodResponseModel?>>{};

    for (var d = 0; d < days; d++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayResponses = <TimeSlot, MoodResponseModel?>{};
      final doc = await _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('prompts')
          .doc(dateStr)
          .get();

      if (doc.exists && doc.data() != null) {
        dayResponses[TimeSlot.daily] = MoodResponseModel.fromMap(
          doc.data() as Map<String, dynamic>,
          dateStr,
          subjectUid: subjectId,
          excludeNote: excludeNote,
        );
      } else {
        dayResponses[TimeSlot.daily] = null;
      }
      result[dateStr] = dayResponses;
    }
    return result;
  }
}
