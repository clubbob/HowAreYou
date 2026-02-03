import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mode_service.dart';
import '../utils/button_styles.dart';
import '../widgets/app_logo.dart';
import 'subject_mode_screen.dart';
import 'guardian_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  }

  Future<void> _loadLastSelectedMode() async {
    final mode = await ModeService.getLastSelectedMode();
    if (mounted) {
      setState(() {
        _lastSelectedMode = mode;
        _isLoading = false;
      });
      // 마지막 선택한 모드가 있으면 자동으로 해당 모드로 진입
      if (mode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToMode(mode, skipSave: true);
        });
      }
    }
  }

  Widget _buildAppBarTitle() {
    return const AppLogo(height: 32, fontSize: 18, fontWeight: FontWeight.w600);
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
          title: _buildAppBarTitle(),
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
        title: _buildAppBarTitle(),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false, // 뒤로 가기 버튼 숨김 (최상위 화면)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: '로그아웃',
            onPressed: () => _showLogoutConfirm(context, authService),
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
              // 보호대상자 모드 버튼
              SizedBox(
                width: double.infinity,
                height: 120,
                child: FilledButton.icon(
                  onPressed: () => _selectMode(ModeService.modeSubject),
                  icon: const Icon(Icons.person, size: 48),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('보호대상자 모드', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 4),
                      Text('상태를 알려주는 모드', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(24),
                    elevation: 6,
                    shadowColor: primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 보호자 모드 버튼
              SizedBox(
                width: double.infinity,
                height: 120,
                child: FilledButton.icon(
                  onPressed: () => _selectMode(ModeService.modeGuardian),
                  icon: const Icon(Icons.visibility, size: 48),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('보호자 모드', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 4),
                      Text('보호 대상을 확인하는 모드', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(24),
                    elevation: 6,
                    shadowColor: primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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


  /// 로그아웃 전 확인 다이얼로그 (노인 등 잘못 탭 방지)
  Future<void> _showLogoutConfirm(
      BuildContext context, AuthService authService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppButtonStyles.primaryFilled,
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }
}
