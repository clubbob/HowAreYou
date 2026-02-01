import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';

class QuestionScreen extends StatefulWidget {
  final TimeSlot timeSlot;

  const QuestionScreen({
    super.key,
    required this.timeSlot,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  Mood? _selectedMood;
  final _noteController = TextEditingController();
  final MoodService _moodService = MoodService();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveResponse() async {
    if (_selectedMood == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;

      if (userId == null) {
        throw Exception('사용자 인증이 필요합니다.');
      }

      await _moodService.saveMoodResponse(
        subjectId: userId,
        slot: widget.timeSlot,
        mood: _selectedMood!,
        note: _selectedMood == Mood.hard ? _noteController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showThankYouDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Text(
          _selectedMood == Mood.hard
              ? '알려줘서 고마워요.'
              : '고마워요.',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.timeSlot.label} 상태'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '지금 어때?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: Mood.values.map((mood) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                    });
                  },
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: _selectedMood == mood
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedMood == mood
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mood.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedMood == Mood.hard) ...[
              const SizedBox(height: 48),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: '어떤 게 힘드세요?',
                  hintText: '자유롭게 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedMood == null || _isSaving
                    ? null
                    : _saveResponse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
