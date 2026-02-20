import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// 알림 권한 요청 헬퍼 클래스
class PermissionHelper {
  /// 한글 커스텀 다이얼로그를 표시한 후 알림 권한 요청
  /// [isForSubject] true면 보호대상자용 메시지, false면 보호자용 메시지
  static Future<bool> requestNotificationPermission(BuildContext? context, {bool isForSubject = false}) async {
    debugPrint('[PermissionHelper] 알림 권한 요청 시작 (isForSubject: $isForSubject)');
    // Android 13 이상에서만 권한 요청 필요
    if (Platform.isAndroid) {
      // 이미 권한이 허용되었는지 확인
      final isAlreadyGranted = await isNotificationPermissionGranted();
      debugPrint('[PermissionHelper] 권한 상태: $isAlreadyGranted');
      if (isAlreadyGranted) {
        debugPrint('[PermissionHelper] 권한이 이미 허용되어 있음 - 다이얼로그 표시 안 함');
        return true; // 이미 허용되었으면 다이얼로그 표시하지 않고 바로 반환
      }
      
      // 권한 요청 전에 한글 다이얼로그 표시
      if (context != null && context.mounted) {
        debugPrint('[PermissionHelper] 권한 요청 다이얼로그 표시 시작');
        final shouldRequest = await _showPermissionRequestDialog(context, isForSubject: isForSubject);
        debugPrint('[PermissionHelper] 사용자가 권한 요청 다이얼로그에서 선택: $shouldRequest');
        if (!shouldRequest) {
          debugPrint('[PermissionHelper] 사용자가 권한 요청을 취소함');
          return false;
        }
      } else {
        debugPrint('[PermissionHelper] Context가 없거나 mounted가 아님 - 다이얼로그 표시 불가');
      }
      
      // flutter_local_notifications를 통한 권한 요청
      final androidPlugin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission() ?? false;
      
      if (!granted && context != null && context.mounted) {
        // 권한이 거부된 경우 안내 다이얼로그 표시
        await _showPermissionDeniedDialog(context);
      }
      
      return granted;
    }
    
    // iOS는 flutter_local_notifications가 자동으로 처리
    return true;
  }
  
  /// 알림 권한 요청 다이얼로그 표시 (한글)
  /// [isForSubject] true면 보호대상자용 메시지, false면 보호자용 메시지
  static Future<bool> _showPermissionRequestDialog(BuildContext context, {bool isForSubject = false}) async {
    final dialogContent = isForSubject
        ? '하루 한 번 컨디션 기록 알림을 받으려면 알림 권한이 필요해요.\n\n'
          '다음 화면에서 「허용」을 눌러 주세요.'
        : '"보호대상자"가 상태를 등록한 경우 "보호자"께 알림을 보내도록 허용하시겠습니까?\n\n'
          '다음 화면에서 「허용」을 눌러 주세요.';
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '알림 권한 요청',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            dialogContent,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '허용 안 함',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '허용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  /// 권한이 거부된 경우 설정으로 이동 안내 다이얼로그
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            '안부 알림을 받으려면 알림 권한이 필요해요.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('설정으로 이동'),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 알림 권한 상태 확인
  static Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      // flutter_local_notifications를 통해 권한 상태 확인
      final androidPlugin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.areNotificationsEnabled() ?? false;
        debugPrint('[PermissionHelper] 알림 권한 상태 확인: $granted');
        return granted;
      }
      debugPrint('[PermissionHelper] Android 플러그인을 찾을 수 없음');
    }
    return true; // iOS는 flutter_local_notifications가 처리
  }
}
