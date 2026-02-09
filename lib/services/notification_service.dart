import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../main.dart';
import '../screens/question_screen.dart';
import '../models/mood_response_model.dart';
import '../services/mood_service.dart';
import '../services/mode_service.dart';
import '../screens/subject_mode_screen.dart';
import '../utils/permission_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 알림 권한 요청 (BuildContext가 있는 경우에만 한글 다이얼로그 표시)
    await _requestPermissions();
    
    // 보호자 알림 채널 생성 (Android)
    await _createGuardianNotificationChannel();
    
    // 일일 알림 스케줄 설정은 로그인 시에만 수행 (initialize에서는 제거)
  }
  
  /// 권한 요청 (BuildContext가 있는 경우 한글 다이얼로그 표시)
  Future<void> requestPermissionsWithDialog(BuildContext? context) async {
    if (context != null) {
      await PermissionHelper.requestNotificationPermission(context);
    } else {
      await _requestPermissions();
    }
  }

  /// 보호자 알림 채널 생성 (Android)
  Future<void> _createGuardianNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'guardian_notifications',
      '보호자 알림',
      description: '보호 대상의 상태 확인 및 미회신 알림',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  Future<void> _requestPermissions() async {
    // BuildContext를 사용할 수 있는 경우 한글 다이얼로그 표시
    final navigator = MyApp.navigatorKey.currentState;
    final context = navigator?.context;
    
    if (context != null) {
      // 한글 커스텀 다이얼로그를 표시한 후 권한 요청
      await PermissionHelper.requestNotificationPermission(context);
    } else {
      // BuildContext가 없는 경우 기본 권한 요청
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// 일일 알림 스케줄링 (로그인 시에만 호출)
  Future<void> scheduleDailyNotifications() async {
    await _notifications.cancelAll();

    try {
      // 하루 1회 저녁 시간(18:00)에만 알림 발송
      await _scheduleNotification(
        id: 1,
        title: '지금 어때?',
        body: '오늘 컨디션을 기록해 주세요.',
        hour: 18,
        minute: 0,
        useExact: true,
      );
      debugPrint('[알림] 일일 알림 스케줄링 완료 (매일 18:00)');
    } on Exception catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted') ||
          e.toString().contains('Exact alarms are not permitted')) {
        debugPrint('일일 알림: 정확 알람 권한 없음 → 대략적 시간으로 스케줄');
        await _scheduleNotification(id: 1, title: '지금 어때?', body: '오늘 컨디션을 기록해 주세요.', hour: 18, minute: 0, useExact: false);
      } else {
        rethrow;
      }
    }
  }

  /// 모든 알림 취소 (로그아웃 시 호출)
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('[알림] 모든 알림 취소 완료');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool useExact = true,
  }) async {
    final androidMode = useExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_mood_check',
          '일일 상태 확인',
          channelDescription: '하루 1번 상태를 확인하는 알림',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: androidMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 오늘 18:00 이전이고 아직 기록하지 않았다면 즉시 알림 표시
  /// 보호대상자 모드 진입 시 또는 로그인 시 호출
  Future<void> checkAndShowTodayNotificationIfNeeded(String subjectId) async {
    try {
      // 현재 시간 확인 (한국 시간)
      final now = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
      final today18 = tz.TZDateTime(
        tz.getLocation('Asia/Seoul'),
        now.year,
        now.month,
        now.day,
        18,
        0,
      );

      // 오늘 18:00 이전이고, 아직 기록하지 않았다면
      if (now.isBefore(today18)) {
        final moodService = MoodService();
        final hasResponded = await moodService.hasRespondedToday(subjectId: subjectId);
        
        if (!hasResponded) {
          // 즉시 알림 표시
          await _notifications.show(
            999, // 즉시 알림용 ID (스케줄 알림 ID와 구분)
            '지금 어때?',
            '오늘 컨디션을 기록해 주세요.',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_mood_check',
                '일일 상태 확인',
                channelDescription: '하루 1번 상태를 확인하는 알림',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
          debugPrint('[알림] 오늘 18:00 이전이고 기록하지 않아 즉시 알림 표시');
        }
      }
    } catch (e) {
      debugPrint('[알림] 오늘 알림 체크 오류: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) async {
    // 알림 탭 시 질문 화면으로 이동
    final navigator = MyApp.navigatorKey.currentState;
    if (navigator == null) return;

    // 24시 기준 하루 1회 → 알림 탭 시 항상 daily
    // 알림은 보호대상자용이므로 보호대상자 모드로 자동 진입
    await ModeService.saveSelectedMode(ModeService.modeSubject);

    navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    await Future.delayed(const Duration(milliseconds: 300));

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SubjectModeScreen(),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 300));

    navigator.push(
      MaterialPageRoute(
        builder: (_) => QuestionScreen(
          timeSlot: TimeSlot.daily,
          alreadyResponded: false,
        ),
      ),
    );
  }
}
