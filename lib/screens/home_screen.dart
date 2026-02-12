import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mode_service.dart';
import '../services/fcm_service.dart';
import '../services/guardian_service.dart';
import '../services/notification_service.dart';
import '../utils/button_styles.dart';
import '../utils/permission_helper.dart';
import '../main.dart';
import 'subject_mode_screen.dart';
import 'guardian_mode_screen.dart';
import 'guardian_screen.dart';
import 'auth_screen.dart';
import 'dart:io' show Platform;

class HomeScreen extends StatefulWidget {
  final bool skipAutoNavigation;
  
  const HomeScreen({super.key, this.skipAutoNavigation = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastSelectedMode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLastSelectedMode();
    // 알림 권한 요청은 각 모드 진입 시에만 수행하도록 변경 (통일성)
    // HomeScreen에서는 권한 요청하지 않음
  }

  Future<void> _loadLastSelectedMode() async {
    final mode = await ModeService.getLastSelectedMode();
    if (mounted) {
      setState(() {
        _lastSelectedMode = mode;
        _isLoading = false;
      });
      // skipAutoNavigation이 false이고 마지막 선택한 모드가 있으면 자동으로 해당 모드로 진입
      // (로그인 직후에는 skipAutoNavigation=true로 설정하여 역할 선택 화면을 보여줌)
      if (!widget.skipAutoNavigation && mode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _navigateToMode(mode, skipSave: true);
        });
      }
    }
  }


  Future<void> _selectMode(String mode) async {
    await ModeService.saveSelectedMode(mode);
    await _navigateToMode(mode);
  }

  Future<void> _navigateToMode(String mode, {bool skipSave = false}) async {
    if (!skipSave) {
      ModeService.saveSelectedMode(mode);
    }

    if (mode == ModeService.modeSubject) {
      final uid = Provider.of<AuthService>(context, listen: false).user?.uid;
      if (uid != null) {
        final hasGuardian = await GuardianService().hasGuardian(uid);
        if (!mounted) return;
        // 보호자가 한 명도 없으면 바로 보호자 등록 화면으로
        if (!hasGuardian) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GuardianScreen()),
          );
          return;
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
      );
    } else if (mode == ModeService.modeGuardian) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GuardianModeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    const primaryColor = Color(0xFF5C6BC0);
    const surfaceColor = Color(0xFFF5F5F9);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          title: const Text('지금 어때?'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('지금 어때?'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false, // 뒤로 가기 버튼 숨김 (최상위 화면)
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
                '버튼 하나로\n안부를 전하는 앱입니다.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '하루 한 번이면 충분해요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                '어느 쪽으로 사용하시겠어요?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '선택은 언제든 변경할 수 있습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // 보호대상자 모드 버튼 (파란색)
              SizedBox(
                width: double.infinity,
                height: 140,
                child: FilledButton.icon(
                  onPressed: () => _selectMode(ModeService.modeSubject),
                  icon: const Icon(Icons.person, size: 56),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('보호대상자', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('안부를 남깁니다.', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3), // 파란색
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(28),
                    elevation: 8,
                    shadowColor: const Color(0xFF2196F3).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 보호자 모드 버튼 (초록색)
              SizedBox(
                width: double.infinity,
                height: 140,
                child: FilledButton.icon(
                  onPressed: () => _selectMode(ModeService.modeGuardian),
                  icon: const Icon(Icons.visibility, size: 56),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('보호자', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('안부를 확인합니다.', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // 초록색
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(28),
                    elevation: 8,
                    shadowColor: const Color(0xFF4CAF50).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 테스트 알림 버튼 (디버그용)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '테스트 알림',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendTestSubjectNotification(),
                            icon: const Icon(Icons.person, size: 18),
                            label: const Text('보호대상자 알림'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                              side: BorderSide(color: Colors.orange.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendTestGuardianNotification(),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('보호자 알림'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                              side: BorderSide(color: Colors.orange.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 테스트용: 보호대상자 알림 발송
  Future<void> _sendTestSubjectNotification() async {
    try {
      await NotificationService.instance.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보호대상자 테스트 알림이 발송되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 발송 실패: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 테스트용: 보호자 알림 발송
  Future<void> _sendTestGuardianNotification() async {
    try {
      await FCMService.instance.sendTestGuardianNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보호자 테스트 알림이 발송되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 발송 실패: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
