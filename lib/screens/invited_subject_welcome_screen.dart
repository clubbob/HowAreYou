import 'package:flutter/material.dart';
import '../services/invite_pending_service.dart';
import '../services/guardian_service.dart';
import 'auth_screen.dart';
import 'subject_mode_screen.dart';

/// 초대 링크로 들어온 사용자: "○○님이 괜히 마음 쓰이지 않게..." 문구 + 시작하기 → 로그인 후 보호대상자로 자동 연결
class InvitedSubjectWelcomeScreen extends StatefulWidget {
  const InvitedSubjectWelcomeScreen({super.key});

  @override
  State<InvitedSubjectWelcomeScreen> createState() => _InvitedSubjectWelcomeScreenState();
}

class _InvitedSubjectWelcomeScreenState extends State<InvitedSubjectWelcomeScreen> {
  String _guardianName = '보호자';

  @override
  void initState() {
    super.initState();
    _loadGuardianName();
  }

  Future<void> _loadGuardianName() async {
    final inviterId = await InvitePendingService.getPendingInviterId();
    if (inviterId == null || !mounted) return;
    final name = await GuardianService().getGuardianDisplayName(inviterId);
    if (mounted) setState(() => _guardianName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_guardianName님이 괜히 마음 쓰이지 않게\n하루 한 번만 알려주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '매일 전화 대신, 버튼 하나만 누르면 됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(redirectToSubjectIfInvited: true),
                      ),
                    );
                  },
                  child: const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
