import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  static FCMService get instance => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize(String userId) async {
    // 알림 권한 요청
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('사용자가 알림 권한을 허용했습니다.');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('사용자가 임시 알림 권한을 허용했습니다.');
    } else {
      debugPrint('사용자가 알림 권한을 거부했습니다.');
    }

    // 보호자 알림 채널 생성 (Android)
    await _createGuardianNotificationChannel();

    // FCM 토큰 가져오기
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      await _saveTokenToFirestore(userId, _fcmToken!);
      debugPrint('FCM 토큰: $_fcmToken');
    }

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenToFirestore(userId, newToken);
      debugPrint('FCM 토큰 갱신: $newToken');
    });

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 메시지 핸들러 (앱이 열린 상태에서 알림 탭)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
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

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      debugPrint('FCM 토큰 저장 실패: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');
    
    // 포그라운드에서도 알림 표시 (로컬 알림 사용)
    final notification = message.notification;
    if (notification != null) {
      final androidDetails = AndroidNotificationDetails(
        'guardian_notifications',
        '보호자 알림',
        channelDescription: '보호 대상의 상태 확인 및 미회신 알림',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        message.hashCode,
        notification.title ?? '알림',
        notification.body ?? '',
        details,
      );
    }
  }

  /// 알림 탭 시 처리 (앱이 열린 상태에서 알림을 탭한 경우)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('알림 탭: ${message.notification?.title}');
    final data = message.data;
    final type = data['type'];
    
    final navigator = MyApp.navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'RESPONSE_RECEIVED' || type == 'UNREACHABLE') {
      // 보호자 모드로 이동
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      // TODO: 보호자 대시보드로 이동하거나 알림 상세 화면 표시
    }
  }

  Future<void> removeToken(String userId) async {
    if (_fcmToken != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([_fcmToken!]),
        });
      } catch (e) {
        debugPrint('FCM 토큰 제거 실패: $e');
      }
    }
  }
}
