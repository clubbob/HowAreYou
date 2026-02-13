import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../services/guardian_service.dart';
import '../models/mood_response_model.dart';
import '../widgets/mood_face_icon.dart';
import '../utils/button_styles.dart';
import 'subject_mode_screen.dart';

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
  final GuardianService _guardianService = GuardianService();
  bool _isSaving = false;
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 이미 오늘 기록을 남긴 뒤 다시 진입한 경우 안내 후 되돌림
    if (widget.alreadyResponded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAlreadyResponded();
      });
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyResponded() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) return;
    final done = await _moodService.hasRespondedToday(subjectId: userId);
    if (done && mounted) {
      // 이전 화면이 있는지 확인
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // 이전 화면이 없으면 SubjectModeScreen으로 이동
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
          );
        }
      } catch (e) {
        // pop() 실패 시 SubjectModeScreen으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오늘 안부는 이미 전달됐어요. 자정(한국 시간) 이후에 다시 남길 수 있어요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 컨디션 기록하기'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () {
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
                );
              }
            } catch (e) {
              // pop() 실패 시 SubjectModeScreen으로 이동
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
              );
            }
          },
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
                    Column(
                      children: Mood.selectableMoods.map((mood) {
                        Color backgroundColor;
                        Color borderColor;
                        Color textColor;
                        if (mood == Mood.okay) {
                          backgroundColor = Colors.lightGreen.shade50;
                          borderColor = Colors.lightGreen.shade300;
                          textColor = Colors.lightGreen.shade800;
                        } else if (mood == Mood.normal) {
                          backgroundColor = const Color(0xFFF5F0E8);
                          borderColor = const Color(0xFFD4C4B0);
                          textColor = const Color(0xFF6B5B4F);
                        } else {
                          backgroundColor = Colors.deepOrange.shade50;
                          borderColor = Colors.deepOrange.shade300;
                          textColor = Colors.deepOrange.shade800;
                        }
                        final isSelected = _selectedMood == mood;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMood = mood;
                              });
                              // 감정 선택 시 메모 입력창에 자동 포커스
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _memoFocusNode.requestFocus();
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
                              child: Row(
                                children: [
                                  MoodFaceIcon(
                                    mood: mood,
                                    size: isSelected ? 48 : 46,
                                    withShadow: true,
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    mood.label,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? textColor : textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 감정 선택 후에만 메모 입력창 표시
                    if (_selectedMood != null) ...[
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '한 줄 메모 (선택)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _memoController,
                            focusNode: _memoFocusNode,
                            maxLength: 50,
                            maxLines: null,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: '필요하면 한 줄만 남겨요.',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade400,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              counterText: '',
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '※ 입력 내용은 보호자에게 전달되지 않습니다.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '선택 내용은 해석되거나 평가되지 않습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
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

  Future<void> _saveResponse() async {
    if (_selectedMood == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid;
      if (userId == null) {
        return;
      }

      // 메모 텍스트 가져오기 (빈 값이면 null)
      final memoText = _memoController.text.trim();
      final memo = memoText.isEmpty ? null : memoText;

      await _moodService.saveMoodResponse(
        subjectId: userId,
        slot: widget.timeSlot,
        mood: _selectedMood!,
        note: memo,
      );

      if (!mounted) return;

      // 이전 화면이 있는지 확인
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // 이전 화면이 없으면 (알림에서 직접 온 경우) SubjectModeScreen으로 이동
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
          );
        }
      } catch (e) {
        // pop() 실패 시 SubjectModeScreen으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('잘했어요. 오늘 기록은 끝이에요.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기록을 저장하는 데 실패했습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
