import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
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

/// 초기화 실패 시 표시하는 최소 화면 (앱이 꺼지지 않도록)
Widget _buildFallbackApp(String message) {
  return MaterialApp(
    title: '오늘 어때?',
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  runZonedGuarded(() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // 디버그 시각적 도구 및 출력 비활성화
      _disableDebugVisuals();

      // 위젯 빌드 오류 시 앱이 꺼지지 않도록 안전한 오류 위젯 사용
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      '일시적인 화면 오류가 발생했습니다.\n다른 화면으로 이동해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      };

      // 한국 시간 사용을 위해 timezone 초기화 (실패해도 앱은 계속 실행)
      try {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      } catch (_) {}

      // 한국어 날짜 포맷 (보호자 대시보드 7일 이력 등)
      try {
        await initializeDateFormatting('ko_KR', null);
      } catch (_) {}

      // Firebase 초기화 (모바일 플랫폼만)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        // Firebase Crashlytics 초기화 (Firebase.initializeApp 이후)
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

        // FlutterError.onError → Crashlytics 연결 (Flutter 프레임워크 오류 수집)
        FlutterError.onError = (FlutterErrorDetails details) {
          if (!MyApp.firebaseInitFailed) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          }
          if (kDebugMode) {
            FlutterError.presentError(details);
          }
          // 릴리즈에서는 presentError 호출 안 함 → 앱 종료 방지
        };
        PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
          if (!MyApp.firebaseInitFailed) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
          }
          return true; // 오류 처리함 → 앱 종료하지 않음
        };
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
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Firebase 초기화 실패 (데스크톱): $e');
      }
    }

    // 초대 링크로 앱이 열렸는지 확인
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

    // Install Referrer에서 inviterId/subjectId 복원
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
    } catch (e, stack) {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !MyApp.firebaseInitFailed) {
        try {
          FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
        } catch (_) {}
      }
      runApp(_buildFallbackApp('일시적인 오류가 발생했습니다.\n앱을 다시 실행해 주세요.'));
    }
  }, (error, stack) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && !MyApp.firebaseInitFailed) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    }
    // zone 비동기 오류: 처리했으므로 앱 종료하지 않음 (rethrow 안 함)
  });
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
      child: _AppLifecycleHandler(
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: '오늘 어때?',
        locale: const Locale('ko', 'KR'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
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
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              visualDensity: VisualDensity.comfortable,
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
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: AppConstants.primaryColor.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              side: BorderSide(color: AppConstants.primaryColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
      ),
    );
  }
}

/// 앱 포그라운드 복귀 시 역할별 알림 스케줄 재확인
class _AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const _AppLifecycleHandler({required this.child});

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler>
    with WidgetsBindingObserver {
  /// 포그라운드 복귀 시 연속 이벤트 디바운스 (2초)
  Timer? _resumeDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _resumeDebounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeDebounceTimer?.cancel();
      _resumeDebounceTimer = Timer(const Duration(seconds: 2), () {
        _resumeDebounceTimer = null;
        if (!mounted) return;
        final auth = context.read<AuthService>();
        if (auth.isAuthenticated) {
          NotificationService.instance.scheduleDailyRemindersByRole().catchError((e) {
            debugPrint('알림 스케줄링 오류 (무시): $e');
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
