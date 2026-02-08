import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../services/guardian_service.dart';
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
  final GuardianService _guardianService = GuardianService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.timeSlot == TimeSlot.daily && !widget.alreadyResponded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlreadyResponded());
    }
  }

  Future<void> _checkAlreadyResponded() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) return;
    final done = await _moodService.hasRespondedToday(subjectId: userId);
    if (done && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘 이미 상태를 알려주셨습니다. 자정(한국 시간) 이후에 다시 알려주세요.')),
      );
    }
  }

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

      final hasGuardian = await _guardianService.hasGuardian(userId);
      if (!hasGuardian) {
        if (mounted) {
          Navigator.of(context).pop();
          _showNoGuardianDialog();
        }
        return;
      }

      final note = _selectedMood == Mood.notGood ? _noteController.text.trim() : null;

      await _moodService.saveMoodResponse(
        subjectId: userId,
        slot: widget.timeSlot,
        mood: _selectedMood!,
        note: note?.isEmpty == true ? null : note,
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showThankYouDialog(hasNote: note?.isNotEmpty == true);
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

  void _showNoGuardianDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('보호자 지정 필요'),
          content: const Text(
            '상태를 알려주려면 먼저 보호자를 지정해주세요.\n\n보호 대상자 모드에서 "보호자 지정" 메뉴를 이용해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// PRD §4.3: 응답 완료 후 "고마워요." 또는 "알려줘서 고마워요." 한 줄 표시
  void _showThankYouDialog({required bool hasNote}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          });
        });
        return AlertDialog(
          content: Text(
            hasNote ? '알려줘서 고마워요.' : '고마워요.',
            style: const TextStyle(fontSize: 18),
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
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32 + bottomInset),
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
                      runSpacing: 12,
                      children: Mood.selectableMoods.map((mood) {
                        final isOkay = mood == Mood.okay;
                        final backgroundColor = isOkay ? Colors.lightGreen.shade50 : Colors.deepOrange.shade50;
                        final borderColor = isOkay ? Colors.lightGreen.shade300 : Colors.deepOrange.shade300;
                        final textColor = isOkay ? Colors.lightGreen.shade800 : Colors.deepOrange.shade800;
                        final isSelected = _selectedMood == mood;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = mood;
                            });
                          },
                          child: Container(
                            width: 120,
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
                                mood.buildLargeIcon(size: isSelected ? 48 : 46),
                                const SizedBox(height: 4),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? textColor : textColor.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedMood == Mood.notGood) ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: '어떤 게 별로예요? (선택)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
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
