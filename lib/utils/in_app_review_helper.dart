import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-App Review 요청 헬퍼 (스토어 리뷰 팝업)
class InAppReviewHelper {
  static const String _keyReviewRequested = 'in_app_review_requested';
  static const int _minSuccessfulAddsBeforeReview = 2;

  /// 보호대상자 추가 성공 시 호출. 조건 충족 시 리뷰 요청 (시스템이 쿼터에 따라 표시/미표시)
  static Future<void> maybeRequestReviewAfterGuardianAdd() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('guardian_add_success_count') ?? 0;
    final newCount = count + 1;
    await prefs.setInt('guardian_add_success_count', newCount);

    if (prefs.getBool(_keyReviewRequested) == true) return;
    if (newCount < _minSuccessfulAddsBeforeReview) return;

    await prefs.setBool(_keyReviewRequested, true);

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }
}
