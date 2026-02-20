import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/guardian_service.dart';
import '../services/mode_service.dart';
import '../services/mood_service.dart';
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

class _GuardianModeScreenState extends State<GuardianModeScreen> with WidgetsBindingObserver {
  bool? _notificationPermissionGranted;
  final GuardianService _guardianService = GuardianService();
  final MoodService _moodService = MoodService();

  /// 보호대상자 목록 + 오늘 기록 여부 로드
  Future<({List<String> subjectIds, bool hasTodayRecord})> _loadGuardianStatus(String? guardianUid) async {
    if (guardianUid == null) return (subjectIds: <String>[], hasTodayRecord: false);
    final ids = await _guardianService.getSubjectIdsForGuardian(guardianUid);
    if (ids.isEmpty) return (subjectIds: <String>[], hasTodayRecord: false);
    var hasToday = false;
    for (final id in ids) {
      final today = await _moodService.getTodayResponses(id, forGuardian: true);
      if (today.values.any((r) => r != null)) {
        hasToday = true;
        break;
      }
    }
    return (subjectIds: ids, hasTodayRecord: hasToday);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 보호자 역할 활성 플래그 설정 (스케줄은 Splash/포그라운드 복귀에서만)
    ModeService.setGuardianEnabled(true);
    // 보호자 모드 진입 시 FCM 초기화 (알림 수신을 위해)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      PermissionHelper.isNotificationPermissionGranted().then((granted) {
        if (mounted) setState(() => _notificationPermissionGranted = granted);
      });
    }
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
        if (mounted) setState(() => _notificationPermissionGranted = isGranted);
        if (!isGranted && mounted) {
          debugPrint('[보호자 모드] 알림 권한 요청 시작');
          final granted = await PermissionHelper.requestNotificationPermission(context, isForSubject: false);
          debugPrint('[보호자 모드] 알림 권한 요청 결과: $granted');
          if (mounted) setState(() => _notificationPermissionGranted = granted);
        } else {
          debugPrint('[보호자 모드] 알림 권한이 이미 허용되어 있음');
        }
      } catch (e) {
        debugPrint('[보호자 모드] 알림 권한 요청 오류: $e');
        if (mounted) setState(() => _notificationPermissionGranted = false);
      }
    } else {
      if (mounted) setState(() => _notificationPermissionGranted = true);
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GuardianSettingsScreen()),
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
                          '알림을 켜야 안부 확인 알림을 받을 수 있습니다.',
                          style: TextStyle(fontSize: 14, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // 보호대상자 오늘 기록 여부 상태 배지
              FutureBuilder<({List<String> subjectIds, bool hasTodayRecord})>(
                future: _loadGuardianStatus(authService.user?.uid),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (snapshot.connectionState == ConnectionState.waiting && data == null) {
                    return const SizedBox.shrink();
                  }
                  final count = data?.subjectIds.length ?? 0;
                  final hasToday = data?.hasTodayRecord ?? false;
                  String message;
                  IconData icon;
                  if (count == 0) {
                    message = '보호 대상을 추가해 보세요';
                    icon = Icons.people_outline;
                  } else if (hasToday) {
                    message = '오늘 기록이 있어요';
                    icon = Icons.check_circle_outline;
                  } else {
                    message = '오늘 기록이 없어요';
                    icon = Icons.schedule_outlined;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasToday ? Colors.green.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasToday ? Colors.green.shade200 : Colors.blue.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: hasToday ? Colors.green.shade700 : Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: hasToday ? Colors.green.shade800 : Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Text(
                '보호자 모드',
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
                '안부 확인과 보호 대상을 관리하세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 88,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuardianDashboardScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 40),
                  label: const Text('안부 확인'),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuardianDashboardScreen(initialTabIndex: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people_outline, size: 22),
                  label: const Text('보호 대상 관리'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor, width: 1.5),
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
              const SizedBox(height: 32),
              // 안내 문구 (보호대상자 화면과 동일 스타일)
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
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '보호대상자의 안부를 확인할 수 있어요.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade900,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '기록 내용(기분, 메모)은 공유되지 않으며, 안부가 전달되었는지만 표시됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
