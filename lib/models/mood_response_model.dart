import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

/// 저장/이력 표시용 5종 유지. 상태 알려주기 선택은 selectableMoods(괜찮아, 별로)만 사용.
enum Mood {
  good(emoji: '😊', label: '좋아', value: 1, color: Colors.green),
  okay(emoji: '🙂', label: '괜찮아', value: 2, color: Colors.lightGreen),
  normal(emoji: '😐', label: '보통', value: 3, color: Colors.orange),
  notGood(emoji: '🙁', label: '별로', value: 4, color: Colors.deepOrange),
  hard(emoji: '😞', label: '힘들어', value: 5, color: Colors.red);

  /// 상태 알려주기 화면에서 선택 가능한 옵션 (괜찮아, 별로만)
  static const List<Mood> selectableMoods = [Mood.okay, Mood.notGood];

  /// 내 상태 보기/차트 등에서 2가지로만 표시할 때 (좋아·보통·힘들어 → 괜찮아 또는 별로)
  Mood get displayAsSelectable {
    switch (this) {
      case Mood.good:
      case Mood.okay:
      case Mood.normal:
        return Mood.okay;
      case Mood.notGood:
      case Mood.hard:
        return Mood.notGood;
    }
  }

  final String emoji;
  final String label;
  final int value;
  final Color color;

  const Mood({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
  
  /// 색상이 있는 아이콘 위젯 생성 (상태 페이지용)
  Widget buildColoredIcon({double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: size * 0.6,
            // 이모지가 배경색 위에서 잘 보이도록 약간의 그림자 효과
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 큰 아이콘 (선택 화면용)
  Widget buildLargeIcon({double size = 52}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: size * 0.65,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TimeSlot {
  morning('morning', '아침', '08:00'),
  noon('noon', '점심', '12:00'),
  evening('evening', '저녁', '18:00'),
  /// 24시 기준 하루 1회 응답용 (문서 id = yyyy-MM-dd)
  daily('daily', '오늘', '—');

  final String value;
  final String label;
  final String time;

  const TimeSlot(this.value, this.label, this.time);

  /// 내 상태 보기 등에서 표시할 슬롯 (하루 1회 모드에서는 daily만)
  static List<TimeSlot> get displaySlots => [daily];
}

class MoodResponseModel {
  final String subjectId;
  final String dateSlot; // YYYY-MM-DD_slot 형식
  final TimeSlot slot;
  final DateTime answeredAt;
  final Mood mood;
  final String? note;

  MoodResponseModel({
    required this.subjectId,
    required this.dateSlot,
    required this.slot,
    required this.answeredAt,
    required this.mood,
    this.note,
  });

  /// [id] = document id (YYYY-MM-DD 또는 YYYY-MM-DD_slot). [subjectUid] = 보호대상자 Auth UID from path (PRD §9); omit for legacy docs.
  factory MoodResponseModel.fromMap(Map<String, dynamic> map, String id, {String? subjectUid}) {
    final parts = id.split('_');
    final slotValue = parts.length > 1 ? parts[1] : 'daily';
    final moodVal = map['mood'] as int?;
    final Mood mood = moodVal == 1
        ? Mood.good
        : moodVal == 2
            ? Mood.okay
            : moodVal == 3
                ? Mood.normal
                : moodVal == 4
                    ? Mood.notGood
                    : Mood.hard;

    return MoodResponseModel(
      subjectId: subjectUid ?? map['subjectId']?.toString() ?? '',
      dateSlot: id,
      slot: TimeSlot.values.firstWhere(
        (s) => s.value == slotValue,
        orElse: () => TimeSlot.daily,
      ),
      answeredAt: (map['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mood: mood,
      note: map['note'],
    );
  }

  /// PRD §10: prompt document contains only slot, answeredAt, mood, note. Subject identity is path (PRD §9).
  Map<String, dynamic> toMap() {
    return {
      'slot': slot.value,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'mood': mood.value,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
