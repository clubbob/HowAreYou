import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import 'question_screen.dart';
import 'guardian_screen.dart';
import 'guardian_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MoodService _moodService = MoodService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF5C6BC0);
    const surfaceColor = Color(0xFFF5F5F9);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text(
          '지금 어때?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
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
              Text(
                '지금 기분을 알려주세요',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _navigateToQuestion(),
                  icon: const Icon(Icons.sentiment_satisfied_rounded, size: 22),
                  label: const Text('상태 알려주기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const GuardianScreen()),
                    );
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 22),
                  label: const Text('보호자 관리'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const GuardianDashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 22),
                  label: const Text('보호자 확인'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Future<void> _navigateToQuestion() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    
    if (userId == null) return;

    final currentSlot = await _moodService.getCurrentTimeSlot();
    
    if (currentSlot == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재는 질문 시간이 아닙니다.'),
          ),
        );
      }
      return;
    }

    final hasResponded = await _moodService.hasRespondedToday(
      subjectId: userId,
      slot: currentSlot,
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(
            timeSlot: currentSlot,
            alreadyResponded: hasResponded,
          ),
        ),
      );
    }
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
