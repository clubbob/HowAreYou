import 'package:share_plus/share_plus.dart';
import 'constants.dart';

/// 보호자↔보호대상자 초대 링크 생성·공유
class InviteLinkHelper {
  /// 보호자 → 보호대상자 초대 링크 (g = 보호자 UID)
  static String buildInviteUrl(String guardianUid) {
    final uri = Uri.parse(AppConstants.inviteBaseUrl).replace(
      queryParameters: {'g': guardianUid},
    );
    return uri.toString();
  }

  /// 보호대상자 → 보호자 초대 링크 (s = 보호대상자 UID). 앱 설치 여부와 관계없이 보호자 연계용.
  static String buildGuardianInviteUrl(String subjectUid) {
    final uri = Uri.parse(AppConstants.inviteBaseUrl).replace(
      queryParameters: {'s': subjectUid},
    );
    return uri.toString();
  }

  /// 카톡/문자로 보낼 때 쓸 문장 (보호자가 보호대상자에게)
  static const String suggestedMessage =
      '하루 한 번 컨디션만 기록하는 앱이에요.';

  /// 보호대상자가 보호자에게 보낼 때 쓸 문장
  static const String suggestedMessageForGuardian =
      '하루 한 번 컨디션만 기록하는 앱이에요. 링크 누르고 앱 깔면 내 기록을 확인할 수 있어요 (이미 깔았어도 됨).';

  /// 링크 + 문장을 한 번에 공유 (보호자 → 보호대상자)
  static Future<void> shareInvite(String guardianUid) async {
    final url = buildInviteUrl(guardianUid);
    await Share.share(
      '$suggestedMessage\n\n$url',
      subject: '지금 어때? 앱 초대',
    );
  }

  /// 링크 + 문장을 한 번에 공유 (보호대상자 → 보호자). 앱 설치/미설치 모두 연계됨.
  static Future<void> shareGuardianInvite(String subjectUid) async {
    final url = buildGuardianInviteUrl(subjectUid);
    // Android 시스템 공유 다이얼로그 제목은 제어할 수 없지만, 
    // subject는 일부 앱(이메일, 메시지 등)에서 제목으로 사용됩니다.
    await Share.share(
      '$suggestedMessageForGuardian\n\n$url',
      subject: '지금 어때? 보호자 연결',
    );
  }
}
