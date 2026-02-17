import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 모드 선택 관리 (보호대상자/보호자)
class ModeService {
  static const String _keyLastSelectedMode = 'last_selected_mode';
  static const String _keySubjectEnabled = 'roles_subject_enabled';
  static const String _keyGuardianEnabled = 'roles_guardian_enabled';
  static const String modeSubject = 'subject';
  static const String modeGuardian = 'guardian';

  /// 보호대상자 역할 활성 여부 (알림 스케줄용)
  static Future<bool> isSubjectEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySubjectEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 보호자 역할 활성 여부 (알림 스케줄용)
  static Future<bool> isGuardianEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyGuardianEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 보호대상자 역할 활성 설정 (SubjectModeScreen 진입 시 호출)
  static Future<void> setSubjectEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySubjectEnabled, value);
    } catch (e) {
      // 저장 실패 시 무시
    }
  }

  /// 보호자 역할 활성 설정 (GuardianModeScreen 진입 시 호출)
  static Future<void> setGuardianEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGuardianEnabled, value);
    } catch (e) {
      // 저장 실패 시 무시
    }
  }

  /// 마지막 선택한 모드 가져오기 (라우팅/초기 화면용)
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

  /// 로그아웃 시 역할 플래그 초기화
  static Future<void> clearRoleFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySubjectEnabled);
      await prefs.remove(_keyGuardianEnabled);
    } catch (e) {
      // 저장 실패 시 무시
    }
  }
}
