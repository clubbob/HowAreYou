import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'services/invite_pending_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/guardian_mode_screen.dart';
import 'screens/question_screen.dart';
import 'models/mood_response_model.dart';

// 디버그 시각적 도구 비활성화
void _disableDebugVisuals() {
  if (kDebugMode) {
    // 파란색 위젯 아웃라인 비활성화
    debugPaintSizeEnabled = false;
    
    // 원본 debugPrint 저장
    final originalDebugPrint = debugPrint;
    
    // Flutter 포커스·에뮬레이터 EGL 로그 필터링 (터미널 가독성)
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
        return;
      }
      if (message.contains('FocusScopeNode') ||
          message.contains('FocusNode') ||
          message.contains('FocusManager') ||
          message.contains('PRIMARY FOCUS') ||
          message.contains('Root Focus Scope') ||
          message.contains('_ModalScopeState') ||
          message.contains('EGL_emulation') ||
          message.contains('app_time_stats')) {
        return;
      }
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }
}

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('백그라운드 메시지 처리: ${message.messageId}');
  debugPrint('알림 제목: ${message.notification?.title}');
  debugPrint('알림 내용: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 디버그 시각적 도구 및 출력 비활성화
  _disableDebugVisuals();

  // 한국 시간 사용을 위해 timezone 초기화 (MoodService 등에서 사용)
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // 한국어 날짜 포맷 (보호자 대시보드 7일 이력 등)
  await initializeDateFormatting('ko_KR', null);

  // Firebase 초기화 (모바일 플랫폼만)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase 초기화 오류: $e');
      MyApp.firebaseInitFailed = true;
    }
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('알림 서비스 초기화 오류 (앱은 계속 실행됩니다): $e');
    }
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 데스크톱 플랫폼에서는 Firebase 초기화 시도 (선택적)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase 초기화 실패 (데스크톱): $e');
      debugPrint('데스크톱에서는 Firebase 기능이 제한될 수 있습니다.');
    }
  }

  // 초대 링크로 앱이 열렸는지 확인 (딥링크 g= 보호자 UID, s= 보호대상자 UID)
  try {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();
    if (uri != null) {
      final g = uri.queryParameters['g'];
      if (g != null && g.isNotEmpty) {
        await InvitePendingService.setPendingInviterId(g);
      }
      final s = uri.queryParameters['s'];
      if (s != null && s.isNotEmpty) {
        await InvitePendingService.setPendingSubjectId(s);
      }
    }
  } catch (_) {}

  // 미설치 → 스토어 설치 → 앱 첫 실행: Install Referrer에서 inviterId/subjectId 복원
  if (!kIsWeb && Platform.isAndroid) {
    try {
      const channel = MethodChannel('howareyou/install_referrer');
      final referrer = await channel.invokeMethod<String>('getInstallReferrer');
      if (referrer != null && referrer.isNotEmpty) {
        final inviterId = _parseInviterIdFromReferrer(referrer);
        if (inviterId != null && inviterId.isNotEmpty) {
          await InvitePendingService.setPendingInviterId(inviterId);
        }
        final subjectId = _parseSubjectIdFromReferrer(referrer);
        if (subjectId != null && subjectId.isNotEmpty) {
          await InvitePendingService.setPendingSubjectId(subjectId);
        }
      }
    } catch (_) {}
  }

  runApp(const MyApp());
}

/// Play Install Referrer 문자열에서 inviterId 추출 (예: inviterId=uid 또는 inviterId%3Duid)
String? _parseInviterIdFromReferrer(String referrer) {
  return _parseReferrerParam(referrer, 'inviterId');
}

/// Play Install Referrer 문자열에서 subjectId 추출 (보호대상자 → 보호자 초대 링크)
String? _parseSubjectIdFromReferrer(String referrer) {
  return _parseReferrerParam(referrer, 'subjectId');
}

String? _parseReferrerParam(String referrer, String paramKey) {
  try {
    final parts = referrer.split('&');
    for (final part in parts) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final key = Uri.decodeComponent(part.substring(0, idx).trim());
      final value = part.substring(idx + 1).trim();
      if (key == paramKey && value.isNotEmpty) {
        return Uri.decodeComponent(value);
      }
    }
  } catch (_) {}
  return null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  /// Firebase 초기화 실패 시 true (스플래시/첫 화면에서 안내 표시용)
  static bool firebaseInitFailed = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: '지금 어때?',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4285F4), // Google Blue (Pixel 6)
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Pixel 6 background
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF202124), // Pixel 6 text color
            titleTextStyle: TextStyle(
              color: Color(0xFF202124),
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: const TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28), // Pixel 6 style rounded corners
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4285F4),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(skipAutoNavigation: true),
          '/guardian': (context) => const GuardianModeScreen(),
          '/question': (context) => const QuestionScreen(timeSlot: TimeSlot.daily),
        },
      ),
    );
  }
}
