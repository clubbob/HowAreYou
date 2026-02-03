import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/button_styles.dart';
import '../widgets/app_logo.dart';
import 'guardian_dashboard_screen.dart';
import 'home_screen.dart';

/// 보호자 모드 화면 (보호 대상 확인)
class GuardianModeScreen extends StatelessWidget {
  const GuardianModeScreen({super.key});

  Widget _buildAppBarTitle() {
    return const AppLogo(height: 32, fontSize: 18, fontWeight: FontWeight.w600);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    const primaryColor = Color(0xFF5C6BC0);
    const surfaceColor = Color(0xFFF5F5F9);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 홈 화면(역할 선택 화면)으로 돌아가기
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
          tooltip: '뒤로',
        ),
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

  /// 로그아웃 전 확인 다이얼로그
  static Future<void> _showLogoutConfirm(
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
    if (confirmed == true && context.mounted) {
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }
}
