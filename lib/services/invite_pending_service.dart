import 'package:shared_preferences/shared_preferences.dart';

/// 초대 링크로 들어온 보호대상자: pending inviterId 저장·조회
/// 초대 링크로 들어온 보호자: pending subjectId 저장·조회 (보호대상자가 보호자에게 링크 보낸 경우)
class InvitePendingService {
  static const String _keyPendingInviterId = 'pending_inviter_id';
  static const String _keyPendingSubjectId = 'pending_subject_id';

  static Future<void> setPendingInviterId(String? inviterId) async {
    final prefs = await SharedPreferences.getInstance();
    if (inviterId == null || inviterId.isEmpty) {
      await prefs.remove(_keyPendingInviterId);
    } else {
      await prefs.setString(_keyPendingInviterId, inviterId);
    }
  }

  static Future<String?> getPendingInviterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingInviterId);
  }

  static Future<void> clearPendingInviterId() async {
    await setPendingInviterId(null);
  }

  /// 보호대상자 → 보호자 초대 링크로 들어온 경우: 초대한 보호대상자(subject) UID
  static Future<void> setPendingSubjectId(String? subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    if (subjectId == null || subjectId.isEmpty) {
      await prefs.remove(_keyPendingSubjectId);
    } else {
      await prefs.setString(_keyPendingSubjectId, subjectId);
    }
  }

  static Future<String?> getPendingSubjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPendingSubjectId);
  }

  static Future<void> clearPendingSubjectId() async {
    await setPendingSubjectId(null);
  }
}
