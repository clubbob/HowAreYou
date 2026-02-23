import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../screens/question_screen.dart';
import '../screens/home_screen.dart';
import '../screens/guardian_dashboard_screen.dart';
import '../screens/subject_detail_screen.dart';
import 'fcm_service.dart';
import '../models/mood_response_model.dart';
import '../services/guardian_service.dart';
import '../services/mode_service.dart';
import '../services/mood_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 알림 액션 ID
  static const String actionOpenQuestion = 'OPEN_QUESTION';
  static const String actionDismiss = 'DISMISS';
  
  // FCMService에서 플러그인 인스턴스 접근용 (공유)
  FlutterLocalNotificationsPlugin getNotificationsPlugin() => _notifications;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android 알림 채널 생성
    await _createDailyMoodCheckChannel();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final bool? initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    debugPrint('[알림] ✅ NotificationService 초기화 완료: $initialized');
    debugPrint('[알림] ✅ 알림 버튼 핸들러 등록됨: _onNotificationTapped');
    
    // 핸들러 등록 확인
    if (initialized == true) {
      print('✅✅✅ 알림 핸들러 등록 성공! ✅✅✅');
    } else {
      print('❌❌❌ 알림 핸들러 등록 실패! ❌❌❌');
    }
  }

  /// 일일 알림 채널 생성 (Android)
  Future<void> _createDailyMoodCheckChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'daily_mood_check',
      '일일 컨디션 확인',
      description: '하루 한 번 컨디션을 기록하도록 알림',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// 보호대상자 리마인드 알림 ID
  static const int subjectReminderNotificationId = 1;

  /// 다음 실행 시각 계산 (KST, 과거면 내일)
  tz.TZDateTime _nextTimeInKST(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// 공통 알림 상세 (내부)
  NotificationDetails _dailyReminderDetails({Color color = const Color(0xFF4285F4)}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_mood_check',
        '일일 컨디션 확인',
        channelDescription: '하루 한 번 컨디션을 기록하도록 알림',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        category: AndroidNotificationCategory.alarm,
        styleInformation: const BigTextStyleInformation(''),
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        enableLights: true,
        color: color,
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── 매일 반복 로컬 알림 (보호대상자 19:00) ────────────────────────────────────

  /// 보호대상자 리마인드 취소
  Future<void> cancelSubjectReminder() async {
    await _notifications.cancel(subjectReminderNotificationId);
    debugPrint('[알림] 보호대상자 리마인드 취소');
  }

  /// 보호대상자 매일 19:00 반복 (id=1). subjectEnabled 시 등록.
  Future<void> scheduleSubjectDailyReminder() async {
    try {
      await _notifications.cancel(subjectReminderNotificationId);
      await _notifications.zonedSchedule(
        subjectReminderNotificationId,
        '',
        '오늘 어때요? 편안한 저녁 되세요.',
        _nextTimeInKST(19, 0),
        _dailyReminderDetails(),
        payload: 'SUBJECT_REMINDER',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('[알림] 보호대상자 19시 리마인드 예약 완료 (매일 반복)');
    } catch (e) {
      debugPrint('[알림] 보호대상자 리마인드 예약 오류: $e');
    }
  }

  /// OS Push(FCM)로 전환됨. 로컬 19시 스케줄 비활성화.
  /// Cloud Scheduler가 매일 19:00/20:05에 FCM 발송.
  Future<void> scheduleDailyRemindersByRole() async {
    // no-op: FCM 기반 푸시로 대체됨
  }

  /// 모든 알림 취소 (로그아웃 시 호출)
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('[알림] 모든 알림 취소 완료');
  }

  /// 알림 탭/액션 버튼 클릭 처리 (통합 핸들러)
  void _onNotificationTapped(NotificationResponse response) async {
    // 핸들러 호출 확인용 - 이 로그가 안 보이면 핸들러가 호출되지 않는 것
    print('🔔🔔🔔 알림 핸들러 호출됨! 🔔🔔🔔');
    debugPrint('[알림] ========== 알림 버튼 클릭 감지 ==========');
    debugPrint('[알림] actionId: "${response.actionId}"');
    debugPrint('[알림] payload: "${response.payload}"');
    debugPrint('[알림] id: ${response.id}');

    // 취소 버튼 클릭
    if (response.actionId == actionDismiss || response.actionId == 'DISMISS') {
      debugPrint('[알림] ✅ 취소 버튼 클릭');
      if (response.id != null) {
        await _notifications.cancel(response.id!);
      }
      
      return;
    }

    // 보호자 알림 - 바로 확인 버튼
    if (response.actionId == 'OPEN_DASHBOARD') {
      debugPrint('[알림] ✅ 보호자 알림 - 대시보드로 이동');
      if (response.id != null) {
        await _notifications.cancel(response.id!);
      }
      _navigateToGuardianDashboard(response.payload);
      return;
    }
    
    // 보호대상자 알림 - 바로 확인 버튼
    if (response.actionId == actionOpenQuestion) {
      debugPrint('[알림] ✅ 보호대상자 알림 - 질문 화면으로 이동');
      if (response.id != null) {
        await _notifications.cancel(response.id!);
      }
      _navigateToQuestionScreen();
      return;
    }

    // 알림 탭 (actionId가 null인 경우) - payload로 구분
    if (response.actionId == null) {
      final payload = response.payload;
      // 보호대상자 19시 리마인드 (로컬 SUBJECT_REMINDER / FCM DAILY_REMINDER)
      if (payload == 'SUBJECT_REMINDER' || payload == 'DAILY_REMINDER' || response.id == subjectReminderNotificationId) {
        debugPrint('[알림] ✅ 보호대상자 리마인드 알림 탭 - 질문 화면으로 이동');
        if (response.id != null) await _notifications.cancel(response.id!);
        _navigateToQuestionScreen();
        return;
      }
      // FCM 보호자 알림 (RESPONSE_RECEIVED 등)
      if (payload == 'RESPONSE_RECEIVED' || payload == 'UNREACHABLE' || payload == 'ESCALATION_3DAYS' ||
          (payload != null && (payload.startsWith('RESPONSE_RECEIVED') || payload.startsWith('UNREACHABLE') || payload.startsWith('ESCALATION_3DAYS')))) {
        debugPrint('[알림] ✅ 보호자 FCM 알림 탭 - 상세 화면으로 이동');
        if (response.id != null) await _notifications.cancel(response.id!);
        _navigateToGuardianDashboard(payload);
      } else if (payload == 'ADMIN_BROADCAST' || (payload != null && payload.startsWith('ADMIN_BROADCAST'))) {
        // notificationResponseType: selectedNotification(탭) | selectedNotificationAction(버튼탭) 만 열람으로 인정
        final rt = response.notificationResponseType;
        final isUserTap = rt == NotificationResponseType.selectedNotification ||
            rt == NotificationResponseType.selectedNotificationAction;
        if (isUserTap) {
          debugPrint('[알림] ✅ 관리자 FCM 알림 탭 - 열람 보고 후 홈으로 이동');
          if (response.id != null) await _notifications.cancel(response.id!);
          await FCMService.reportAdminFcmOpened();
          _navigateToHome();
        } else {
          debugPrint('[알림] ADMIN_BROADCAST responseType=$rt - 사용자 탭 아님, 열람 보고 스킵');
          if (response.id != null) await _notifications.cancel(response.id!);
        }
      } else {
        debugPrint('[알림] ✅ 보호대상자 알림 탭 - 질문 화면으로 이동');
        if (response.id != null) await _notifications.cancel(response.id!);
        _navigateToQuestionScreen();
      }
      return;
    }
    
    debugPrint('[알림] ⚠️ 처리되지 않은 알림: actionId="${response.actionId}", payload="${response.payload}"');
  }


  /// 보호 대상 관리 화면으로 이동 (subjectId가 있으면 상세 화면으로 이동)
  void _navigateToGuardianDashboard(String? payload) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var navigator = MyApp.navigatorKey.currentState;
      if (navigator == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        navigator = MyApp.navigatorKey.currentState;
        if (navigator == null) {
          debugPrint('[알림] ❌ Navigator를 찾을 수 없음');
          return;
        }
      }

      // payload에서 subjectId 추출 (형식: "RESPONSE_RECEIVED|subjectId", "UNREACHABLE|subjectId", "ESCALATION_3DAYS|subjectId")
      String? subjectId;
      if (payload != null && payload.contains('|')) {
        final parts = payload.split('|');
        if (parts.length >= 2) {
          subjectId = parts[1];
          debugPrint('[알림] payload에서 subjectId 추출: $subjectId');
        }
      }

      // subjectId가 있고 현재 사용자가 보호자인 경우 상세 화면으로 이동
      if (subjectId != null && subjectId.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final guardianService = GuardianService();
            final moodService = MoodService();
            
            // 보호자가 해당 보호 대상자와 연결되어 있는지 확인
            final subjectIds = await guardianService.getSubjectIdsForGuardian(user.uid);
            if (subjectIds.contains(subjectId)) {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => SubjectDetailScreen(
                    subjectId: subjectId!,
                    guardianUid: user.uid,
                    guardianService: guardianService,
                    moodService: moodService,
                  ),
                ),
                (route) => false,
              );
              debugPrint('[알림] ✅ 보호 대상 상세 화면으로 이동 완료 (subjectId: $subjectId)');
              return;
            } else {
              debugPrint('[알림] ⚠️ 보호자가 해당 보호 대상자와 연결되어 있지 않음: $subjectId');
            }
          } catch (e) {
            debugPrint('[알림] ⚠️ 상세 화면 이동 실패: $e');
          }
        }
      }

      // subjectId가 없거나 상세 화면으로 이동할 수 없는 경우 대시보드로 이동
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
        (route) => false,
      );
      debugPrint('[알림] ✅ 보호자 대시보드로 이동 완료');
    });
  }

  /// 홈 화면으로 이동 (ADMIN_BROADCAST 탭 시)
  void _navigateToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var navigator = MyApp.navigatorKey.currentState;
      if (navigator == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        navigator = MyApp.navigatorKey.currentState;
      }
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen(skipAutoNavigation: true)),
          (route) => false,
        );
      }
    });
  }

  /// 컨디션 선택지 화면으로 이동
  void _navigateToQuestionScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ModeService.saveSelectedMode(ModeService.modeSubject);
      
      var navigator = MyApp.navigatorKey.currentState;
      if (navigator == null) {
        await Future.delayed(const Duration(milliseconds: 300));
        navigator = MyApp.navigatorKey.currentState;
        if (navigator == null) {
          debugPrint('[알림] ❌ Navigator를 찾을 수 없음');
          return;
        }
      }

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const QuestionScreen(
            timeSlot: TimeSlot.daily,
            alreadyResponded: false,
          ),
        ),
        (route) => false,
      );
      debugPrint('[알림] ✅ 질문 화면으로 이동 완료');
    });
  }

  /// 테스트용: 보호대상자 19시 리마인드 즉시 발송 (로컬 알림)
  Future<void> sendTestSubjectNotification() async {
    try {
      debugPrint('[테스트 알림] 보호대상자 리마인드 발송 시작');
      const notificationId = 9999;
      await _notifications.show(
        notificationId,
        '',
        '오늘 어때요? 편안한 저녁 되세요.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_mood_check',
            '일일 컨디션 확인',
            channelDescription: '하루 한 번 컨디션을 기록하도록 알림',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
            category: AndroidNotificationCategory.alarm,
            styleInformation: const BigTextStyleInformation(''),
            autoCancel: true,
            ongoing: false,
            showWhen: true,
            enableLights: true,
            color: const Color(0xFF4285F4),
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'SUBJECT_REMINDER',
      );
      Future.delayed(const Duration(seconds: 10), () {
        _notifications.cancel(notificationId);
        debugPrint('[테스트 알림] 보호대상자 리마인드 자동 취소 (10초 후)');
      });
      debugPrint('[테스트 알림] 보호대상자 리마인드 발송 완료 (ID: $notificationId)');
    } catch (e) {
      debugPrint('[테스트 알림] 오류: $e');
      rethrow;
    }
  }
}
