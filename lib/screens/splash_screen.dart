import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/invite_pending_service.dart';
import '../services/guardian_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'invited_subject_welcome_screen.dart';
import 'invited_guardian_welcome_screen.dart';
import 'subject_mode_screen.dart';
import 'guardian_mode_screen.dart';
import 'guardian_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    // 저장된 로그인 상태가 복원될 때까지 대기 (Firebase Auth는 한 번 로그인 시 자동 유지)
    await authService.authReady.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );

    if (!mounted) return;

    bool isAuthenticated = authService.isAuthenticated;
    // 일부 기기에서 persistence 복원이 한 틱 늦을 수 있어, 로그인 없으면 잠시 후 한 번 더 확인
    if (!isAuthenticated) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      isAuthenticated = authService.isAuthenticated;
    }

    if (isAuthenticated) {
      // 역할별 알림은 auth_service(로그인 시) + _AppLifecycleHandler(포그라운드 복귀)에서만 스케줄

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      final data = initialMessage?.data;
      final type = data?['type'];
      final pendingInviterId = await InvitePendingService.getPendingInviterId();
      final pendingSubjectId = await InvitePendingService.getPendingSubjectId();
      if (!mounted) return;
      if (type == 'RESPONSE_RECEIVED' || type == 'UNREACHABLE') {
        // 앱 시작 시 알림이 있으면 바로 보호 대상 관리 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
        );
      } else if (type == 'REMIND_RESPONSE') {
        Navigator.of(context).pushReplacementNamed('/question');
      } else if (pendingInviterId != null && pendingInviterId.isNotEmpty) {
        final user = authService.user;
        if (user != null) {
          try {
            await GuardianService().acceptInviteAsSubject(
              subjectUid: user.uid,
              subjectPhone: user.phoneNumber ?? '',
              subjectDisplayName: user.displayName,
              guardianUid: pendingInviterId,
            );
            await InvitePendingService.clearPendingInviterId();
          } catch (_) {}
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
        );
      } else if (pendingSubjectId != null && pendingSubjectId.isNotEmpty) {
        final user = authService.user;
        if (user != null) {
          try {
            await GuardianService().acceptInviteAsGuardian(
              guardianUid: user.uid,
              guardianPhone: user.phoneNumber ?? '',
              guardianDisplayName: user.displayName,
              subjectId: pendingSubjectId,
            );
            await InvitePendingService.clearPendingSubjectId();
          } catch (_) {}
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GuardianModeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen(skipAutoNavigation: true)),
        );
      }
    } else {
      final pendingInviterId = await InvitePendingService.getPendingInviterId();
      final pendingSubjectId = await InvitePendingService.getPendingSubjectId();
      if (!mounted) return;
      if (pendingInviterId != null && pendingInviterId.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InvitedSubjectWelcomeScreen()),
        );
      } else if (pendingSubjectId != null && pendingSubjectId.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InvitedGuardianWelcomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (MyApp.firebaseInitFailed)
              Material(
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '연결을 확인해 주세요. 일부 기능이 제한될 수 있습니다.',
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
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
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
