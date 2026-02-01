import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/mood_response_model.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveMoodResponse({
    required String subjectId,
    required TimeSlot slot,
    required Mood mood,
    String? note,
  }) async {
    final now = DateTime.now();
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

    await _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('prompts')
        .doc(dateSlot)
        .set(response.toMap());
  }

  Future<bool> hasRespondedToday({
    required String subjectId,
    required TimeSlot slot,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    final now = DateTime.now();
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
}
