import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import '../services/auth_service.dart';
import '../services/service_feedback_service.dart';

/// 서비스 개선 의견 수집 화면
class ServiceImprovementScreen extends StatefulWidget {
  const ServiceImprovementScreen({super.key});

  @override
  State<ServiceImprovementScreen> createState() => _ServiceImprovementScreenState();
}

class _ServiceImprovementScreenState extends State<ServiceImprovementScreen> {
  final ServiceFeedbackService _feedbackService = ServiceFeedbackService();
  final _inconvenienceController = TextEditingController();
  final _improvementController = TextEditingController();

  SatisfactionLevel? _satisfaction;
  String? _continueIntent;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inconvenienceController.dispose();
    _improvementController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_satisfaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('만족도 평가를 선택해 주세요.')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final userModel = authService.userModel;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final feedback = ServiceFeedbackModel(
        userId: user.uid,
        userPhone: userModel?.phone,
        userDisplayName: userModel?.displayName,
        satisfaction: _satisfaction!.value,
        inconvenience: _inconvenienceController.text.trim().isEmpty
            ? null
            : _inconvenienceController.text.trim(),
        improvementIdea: _improvementController.text.trim().isEmpty
            ? null
            : _improvementController.text.trim(),
        continueIntent: _continueIntent,
        createdAt: DateTime.now(),
      );

      await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('소중한 의견 감사합니다.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('서비스 개선 전송 실패: $e');
      debugPrint('스택: $st');
      if (mounted) {
        String msg = '전송에 실패했습니다. 잠시 후 다시 시도해 주세요.';
        if (e is FirebaseException) {
          if (e.code == 'permission-denied' ||
              e.code == 'cloud_firestore/permission-denied') {
            msg = '권한이 없습니다. Firestore 규칙이 배포되었는지 확인해 주세요.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서비스 개선'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 설명
              Text(
                '오늘 어때?를 더 좋게 만들기 위해\n여러분의 의견을 듣고 있습니다.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 1. 만족도 평가 (필수)
              Text(
                '1. 만족도 평가',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ...SatisfactionLevel.values.map((level) {
                return RadioListTile<SatisfactionLevel>(
                  value: level,
                  groupValue: _satisfaction,
                  onChanged: _isSubmitting ? null : (v) => setState(() => _satisfaction = v),
                  title: Text(level.label, style: const TextStyle(fontSize: 15)),
                );
              }),
              const SizedBox(height: 24),

              // 2. 불편했던 점 (선택)
              Text(
                '2. 불편했던 점',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inconvenienceController,
                maxLines: 4,
                maxLength: 1000,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: '사용 중 불편했던 점이 있다면 적어주세요.',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // 3. 개선 아이디어 (선택)
              Text(
                '3. 개선 아이디어',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _improvementController,
                maxLines: 4,
                maxLength: 1000,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: '이런 기능이 추가되면 좋겠어요.',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // 4. 계속 사용 의향 (선택)
              Text(
                '4. 계속 사용 의향',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ...ContinueIntent.values.map((intent) {
                return RadioListTile<String>(
                  value: intent.label,
                  groupValue: _continueIntent,
                  onChanged: _isSubmitting ? null : (v) => setState(() => _continueIntent = v),
                  title: Text(intent.label, style: const TextStyle(fontSize: 15)),
                );
              }),
              const SizedBox(height: 32),

              // 5. 제출 버튼
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('의견 보내기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
