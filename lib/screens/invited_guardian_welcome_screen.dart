import 'package:flutter/material.dart';
import 'auth_screen.dart';

/// 보호대상자가 보낸 초대 링크로 들어온 사용자: "보호자로 연결됩니다" 문구 + 시작하기 → 로그인 후 보호자로 자동 연결
class InvitedGuardianWelcomeScreen extends StatelessWidget {
  const InvitedGuardianWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '보호대상자님이 당신을 보호자로\n초대했습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '시작하기를 누르고 로그인하면\n자동으로 연결됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
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
                        builder: (_) => const AuthScreen(redirectToGuardianIfInvited: true),
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
