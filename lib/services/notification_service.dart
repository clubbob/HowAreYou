import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../main.dart';
import '../screens/question_screen.dart';
import '../models/mood_response_model.dart';
import '../services/mood_service.dart';

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

    // 알림 권한 요청
    await _requestPermissions();
    
    // 일일 알림 스케줄 설정
    await scheduleDailyNotifications();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyNotifications() async {
    // 기존 알림 취소
    await _notifications.cancelAll();

    // 아침 08:00
    await _scheduleNotification(
      id: 1,
      title: '지금 어때?',
      body: '아침 상태를 알려주세요.',
      hour: 8,
      minute: 0,
    );

    // 점심 12:00
    await _scheduleNotification(
      id: 2,
      title: '지금 어때?',
      body: '점심 상태를 알려주세요.',
      hour: 12,
      minute: 0,
    );

    // 저녁 18:00
    await _scheduleNotification(
      id: 3,
      title: '지금 어때?',
      body: '저녁 상태를 알려주세요.',
      hour: 18,
      minute: 0,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

    // 알림 ID로 시간대 판단
    TimeSlot? timeSlot;
    switch (response.id) {
      case 1:
        timeSlot = TimeSlot.morning;
        break;
      case 2:
        timeSlot = TimeSlot.noon;
        break;
      case 3:
        timeSlot = TimeSlot.evening;
        break;
    }

    if (timeSlot != null) {
      // 홈 화면으로 먼저 이동한 후 질문 화면으로 이동
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      await Future.delayed(const Duration(milliseconds: 300));
      navigator.push(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(timeSlot: timeSlot!),
        ),
      );
    }
  }
}
