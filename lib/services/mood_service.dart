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
  /// 저장 성공 시 subjects 문서의 리마인드 필드·스트릭도 업데이트함.
  Future<void> saveMoodResponse({
    required String subjectId,
    required TimeSlot slot,
    required Mood mood,
    String? note,
  }) async {
    final now = _nowKorea();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
    final docId = dateStr;
    final response = MoodResponseModel(
      subjectId: subjectId,
      dateSlot: docId,
      slot: TimeSlot.daily,
      answeredAt: now,
      mood: mood,
      note: note,
    );

    final subjectRef = _firestore.collection('subjects').doc(subjectId);
    final promptRef = subjectRef.collection('prompts').doc(docId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(promptRef, response.toMap());

      // 어제 기록 여부는 prompts 존재로 확인 (deleteTodayResponse 후에도 정확함)
      final yesterdayPromptRef = subjectRef.collection('prompts').doc(yesterdayStr);
      final yesterdayDoc = await transaction.get(yesterdayPromptRef);
      final yesterdayRecorded = yesterdayDoc.exists;

      final subjectDoc = await transaction.get(subjectRef);
      final data = subjectDoc.data();
      final currentStreak = (data?['currentStreak'] as int?) ?? 0;
      final longestStreak = (data?['longestStreak'] as int?) ?? 0;

      int newStreak = 1;
      if (yesterdayRecorded) {
        newStreak = currentStreak + 1;
      }
      final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

      transaction.set(subjectRef, {
        'lastResponseAt': Timestamp.fromDate(now),
        'lastResponseDate': dateStr,
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastRecordedDate': dateStr,
      }, SetOptions(merge: true));
    });
  }

  /// 연속 기록(스트릭) 조회. subjects 문서의 currentStreak, longestStreak 반환.
  Future<({int currentStreak, int longestStreak})?> getStreak(String subjectId) async {
    try {
      final doc = await _firestore.collection('subjects').doc(subjectId).get();
      if (!doc.exists || doc.data() == null) return null;
      final d = doc.data()!;
      final current = d['currentStreak'];
      final longest = d['longestStreak'];
      if (current == null && longest == null) return null;
      return (
        currentStreak: (current is int ? current : 0),
        longestStreak: (longest is int ? longest : 0),
      );
    } catch (_) {
      return null;
    }
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

  /// 오늘 응답을 삭제. prompts 삭제 + subjects의 lastResponseAt/스트릭 롤백.
  /// lastResponseAt = 오늘 00:00 KST - 1초 → 당일 미기록 만족, 3일 무응답 불만족(즉시 경보 방지).
  Future<void> deleteTodayResponse(String subjectId) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final subjectRef = _firestore.collection('subjects').doc(subjectId);
    final promptRef = subjectRef.collection('prompts').doc(dateStr);

    // 오늘 00:00 KST - 1초 = 어제 23:59:59 KST (epoch 금지: 3일 무응답 즉시 트리거 방지)
    final k = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
    final todayStartKst =
        tz.TZDateTime(tz.getLocation('Asia/Seoul'), k.year, k.month, k.day, 0, 0, 0);
    final yesterdayEndKst = todayStartKst.subtract(const Duration(seconds: 1));

    await _firestore.runTransaction((transaction) async {
      transaction.delete(promptRef);
      transaction.set(subjectRef, {
        'lastResponseAt': Timestamp.fromDate(yesterdayEndKst),
        'lastRecordedDate': FieldValue.delete(),
        'currentStreak': 0,
      }, SetOptions(merge: true));
    });
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

  /// [fromDateStr] 이후 ~ 오늘까지 이력 (최대 7일). 보호자 연결일 이후만 표시할 때 사용.
  /// [fromDateStr] = yyyy-MM-dd. null이면 getLast7DaysResponses와 동일.
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getResponsesFromDate(
    String subjectId, {
    String? fromDateStr,
    int maxDays = 7,
    bool excludeNote = false,
  }) async {
    if (fromDateStr == null || fromDateStr.isEmpty) {
      return _getLastNDaysResponses(subjectId, maxDays, excludeNote: excludeNote);
    }
    final now = _nowKorea();
    DateTime fromDate;
    try {
      fromDate = DateFormat('yyyy-MM-dd').parse(fromDateStr);
    } catch (_) {
      return _getLastNDaysResponses(subjectId, maxDays, excludeNote: excludeNote);
    }
    final result = <String, Map<TimeSlot, MoodResponseModel?>>{};
    var current = DateTime(now.year, now.month, now.day);
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    var count = 0;
    while (current.isAfter(from) || current.isAtSameMomentAs(from)) {
      if (count >= maxDays) break;
      final dateStr = DateFormat('yyyy-MM-dd').format(current);
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
      count++;
      current = current.subtract(const Duration(days: 1));
    }
    return result;
  }

  /// 최근 30일 이력. 날짜별로 1건씩, 키는 TimeSlot.daily.
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getLast30DaysResponses(
    String subjectId,
  ) async {
    return _getLastNDaysResponses(subjectId, 30);
  }

  /// 특정 월 기록률 계산. (기록한 일수 / 해당 월 총 일수) * 100.
  /// [year], [month]: 1-based. 반환값 0~100.
  Future<double> getMonthRecordRate(String subjectId, int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    var recordedDays = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _firestore
          .collection('subjects')
          .doc(subjectId)
          .collection('prompts')
          .doc(dateStr)
          .get();
      if (doc.exists) recordedDays++;
    }
    return daysInMonth > 0 ? (recordedDays / daysInMonth) * 100 : 0;
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
