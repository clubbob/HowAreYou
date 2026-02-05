import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

/// 알림 권한 요청 헬퍼 클래스
class PermissionHelper {
  /// 한글 커스텀 다이얼로그를 표시한 후 알림 권한 요청
  static Future<bool> requestNotificationPermission(BuildContext? context) async {
    // Android 13 이상에서만 권한 요청 필요
    if (Platform.isAndroid) {
      // 권한 요청 전에 한글 다이얼로그 표시
      if (context != null && context.mounted) {
        final shouldRequest = await _showPermissionRequestDialog(context);
        if (!shouldRequest) {
          return false;
        }
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
  static Future<bool> _showPermissionRequestDialog(BuildContext context) async {
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
          content: const Text(
            '지금 어때?에서 알림을 보내도록 허용하시겠습니까?\n\n알림을 통해 하루 3번 상태 확인을 받을 수 있습니다.',
            style: TextStyle(
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
  
  /// 권한이 영구적으로 거부된 경우 설정으로 이동 안내 다이얼로그
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '알림 권한 필요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '알림을 받으려면 설정에서 알림 권한을 허용해주세요.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 설정 앱으로 이동 (permission_handler 없이)
                // 사용자가 수동으로 설정에서 권한을 허용해야 함
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('확인'),
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
        return granted;
      }
    }
    return true; // iOS는 flutter_local_notifications가 처리
  }
}
