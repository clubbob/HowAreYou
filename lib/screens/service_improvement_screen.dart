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
  final _retentionReasonController = TextEditingController();

  SatisfactionLevel? _satisfaction;
  String? _continueIntent;
  bool _isSubmitting = false;
  bool _submitted = false; // 제출 완료 시 완료 화면 표시

  @override
  void dispose() {
    _inconvenienceController.dispose();
    _improvementController.dispose();
    _retentionReasonController.dispose();
    super.dispose();
  }

  bool get _needsComplaint =>
      _satisfaction != null && (_satisfaction!.value == 1 || _satisfaction!.value == 2);

  bool get _needsRetentionReason =>
      _continueIntent != null &&
      (_continueIntent == '고민 중입니다' || _continueIntent == '사용하지 않을 것 같습니다');

  bool get _canSubmit {
    if (_satisfaction == null || _continueIntent == null) return false;
    if (_needsComplaint && _inconvenienceController.text.trim().isEmpty) return false;
    if (_needsRetentionReason && _retentionReasonController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      String msg = '필수 항목을 입력해 주세요.';
      if (_satisfaction == null) msg = '사용 경험을 선택해 주세요.';
      else if (_continueIntent == null) msg = '계속 사용하실 의향을 선택해 주세요.';
      else if (_needsComplaint && _inconvenienceController.text.trim().isEmpty) {
        msg = '가장 아쉬웠던 점을 입력해 주세요.';
      } else if (_needsRetentionReason && _retentionReasonController.text.trim().isEmpty) {
        msg = '이유를 입력해 주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        retentionReason: _needsRetentionReason && _retentionReasonController.text.trim().isNotEmpty
            ? _retentionReasonController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() => _submitted = true);
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
        child: _submitted
            ? _buildCompletionView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 상단 설명
              const Text(
                '더 나은 안심을 위해',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '여러분의 의견이 "오늘 어때"를 더 단단하게 만듭니다.\n사용하면서 느낀 점을 자유롭게 남겨주세요.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),

              // 1. 사용 경험 (필수)
              Text(
                '1. 사용 경험은 어떠셨나요? *',
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
              if (_needsComplaint)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '※ "아쉬움 / 많이 불편함" 선택 시 아래 문항 필수',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                  ),
                ),
              const SizedBox(height: 24),

              // 2. 가장 아쉬웠던 점
              Text(
                '2. 가장 아쉬웠던 점은 무엇인가요?${_needsComplaint ? ' *' : ''}',
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
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '사용 중 불편했던 점을 자유롭게 적어주세요.',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // 3. 이런 기능이 추가되면 좋겠어요
              Text(
                '3. 이런 기능이 추가되면 좋겠어요',
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
                  hintText: '추가되었으면 하는 기능이나 아이디어를 적어주세요.',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // 4. 계속 사용 의향 (필수)
              Text(
                '4. 앞으로도 계속 사용하실 의향이 있으신가요? *',
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
              if (_needsRetentionReason) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '※ "고민 중 / 사용하지 않을 것 같습니다" 선택 시 이유 입력 요청',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _retentionReasonController,
                  maxLines: 3,
                  maxLength: 500,
                  enabled: !_isSubmitting,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '이유를 적어주세요.',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // 제출 버튼
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_canSubmit ? null : _submit,
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

  Widget _buildCompletionView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            '소중한 의견 감사합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '더 가벼운 안심 루틴을 만들겠습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '오늘도 안부 남기기',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
