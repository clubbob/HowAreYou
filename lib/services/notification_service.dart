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
    
    // 일일 알림 스케줄 설정
    await scheduleDailyNotifications();
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

  Future<void> scheduleDailyNotifications() async {
    await _notifications.cancelAll();

    try {
      await _scheduleNotification(
        id: 1,
        title: '지금 어때?',
        body: '오늘 컨디션을 기록해 주세요.',
        hour: 8,
        minute: 0,
        useExact: true,
      );
      await _scheduleNotification(
        id: 2,
        title: '지금 어때?',
        body: '오늘 컨디션을 기록해 주세요.',
        hour: 12,
        minute: 0,
        useExact: true,
      );
      await _scheduleNotification(
        id: 3,
        title: '지금 어때?',
        body: '오늘 컨디션을 기록해 주세요.',
        hour: 18,
        minute: 0,
        useExact: true,
      );
    } on Exception catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted') ||
          e.toString().contains('Exact alarms are not permitted')) {
        debugPrint('일일 알림: 정확 알람 권한 없음 → 대략적 시간으로 스케줄');
        await _scheduleNotification(id: 1, title: '지금 어때?', body: '오늘 컨디션을 기록해 주세요.', hour: 8, minute: 0, useExact: false);
        await _scheduleNotification(id: 2, title: '지금 어때?', body: '오늘 컨디션을 기록해 주세요.', hour: 12, minute: 0, useExact: false);
        await _scheduleNotification(id: 3, title: '지금 어때?', body: '오늘 컨디션을 기록해 주세요.', hour: 18, minute: 0, useExact: false);
      } else {
        rethrow;
      }
    }
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
          channelDescription: '하루 3번 상태를 확인하는 알림',
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
