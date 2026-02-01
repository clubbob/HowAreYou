import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';

class QuestionScreen extends StatefulWidget {
  final TimeSlot timeSlot;
  final bool alreadyResponded;

  const QuestionScreen({
    super.key,
    required this.timeSlot,
    this.alreadyResponded = false,
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

      final noteText = _noteController.text.trim();
      await _moodService.saveMoodResponse(
        subjectId: userId,
        slot: widget.timeSlot,
        mood: _selectedMood!,
        note: noteText.isEmpty ? null : noteText,
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
        content: const Text(
          '확인해 줘서 고마워요.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: AppButtonStyles.primaryFilled,
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('기분 알려주기'),
        leadingWidth: 72,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, size: 20),
                    const SizedBox(width: 4),
                    const Text('뒤로', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '지금 기분이 어때요?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: Mood.values.map((mood) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = mood;
                            });
                          },
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 8,
                            ),
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
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  mood.emoji,
                                  style: const TextStyle(fontSize: 52),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mood.label,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedMood != null) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: '하고 싶은 말 (선택)',
                          hintText: '입력 안 해도 돼요',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: AppButtonStyles.primaryMinHeight,
                child: ElevatedButton(
                  onPressed: _selectedMood == null || _isSaving
                      ? null
                      : _saveResponse,
                  style: AppButtonStyles.primaryElevated,
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('확인'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
