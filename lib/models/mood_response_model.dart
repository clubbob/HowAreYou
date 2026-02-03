import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

enum Mood {
  good(emoji: '😊', label: '좋아', value: 1, color: Colors.green),
  normal(emoji: '😐', label: '보통', value: 2, color: Colors.orange),
  bad(emoji: '😞', label: '안좋아', value: 3, color: Colors.red);

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
  evening('evening', '저녁', '18:00');

  final String value;
  final String label;
  final String time;

  const TimeSlot(this.value, this.label, this.time);
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

  factory MoodResponseModel.fromMap(Map<String, dynamic> map, String id) {
    final parts = id.split('_');
    final slotValue = parts[1];
    final moodVal = map['mood'] as int?;
    // 1=좋아, 2=보통, 3=안좋아. 예전 데이터(4,5)는 안좋아로 매핑
    final Mood mood = moodVal == 1
        ? Mood.good
        : moodVal == 2
            ? Mood.normal
            : Mood.bad;

    return MoodResponseModel(
      subjectId: map['subjectId'] ?? '',
      dateSlot: id,
      slot: TimeSlot.values.firstWhere(
        (s) => s.value == slotValue,
        orElse: () => TimeSlot.morning,
      ),
      answeredAt: (map['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mood: mood,
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slot': slot.value,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'mood': mood.value,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
