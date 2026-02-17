import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 이용약관·개인정보처리방침 다이얼로그 (최초 가입 시와 설정 화면에서 동일하게 사용)
class LegalDialog {
  static const _termsPath = 'assets/terms_content.txt';
  static const _privacyPath = 'assets/privacy_content.txt';

  /// 이용약관 다이얼로그 표시 (최초 가입 시와 동일한 내용·형식)
  static Future<void> showTerms(BuildContext context) async {
    String content;
    try {
      content = await rootBundle.loadString(_termsPath);
    } catch (_) {
      content = '이용약관 내용을 불러올 수 없습니다.';
    }
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('이용약관'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  /// 개인정보처리방침 다이얼로그 표시 (최초 가입 시와 동일한 내용·형식)
  static Future<void> showPrivacy(BuildContext context) async {
    String content;
    try {
      content = await rootBundle.loadString(_privacyPath);
    } catch (_) {
      content = '개인정보처리방침 내용을 불러올 수 없습니다.';
    }
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('개인정보처리방침'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}
