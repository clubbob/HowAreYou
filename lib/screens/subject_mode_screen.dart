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
import '../utils/constants.dart';
import '../utils/permission_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../services/movement_detection_service.dart';
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

class _SubjectModeScreenState extends State<SubjectModeScreen> with WidgetsBindingObserver {
  final MoodService _moodService = MoodService();
  bool _hasShownWelcomeDialog = false;
  bool? _notificationPermissionGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);
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
        // 이동 감지: 이 화면에 있을 때만 실행 (앱 시작 시 크래시 방지)
        final uid = authService.user?.uid;
        if (uid != null) {
          try {
            await MovementDetectionService.instance.start(uid);
          } catch (e) {
            debugPrint('[이동감지] 시작 실패: $e');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    try {
      MovementDetectionService.instance.stop();
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      PermissionHelper.isNotificationPermissionGranted().then((granted) {
        if (mounted) setState(() => _notificationPermissionGranted = granted);
      }).catchError((_) {});
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: Icon(Icons.settings, size: 18, color: Colors.orange.shade700),
                          label: Text('설정에서 켜기', style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FutureBuilder<({bool hasToday, int currentStreak})>(
                future: authService.user?.uid != null
                    ? () async {
                        final uid = authService.user!.uid;
                        final hasToday = await _moodService.hasRespondedToday(subjectId: uid);
                        final streakData = await _moodService.getStreak(uid);
                        return (hasToday: hasToday, currentStreak: streakData?.currentStreak ?? 0);
                      }()
                    : Future.value((hasToday: false, currentStreak: 0)),
                builder: (context, snapshot) {
                  final hasToday = snapshot.data?.hasToday ?? false;
                  final streak = snapshot.data?.currentStreak ?? 0;
                  final String message;
                  final String icon;
                  if (hasToday) {
                    message = streak == 1 ? '오늘 안부를 전했어요' : '$streak일 연속 기록 중';
                    icon = '🔥';
                  } else {
                    message = '오늘 기록 안했어요';
                    icon = '⏳';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasToday ? Colors.orange.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                        border: Border.all(
                          color: hasToday ? Colors.orange.shade200 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: hasToday ? Colors.orange.shade800 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '오늘 컨디션은 어떤가요?',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      letterSpacing: -0.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
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
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _navigateToQuestion(),
                  icon: const Icon(Icons.sentiment_satisfied_rounded, size: 22),
                  label: const Text('오늘 컨디션 전하기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
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
                  label: const Text('지난 컨디션 보기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuardianScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 22),
                  label: const Text('보호자 관리'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
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
        builder: (ctx) {
          final primary = Theme.of(ctx).colorScheme.primary;
          return AlertDialog(
            title: const Text('오늘 안부는 이미 전달됐어요'),
            content: const Text(
              '오늘 기록은 이미 보호자에게 전달되었습니다.\n'
              '필요하다면 다시 선택할 수 있어요.',
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop('close'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('닫기'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop('retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('다시 선택하기'),
              ),
            ],
          );
        },
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
