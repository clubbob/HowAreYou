import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/permission_helper.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  static FCMService get instance => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize(String userId, {BuildContext? context}) async {
    // Android에서는 한글 커스텀 다이얼로그를 표시한 후 권한 요청
    if (context != null) {
      // 한글 커스텀 다이얼로그를 표시한 후 권한 요청
      await PermissionHelper.requestNotificationPermission(context);
    }
    
    // iOS용 알림 권한 요청 (Firebase Messaging)
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
  
  /// 권한 요청 (BuildContext가 있는 경우 한글 다이얼로그 표시)
  Future<void> requestPermissionWithDialog(BuildContext? context) async {
    if (context != null) {
      await PermissionHelper.requestNotificationPermission(context);
    }
  }

  /// 보호자 알림 채널 생성 (Android)
  /// 참고: Android 8.0 이상에서는 채널을 삭제하고 다시 생성해야 설정이 변경됩니다
  Future<void> _createGuardianNotificationChannel() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // 기존 채널 삭제 (설정 변경을 위해)
      try {
        await androidPlugin.deleteNotificationChannel('guardian_notifications');
        debugPrint('기존 알림 채널 삭제 완료');
      } catch (e) {
        debugPrint('알림 채널 삭제 실패 (무시): $e');
      }
      
      // 새 채널 생성 (소리 켜기)
      const androidChannel = AndroidNotificationChannel(
        'guardian_notifications',
        '보호자 알림',
        description: '보호 대상의 상태 확인 및 미회신 알림',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      await androidPlugin.createNotificationChannel(androidChannel);
      debugPrint('알림 채널 생성 완료 (소리: 켜기)');
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
    debugPrint('포그라운드 메시지 내용: ${message.notification?.body}');
    
    // 설정에서 알림 소리 켜기/끄기 확인
    final shouldPlaySound = await _getNotificationSoundEnabled();
    debugPrint('알림 소리 설정: $shouldPlaySound');
    
    // 포그라운드에서도 알림 표시 (로컬 알림 사용)
    final notification = message.notification;
    if (notification != null) {
      final androidDetails = AndroidNotificationDetails(
        'guardian_notifications',
        '보호자 알림',
        channelDescription: '보호 대상의 상태 확인 및 미회신 알림',
        importance: Importance.high,
        priority: Priority.high,
        playSound: shouldPlaySound,
        enableVibration: shouldPlaySound,
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: shouldPlaySound,
        sound: 'default', // 명시적으로 소리 파일 지정
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      debugPrint('알림 표시 중... (소리: $shouldPlaySound)');
      await _localNotifications.show(
        message.hashCode,
        notification.title ?? '알림',
        notification.body ?? '',
        details,
      );
      debugPrint('알림 표시 완료');
    } else {
      debugPrint('알림 데이터 없음');
    }
  }

  /// 알림 소리 설정 가져오기 (기본값: true)
  Future<bool> _getNotificationSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notification_sound_enabled') ?? true;
    } catch (e) {
      debugPrint('알림 소리 설정 읽기 실패: $e');
      return true; // 기본값: 소리 켜기
    }
  }

  /// 알림 소리 설정 저장하기
  Future<void> setNotificationSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_sound_enabled', enabled);
      debugPrint('알림 소리 설정 저장: $enabled');
    } catch (e) {
      debugPrint('알림 소리 설정 저장 실패: $e');
    }
  }

  /// 알림 소리 설정 가져오기 (public)
  Future<bool> getNotificationSoundEnabled() async {
    return await _getNotificationSoundEnabled();
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
