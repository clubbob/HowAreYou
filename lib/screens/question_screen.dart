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
  final MoodService _moodService = MoodService();
  bool _isSaving = false;

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
        note: null, // 텍스트 입력 기능 제거
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
      barrierDismissible: true,
      builder: (dialogContext) {
        // 다이얼로그가 표시된 후 2초 뒤 자동으로 닫기
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          });
        });
        return AlertDialog(
          content: const Text(
            '확인해 줘서 고마워요.',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상태 알려주기'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 18),
                const SizedBox(width: 4),
                const Text('뒤로', style: TextStyle(fontSize: 16)),
              ],
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
                      '지금 어때?',
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
                        // 각 기분에 맞는 색상 정의
                        Color backgroundColor;
                        Color borderColor;
                        Color textColor;
                        
                        switch (mood) {
                          case Mood.good:
                            backgroundColor = Colors.green.shade50;
                            borderColor = Colors.green.shade300;
                            textColor = Colors.green.shade800;
                            break;
                          case Mood.normal:
                            backgroundColor = Colors.orange.shade50;
                            borderColor = Colors.orange.shade300;
                            textColor = Colors.orange.shade800;
                            break;
                          case Mood.bad:
                            backgroundColor = Colors.red.shade50;
                            borderColor = Colors.red.shade300;
                            textColor = Colors.red.shade800;
                            break;
                        }
                        
                        final isSelected = _selectedMood == mood;
                        
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
                              color: isSelected
                                  ? backgroundColor
                                  : backgroundColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? borderColor
                                    : borderColor.withOpacity(0.5),
                                width: isSelected ? 3 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: borderColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                mood.buildLargeIcon(
                                  size: isSelected ? 56 : 52,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? textColor : textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
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
