import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 모드 선택 관리 (보호대상자/보호자)
class ModeService {
  static const String _keyLastSelectedMode = 'last_selected_mode';
  static const String modeSubject = 'subject';
  static const String modeGuardian = 'guardian';

  /// 마지막 선택한 모드 가져오기
  static Future<String?> getLastSelectedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyLastSelectedMode);
    } catch (e) {
      return null;
    }
  }

  /// 선택한 모드 저장
  static Future<void> saveSelectedMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSelectedMode, mode);
    } catch (e) {
      // 저장 실패 시 무시
    }
  }

  /// 저장된 모드 삭제
  static Future<void> clearSelectedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastSelectedMode);
    } catch (e) {
      // 삭제 실패 시 무시
    }
  }
}
