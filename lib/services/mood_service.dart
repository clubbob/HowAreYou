import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/mood_response_model.dart';
import '../utils/constants.dart';

/// 일일 상태(기분) 응답 저장·조회. PRD §9: subjects/{subjectUid} 문서 ID = 보호대상자 Auth UID.
///
/// **데이터 분리**: prompts = answeredAt, slot (보호자 "기록 여부" 공개). private_prompts = mood, note (본인만).
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
  /// 배치 사용: 트랜잭션의 subjects 읽기/쓰기 권한 이슈 회피.
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
    final response = MoodResponseModel(
      subjectId: subjectId,
      dateSlot: dateStr,
      slot: TimeSlot.daily,
      answeredAt: now,
      mood: mood,
      note: note,
    );

    final subjectRef = _firestore.collection('subjects').doc(subjectId);
    final promptRef = subjectRef.collection(AppConstants.promptsCollection).doc(dateStr);
    final privateRef = subjectRef.collection(AppConstants.privatePromptsCollection).doc(dateStr);

    // 1. 읽기는 트랜잭션 밖에서 (권한 이슈 회피)
    final yesterdayDoc = await subjectRef.collection(AppConstants.promptsCollection).doc(yesterdayStr).get();
    final subjectDoc = await subjectRef.get();
    final data = subjectDoc.data();
    final currentStreak = (data?['currentStreak'] as int?) ?? 0;
    final longestStreak = (data?['longestStreak'] as int?) ?? 0;

    int newStreak = 1;
    if (yesterdayDoc.exists) {
      newStreak = currentStreak + 1;
    }
    final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

    // 2. 쓰기: 전체 배치 시도 후, 실패 시 prompts+private_prompts만 저장 (fallback)
    try {
      final batch = _firestore.batch();
      batch.set(promptRef, {
        'slot': response.slot.value,
        'answeredAt': Timestamp.fromDate(response.answeredAt),
      });
      batch.set(privateRef, {
        'mood': response.mood.value,
        if (note != null && note!.isNotEmpty) 'note': note!,
      });
      batch.set(subjectRef, {
        'lastResponseAt': Timestamp.fromDate(now),
        'lastResponseDate': dateStr,
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastRecordedDate': dateStr,
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      // subjects 쓰기 권한 실패 시 prompts+private_prompts만 저장 (컨디션 기록 우선)
      final fallbackBatch = _firestore.batch();
      fallbackBatch.set(promptRef, {
        'slot': response.slot.value,
        'answeredAt': Timestamp.fromDate(response.answeredAt),
      });
      fallbackBatch.set(privateRef, {
        'mood': response.mood.value,
        if (note != null && note!.isNotEmpty) 'note': note!,
      });
      await fallbackBatch.commit();
      // 스트릭은 저장 못함. 다음 기록 시 보정됨.
    }
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
        .collection(AppConstants.promptsCollection)
        .doc(dateStr)
        .get();
    return doc.exists;
  }

  /// 오늘 응답을 삭제. prompts + private_prompts 삭제 + subjects의 lastResponseAt/스트릭 롤백.
  /// lastResponseAt = 오늘 00:00 KST - 1초 → 당일 미기록 만족, 3일 무응답 불만족(즉시 경보 방지).
  Future<void> deleteTodayResponse(String subjectId) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final subjectRef = _firestore.collection('subjects').doc(subjectId);
    final promptRef = subjectRef.collection(AppConstants.promptsCollection).doc(dateStr);
    final privateRef = subjectRef.collection(AppConstants.privatePromptsCollection).doc(dateStr);

    // 오늘 00:00 KST - 1초 = 어제 23:59:59 KST (epoch 금지: 3일 무응답 즉시 트리거 방지)
    final k = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
    final todayStartKst =
        tz.TZDateTime(tz.getLocation('Asia/Seoul'), k.year, k.month, k.day, 0, 0, 0);
    final yesterdayEndKst = todayStartKst.subtract(const Duration(seconds: 1));

    await _firestore.runTransaction((transaction) async {
      transaction.delete(promptRef);
      transaction.delete(privateRef);
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
  /// [forGuardian] = true면 prompts만 읽음 (기록 여부만, mood/note 비공개)
  Future<Map<TimeSlot, MoodResponseModel?>> getTodayResponses(
    String subjectId, {
    bool excludeNote = false,
    bool forGuardian = false,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_nowKorea());
    final result = <TimeSlot, MoodResponseModel?>{};
    final promptDoc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection(AppConstants.promptsCollection)
        .doc(dateStr)
        .get();

    if (!promptDoc.exists || promptDoc.data() == null) {
      result[TimeSlot.daily] = null;
      return result;
    }

    if (forGuardian) {
      // 보호자: answeredAt만 사용, mood는 placeholder (UI에서 "기록 있음"만 표시)
      final data = promptDoc.data()!;
      result[TimeSlot.daily] = MoodResponseModel(
        subjectId: subjectId,
        dateSlot: dateStr,
        slot: TimeSlot.daily,
        answeredAt: (data['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        mood: Mood.normal,
        note: null,
      );
      return result;
    }

    // 본인: private_prompts에서 mood, note 가져와 병합
    final privateDoc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection(AppConstants.privatePromptsCollection)
        .doc(dateStr)
        .get();

    final promptData = promptDoc.data() as Map<String, dynamic>;
    final privateData = privateDoc.exists && privateDoc.data() != null
        ? (privateDoc.data() as Map<String, dynamic>)
        : null;

    // legacy: prompts에 mood/note 있으면 사용 (마이그레이션 전)
    final merged = <String, dynamic>{
      ...promptData,
      if (privateData != null) ...privateData,
    };
    result[TimeSlot.daily] = MoodResponseModel.fromMap(
      merged,
      dateStr,
      subjectUid: subjectId,
      excludeNote: excludeNote,
    );
    return result;
  }

  /// 최근 7일 이력. 날짜별로 1건씩, 키는 TimeSlot.daily.
  /// [forGuardian] = true면 prompts만 (기록 여부만), mood는 placeholder
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getLast7DaysResponses(
    String subjectId, {
    bool excludeNote = false,
    bool forGuardian = false,
  }) async {
    return _getLastNDaysResponses(subjectId, 7, excludeNote: excludeNote, forGuardian: forGuardian);
  }

  /// [fromDateStr] 이후 ~ 오늘까지 이력 (최대 7일). 보호자 연결일 이후만 표시할 때 사용.
  /// [forGuardian] = true면 prompts만 (기록 여부만), mood는 placeholder
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> getResponsesFromDate(
    String subjectId, {
    String? fromDateStr,
    int maxDays = 7,
    bool excludeNote = false,
    bool forGuardian = false,
  }) async {
    if (fromDateStr == null || fromDateStr.isEmpty) {
      return _getLastNDaysResponses(subjectId, maxDays, excludeNote: excludeNote, forGuardian: forGuardian);
    }
    final now = _nowKorea();
    DateTime fromDate;
    try {
      fromDate = DateFormat('yyyy-MM-dd').parse(fromDateStr);
    } catch (_) {
      return _getLastNDaysResponses(subjectId, maxDays, excludeNote: excludeNote, forGuardian: forGuardian);
    }
    final result = <String, Map<TimeSlot, MoodResponseModel?>>{};
    var current = DateTime(now.year, now.month, now.day);
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    var count = 0;
    while (current.isAfter(from) || current.isAtSameMomentAs(from)) {
      if (count >= maxDays) break;
      final dateStr = DateFormat('yyyy-MM-dd').format(current);
      final dayResponses = await _getSingleDayResponse(subjectId, dateStr, excludeNote: excludeNote, forGuardian: forGuardian);
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
          .collection(AppConstants.promptsCollection)
          .doc(dateStr)
          .get();
      if (doc.exists) recordedDays++;
    }
    return daysInMonth > 0 ? (recordedDays / daysInMonth) * 100 : 0;
  }

  /// 단일 날짜 응답 조회 (내부 헬퍼)
  Future<Map<TimeSlot, MoodResponseModel?>> _getSingleDayResponse(
    String subjectId,
    String dateStr, {
    bool excludeNote = false,
    bool forGuardian = false,
  }) async {
    final dayResponses = <TimeSlot, MoodResponseModel?>{};
    final promptDoc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection(AppConstants.promptsCollection)
        .doc(dateStr)
        .get();

    if (!promptDoc.exists || promptDoc.data() == null) {
      dayResponses[TimeSlot.daily] = null;
      return dayResponses;
    }

    if (forGuardian) {
      final data = promptDoc.data()!;
      dayResponses[TimeSlot.daily] = MoodResponseModel(
        subjectId: subjectId,
        dateSlot: dateStr,
        slot: TimeSlot.daily,
        answeredAt: (data['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        mood: Mood.normal,
        note: null,
      );
      return dayResponses;
    }

    final privateDoc = await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection(AppConstants.privatePromptsCollection)
        .doc(dateStr)
        .get();

    final promptData = promptDoc.data() as Map<String, dynamic>;
    final privateData = privateDoc.exists && privateDoc.data() != null
        ? (privateDoc.data() as Map<String, dynamic>)
        : null;

    final merged = <String, dynamic>{
      ...promptData,
      if (privateData != null) ...privateData,
    };
    dayResponses[TimeSlot.daily] = MoodResponseModel.fromMap(
      merged,
      dateStr,
      subjectUid: subjectId,
      excludeNote: excludeNote,
    );
    return dayResponses;
  }

  /// 최근 N일 이력 조회 (내부 헬퍼 메서드)
  /// [forGuardian] = true면 prompts만 (기록 여부만), mood는 placeholder
  Future<Map<String, Map<TimeSlot, MoodResponseModel?>>> _getLastNDaysResponses(
    String subjectId,
    int days, {
    bool excludeNote = false,
    bool forGuardian = false,
  }) async {
    final now = _nowKorea();
    final result = <String, Map<TimeSlot, MoodResponseModel?>>{};

    for (var d = 0; d < days; d++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      result[dateStr] = await _getSingleDayResponse(subjectId, dateStr, excludeNote: excludeNote, forGuardian: forGuardian);
    }
    return result;
  }
}
