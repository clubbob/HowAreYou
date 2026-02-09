import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../utils/permission_helper.dart';
import '../utils/button_styles.dart';
import '../main.dart';
import 'guardian_dashboard_screen.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

/// 보호자 모드 화면 (보호 대상 확인)
class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  @override
  void initState() {
    super.initState();
    // 보호자 모드 진입 시 FCM 초기화 (알림 수신을 위해)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  Future<void> _initializeFCM() async {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) {
      debugPrint('[보호자 모드] 사용자 ID가 없음');
      return;
    }

    debugPrint('[보호자 모드] FCM 초기화 시작');

    // Android에서 알림 권한 확인 및 요청
    if (Platform.isAndroid) {
      try {
        final isGranted = await PermissionHelper.isNotificationPermissionGranted();
        debugPrint('[보호자 모드] 알림 권한 상태: $isGranted');
        if (!isGranted && mounted) {
          debugPrint('[보호자 모드] 알림 권한 요청 시작');
          final granted = await PermissionHelper.requestNotificationPermission(context, isForSubject: false);
          debugPrint('[보호자 모드] 알림 권한 요청 결과: $granted');
        } else {
          debugPrint('[보호자 모드] 알림 권한이 이미 허용되어 있음');
        }
      } catch (e) {
        debugPrint('[보호자 모드] 알림 권한 요청 오류: $e');
      }
    }

    // FCM 초기화 (토큰 저장) - 강제로 다시 초기화하여 토큰이 확실히 저장되도록 함
    try {
      await FCMService.instance.initialize(userId, context: context, forceReinitialize: true);
      debugPrint('[보호자 모드] FCM 초기화 완료');
    } catch (e) {
      debugPrint('[보호자 모드] FCM 초기화 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    const primaryColor = Color(0xFF5C6BC0);
    const surfaceColor = Color(0xFFF5F5F9);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('보호자 모드'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen(skipAutoNavigation: true)),
            );
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
        actions: [
          // 로그아웃 버튼 (테스트용)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && context.mounted) {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                // 로그아웃 후 AuthScreen으로 이동
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                } else if (MyApp.navigatorKey.currentContext != null) {
                  // context가 없으면 전역 Navigator 사용
                  Navigator.of(MyApp.navigatorKey.currentContext!).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '보호 대상 확인',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '보호 대상의 상태를 확인하세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 88,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuardianDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 40),
                  label: const Text('보호 대상 확인'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    elevation: 6,
                    shadowColor: primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
