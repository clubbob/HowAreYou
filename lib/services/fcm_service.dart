import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  static FCMService get instance => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    // 백그라운드 메시지 핸들러 (앱이 종료된 상태)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
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

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('포그라운드 메시지 수신: ${message.notification?.title}');
    // 여기서 로컬 알림을 표시할 수 있습니다
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('백그라운드 메시지 수신: ${message.notification?.title}');
    // 앱이 열린 상태에서 알림을 탭한 경우 처리
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
