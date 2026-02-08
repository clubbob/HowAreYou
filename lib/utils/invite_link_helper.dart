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
      '요즘 연락 안 되면 내가 괜히 마음 쓰여서 그래. 이거 깔고 하루 한 번만 눌러주면 돼.';

  /// 보호대상자가 보호자에게 보낼 때 쓸 문장
  static const String suggestedMessageForGuardian =
      '내가 요즘 상태 알려주는 앱 쓸게. 이 링크 누르고 앱 깔면(이미 깔았어도 됨) 나한테 연결돼.';

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
    await Share.share(
      '$suggestedMessageForGuardian\n\n$url',
      subject: '지금 어때? 보호자 연결',
    );
  }
}
