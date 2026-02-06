import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mode_service.dart';
import '../services/fcm_service.dart';
import '../utils/button_styles.dart';
import '../utils/permission_helper.dart';
import '../main.dart';
import 'subject_mode_screen.dart';
import 'guardian_mode_screen.dart';
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
    // Android에서 알림 권한 요청 (한글 다이얼로그 표시)
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestNotificationPermission();
      });
    }
  }
  
  Future<void> _requestNotificationPermission() async {
    if (!mounted) return;
    
    // 권한이 이미 허용되었는지 확인
    final isGranted = await PermissionHelper.isNotificationPermissionGranted();
    if (!isGranted) {
      // 한글 커스텀 다이얼로그를 표시한 후 권한 요청
      await PermissionHelper.requestNotificationPermission(context);
      // FCM 서비스도 다시 초기화 (권한이 허용된 경우)
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user != null) {
        await FCMService.instance.initialize(authService.user!.uid, context: context);
      }
    }
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToMode(mode, skipSave: true);
        });
      }
    }
  }


  Future<void> _selectMode(String mode) async {
    await ModeService.saveSelectedMode(mode);
    _navigateToMode(mode);
  }

  void _navigateToMode(String mode, {bool skipSave = false}) {
    if (!skipSave) {
      ModeService.saveSelectedMode(mode);
    }

    if (mode == ModeService.modeSubject) {
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
                '어떤 모드로 사용하시겠어요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                      Text('보호대상자 모드', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('상태를 알려주는 모드', style: TextStyle(fontSize: 16)),
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
                      Text('보호자 모드', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('보호 대상을 확인하는 모드', style: TextStyle(fontSize: 16)),
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
            ],
          ),
        ),
      ),
    );
  }
}
