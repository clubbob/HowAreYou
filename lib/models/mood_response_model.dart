import 'package:cloud_firestore/cloud_firestore.dart';

enum Mood {
  good(emoji: '😊', label: '좋아', value: 1),
  normal(emoji: '😐', label: '보통', value: 2),
  bad(emoji: '😞', label: '안좋아', value: 3);

  final String emoji;
  final String label;
  final int value;

  const Mood({
    required this.emoji,
    required this.label,
    required this.value,
  });
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
