import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/permission_helper.dart';
import '../screens/guardian_dashboard_screen.dart';
import '../screens/subject_detail_screen.dart';
import 'notification_service.dart';
import 'guardian_service.dart';
import 'mood_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  static FCMService get instance => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // NotificationService의 플러그인 인스턴스 사용 (중복 초기화 방지)
  FlutterLocalNotificationsPlugin get _localNotifications => 
      NotificationService.instance.getNotificationsPlugin();

  String? _fcmToken;
  String? _lastInitializedUserId; // 마지막으로 초기화한 사용자 ID

  // 알림 액션 ID
  static const String actionOpenDashboard = 'OPEN_DASHBOARD';
  static const String actionDismiss = 'DISMISS';

  String? get fcmToken => _fcmToken;

  Future<void> initialize(String userId, {BuildContext? context, bool forceReinitialize = false}) async {
    // 같은 사용자이고 이미 초기화했으면 스킵 (중복 방지, forceReinitialize가 false인 경우)
    if (!forceReinitialize && _lastInitializedUserId == userId && _fcmToken != null) {
      debugPrint('FCM 이미 초기화됨: $userId (토큰: $_fcmToken)');
      return;
    }
    
    _lastInitializedUserId = userId;
    // Android에서는 한글 커스텀 다이얼로그를 표시한 후 권한 요청
    // 주의: 이미 화면에서 권한을 요청했으면 중복 요청하지 않음
    // (화면에서 요청하는 것이 우선순위가 높음)
    // if (context != null) {
    //   await PermissionHelper.requestNotificationPermission(context);
    // }
    
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

    // 로컬 알림은 NotificationService에서 이미 초기화되었으므로
    // 여기서는 다시 초기화하지 않음 (핸들러 충돌 방지)
    // FCM 포그라운드 메시지는 _handleForegroundMessage에서 처리

    // FCM 토큰 가져오기 (알림 권한이 있어야 토큰을 받을 수 있음)
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        await _saveTokenToFirestore(userId, _fcmToken!);
        debugPrint('FCM 토큰 저장 성공: $userId -> $_fcmToken');
      } else {
        debugPrint('FCM 토큰이 null이거나 비어있음 - 알림 권한이 필요할 수 있음');
      }
    } catch (e) {
      debugPrint('FCM 토큰 가져오기 실패: $e');
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
      
      // 새 채널 생성 (소리 켜기, 중요도 최대)
      const androidChannel = AndroidNotificationChannel(
        'guardian_notifications',
        '보호자 알림',
        description: '보호 대상의 상태 확인 및 미회신 알림',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      
      await androidPlugin.createNotificationChannel(androidChannel);
      debugPrint('보호자 알림 채널 생성 완료 (소리: 켜기, 중요도: 최대)');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final doc = await userRef.get();
      
      if (doc.exists) {
        // 문서가 있으면 update 사용
        await userRef.update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      } else {
        // 문서가 없으면 set with merge 사용
        await userRef.set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
      }
      debugPrint('FCM 토큰 저장 성공: $userId');
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
    final data = message.data;
    final type = data['type'];
    
    if (notification != null) {
      final notificationId = message.hashCode;
      
      // 보호 대상자 이름 가져오기 (보호자가 설정한 별칭 우선)
      String subjectDisplayName = '보호 대상';
      final subjectId = data['subjectId'];
      final user = FirebaseAuth.instance.currentUser;
      
      if (subjectId != null && user != null) {
        try {
          // 보호자가 설정한 별칭 확인
          final guardianService = GuardianService();
          subjectDisplayName = await guardianService.getSubjectDisplayNameForGuardian(
            subjectId,
            user.uid,
          );
        } catch (e) {
          debugPrint('[FCM 알림] 이름 가져오기 실패: $e');
          // 실패 시 data의 이름 사용
          subjectDisplayName = data['subjectDisplayName'] ?? '보호 대상';
        }
      } else {
        // subjectId가 없으면 data의 이름 사용
        subjectDisplayName = data['subjectDisplayName'] ?? '보호 대상';
      }
      
      // 알림 제목과 본문 수정 (제목 없이)
      final title = '';
      final body = '$subjectDisplayName님이 오늘 안부를 남겼어요.';
      
      final androidDetails = AndroidNotificationDetails(
        'guardian_notifications',
        '보호자 알림',
        channelDescription: '보호 대상의 상태 확인 및 미회신 알림',
        importance: Importance.max,
        priority: Priority.max,
        playSound: shouldPlaySound,
        enableVibration: shouldPlaySound,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        category: AndroidNotificationCategory.alarm,
        styleInformation: const BigTextStyleInformation(''),
        autoCancel: true,
        ongoing: false,
        showWhen: true,
        enableLights: true,
        color: const Color(0xFF4285F4),
        visibility: NotificationVisibility.public,
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: shouldPlaySound,
        sound: 'default',
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      debugPrint('[FCM 알림] 알림 표시 중... (소리: $shouldPlaySound, 타입: $type, 이름: $subjectDisplayName)');
      // payload에 type과 subjectId를 함께 전달 (subjectId가 있는 경우)
      final payload = subjectId != null && subjectId.toString().isNotEmpty 
          ? '$type|$subjectId' 
          : type;
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      
      // 10초 후 알림 자동 취소
      Future.delayed(const Duration(seconds: 10), () {
        _localNotifications.cancel(notificationId);
        debugPrint('[FCM 알림] 알림 자동 취소 (10초 후, ID: $notificationId)');
      });
      
      debugPrint('[FCM 알림] 알림 표시 완료 (ID: $notificationId)');
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

  /// 알림 탭 시 처리 (앱이 백그라운드에서 실행 중일 때 알림을 탭한 경우)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('알림 탭: ${message.notification?.title}');
    final data = message.data;
    final type = data['type'];
    final subjectId = data['subjectId']; // FCM data에서 subjectId 추출
    
    final navigator = MyApp.navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'RESPONSE_RECEIVED' || type == 'UNREACHABLE') {
      // subjectId가 있고 현재 사용자가 보호자인 경우 상세 화면으로 이동
      if (subjectId != null && subjectId.toString().isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              final guardianService = GuardianService();
              final moodService = MoodService();
              
              // 보호자가 해당 보호 대상자와 연결되어 있는지 확인
              final subjectIds = await guardianService.getSubjectIdsForGuardian(user.uid);
              if (subjectIds.contains(subjectId)) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => SubjectDetailScreen(
                      subjectId: subjectId.toString(),
                      guardianUid: user.uid,
                      guardianService: guardianService,
                      moodService: moodService,
                    ),
                  ),
                  (route) => false,
                );
                debugPrint('[FCM 알림] ✅ 보호 대상 상세 화면으로 이동 완료 (subjectId: $subjectId)');
                return;
              } else {
                debugPrint('[FCM 알림] ⚠️ 보호자가 해당 보호 대상자와 연결되어 있지 않음: $subjectId');
              }
            } catch (e) {
              debugPrint('[FCM 알림] ⚠️ 상세 화면 이동 실패: $e');
            }
            
            // 상세 화면으로 이동할 수 없는 경우 대시보드로 이동
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
              (route) => false,
            );
          });
          return;
        }
      }
      
      // subjectId가 없거나 상세 화면으로 이동할 수 없는 경우 대시보드로 이동
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
        (route) => false,
      );
    } else if (type == 'REMIND_RESPONSE') {
      navigator.pushNamed('/question');
    }
  }

  // 주의: 로컬 알림 응답 처리는 NotificationService의 통합 핸들러에서 처리됩니다.
  // 이 메서드는 더 이상 사용되지 않습니다 (중복 초기화 방지를 위해 제거됨).

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

  /// 테스트용: 보호자 알림 즉시 발송
  Future<void> sendTestGuardianNotification() async {
    try {
      debugPrint('[테스트 알림] 보호자 알림 발송 시작');
      
      // 현재 사용자 ID 가져오기
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[테스트 알림] 로그인하지 않은 사용자');
        return;
      }
      
      // 보호자가 연결한 첫 번째 보호 대상자 이름 가져오기 (보호자가 설정한 별칭 우선)
      String subjectName = '보호 대상';
      try {
        final guardianService = GuardianService();
        final subjectIds = await guardianService.getSubjectIdsForGuardian(user.uid);
        if (subjectIds.isNotEmpty) {
          subjectName = await guardianService.getSubjectDisplayNameForGuardian(
            subjectIds.first,
            user.uid,
          );
        }
      } catch (e) {
        debugPrint('[테스트 알림] 보호 대상자 이름 가져오기 실패: $e');
      }
      
      const notificationId = 9998;
      final title = '';
      final body = '$subjectName님이 오늘 안부를 남겼어요.';
      
      // 테스트용: 첫 번째 보호 대상자의 ID를 payload에 포함
      String? testSubjectId;
      try {
        final guardianService = GuardianService();
        final subjectIds = await guardianService.getSubjectIdsForGuardian(user.uid);
        if (subjectIds.isNotEmpty) {
          testSubjectId = subjectIds.first;
        }
      } catch (e) {
        debugPrint('[테스트 알림] 보호 대상자 ID 가져오기 실패: $e');
      }
      
      // payload에 type과 subjectId를 함께 전달 (subjectId가 있는 경우)
      final payload = testSubjectId != null && testSubjectId.isNotEmpty
          ? 'RESPONSE_RECEIVED|$testSubjectId'
          : 'RESPONSE_RECEIVED';
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'guardian_notifications',
            '보호자 알림',
            channelDescription: '보호 대상의 상태 확인 및 미회신 알림',
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
        payload: payload,
      );
      
      // 10초 후 알림 자동 취소
      Future.delayed(const Duration(seconds: 10), () {
        _localNotifications.cancel(notificationId);
        debugPrint('[테스트 알림] 보호자 알림 자동 취소 (10초 후)');
      });
      
      debugPrint('[테스트 알림] 보호자 알림 발송 완료 (ID: $notificationId, 이름: $subjectName)');
    } catch (e) {
      debugPrint('[테스트 알림] 오류: $e');
      rethrow;
    }
  }
}
