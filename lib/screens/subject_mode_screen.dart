import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import '../services/mood_service.dart';
import '../services/mode_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import '../utils/permission_helper.dart';
import '../main.dart';
import 'question_screen.dart';
import 'guardian_screen.dart';
import 'home_screen.dart';
import 'subject_my_status_screen.dart';
import 'subject_settings_screen.dart';
import 'auth_screen.dart';

/// 보호대상자 모드 화면 (상태 알려주기, 보호자 관리)
class SubjectModeScreen extends StatefulWidget {
  const SubjectModeScreen({super.key});

  @override
  State<SubjectModeScreen> createState() => _SubjectModeScreenState();
}

class _SubjectModeScreenState extends State<SubjectModeScreen> {
  final MoodService _moodService = MoodService();
  bool _hasShownWelcomeDialog = false;
  bool? _notificationPermissionGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 환영 다이얼로그와 알림 권한 요청을 순차적으로 처리
      final shouldShowWelcome = await _checkAndShowWelcomeDialog();
      if (shouldShowWelcome && mounted) {
        // 환영 다이얼로그가 표시된 경우, 닫힌 후 권한 요청
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // 환영 다이얼로그가 표시되지 않은 경우, 바로 권한 요청
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted) {
        await _requestNotificationPermission();
        // 보호대상자 역할 활성 플래그 설정 (스케줄은 Splash/포그라운드 복귀에서만)
        await ModeService.setSubjectEnabled(true);
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (!mounted) return;
    
    // Android에서 알림 권한 확인 및 요청 (보호대상자는 로컬 알림 필요)
    if (Platform.isAndroid) {
      try {
        final isGranted = await PermissionHelper.isNotificationPermissionGranted();
        debugPrint('[보호대상자] 알림 권한 상태: $isGranted');
        if (mounted) setState(() => _notificationPermissionGranted = isGranted);
        if (!isGranted && mounted) {
          debugPrint('[보호대상자] 알림 권한 요청 시작');
          final granted = await PermissionHelper.requestNotificationPermission(context, isForSubject: true);
          debugPrint('[보호대상자] 알림 권한 요청 결과: $granted');
          if (mounted) setState(() => _notificationPermissionGranted = granted);
        } else {
          debugPrint('[보호대상자] 알림 권한이 이미 허용되어 있음');
        }
      } catch (e) {
        debugPrint('[보호대상자] 알림 권한 요청 오류: $e');
        if (mounted) setState(() => _notificationPermissionGranted = false);
      }
    } else {
      if (mounted) setState(() => _notificationPermissionGranted = true);
    }
  }

  /// 환영 다이얼로그 표시 여부를 반환 (true면 표시됨, false면 이미 표시됨)
  Future<bool> _checkAndShowWelcomeDialog() async {
    if (_hasShownWelcomeDialog) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final hasShownBefore = prefs.getBool('subject_mode_welcome_shown') ?? false;
    
    if (hasShownBefore) {
      return false; // 이미 표시되었으면 false 반환
    }
    
    if (!mounted) return false;
    
    _hasShownWelcomeDialog = true;
    await prefs.setBool('subject_mode_welcome_shown', true);
    
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('안내'),
            content: const Text(
              '하루 한 번이면 충분해요.\n\n'
              '간단히 컨디션을 기록해 두세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return true; // 다이얼로그가 표시되었으면 true 반환
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF5C6BC0);
    const surfaceColor = Color(0xFFF5F5F9);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('보호대상자 모드'),
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubjectSettingsScreen()),
              );
            },
          ),
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade800,
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('로그아웃'),
                          ),
                        ),
                      ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 알림 권한 거부 시 배너 (비용 0원 보완)
              if (_notificationPermissionGranted == false) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_off_outlined, color: Colors.orange.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '알림을 켜야 컨디션 기록 알림을 받을 수 있습니다.',
                          style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FutureBuilder<({int currentStreak, int longestStreak})?>(
                future: authService.user?.uid != null
                    ? _moodService.getStreak(authService.user!.uid)
                    : Future.value(null),
                builder: (context, snapshot) {
                  final streak = snapshot.data?.currentStreak ?? 0;
                  if (streak < 1) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔥', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '$streak일 연속 기록 중',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Text(
                '오늘도 잘 지내고 계신가요?',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '하루 한 번이면 충분합니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 88,
                child: FilledButton(
                  onPressed: () => _navigateToQuestion(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    elevation: 6,
                    shadowColor: primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sentiment_satisfied_rounded, size: 40),
                        const SizedBox(width: 12),
                        Text(
                          '오늘 컨디션 기록하기',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final userId = authService.user?.uid;
                    if (userId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubjectMyStatusScreen(subjectId: userId),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.history_rounded, size: 22),
                  label: const Text('최근 컨디션'),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuardianScreen(),
                      ),
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
              const SizedBox(height: 24),
              // 안내 문구
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '하루 한 번, 버튼만 누르면 안부가 전달돼요.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '보호자에게 기록 내용은 공유되지 않으며, 안부가 전달되었는지만 표시됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearTodayResponse() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오늘 응답 취소'),
        content: const Text(
          '오늘 남긴 기록을 취소할까요?\n취소하면 다시 기록을 남길 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _moodService.deleteTodayResponse(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취소되었습니다. 다시 기록을 남겨주세요.')),
      );
    }
  }

  Future<void> _navigateToQuestion() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;

    if (userId == null) return;

    // 컨디션 기록은 보호자 여부와 상관없이 항상 허용 (기록 후 보호자 있으면 알림 발송)
    final hasResponded = await _moodService.hasRespondedToday(subjectId: userId);
    if (hasResponded && mounted) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('오늘 안부는 이미 전달됐어요'),
          content: const Text(
            '오늘 기록은 이미 보호자에게 전달되었습니다.\n'
            '필요하다면 다시 선택할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('close'),
              child: const Text('닫기'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('retry'),
              child: const Text('다시 선택하기'),
            ),
          ],
        ),
      );
      if (choice != 'retry' || !mounted) return;
      // "다시 선택하기"를 선택한 경우, 삭제하지 않고 화면만 열기
      // saveMoodResponse가 이미 덮어쓰므로 저장할 때 자동으로 처리됨
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(
            timeSlot: TimeSlot.daily,
            alreadyResponded: false,
          ),
        ),
      );
    }
  }
}
