import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// 앱 전체에서 KST(Asia/Seoul) 기준 날짜/시각을 통일하기 위한 유틸.
/// guardianCheckedDate, 알림 스케줄 등 날짜 경계(23:59~00:01)에서 꼬이지 않도록 사용.

/// KST 기준 오늘 날짜 문자열 (yyyy-MM-dd)
String todayKoreaStr() {
  try {
    final k = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
    return DateFormat('yyyy-MM-dd').format(DateTime(k.year, k.month, k.day));
  } catch (_) {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}

/// KST 기준 현재 시각 (DateTime)
DateTime nowKorea() {
  try {
    final k = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
    return DateTime(k.year, k.month, k.day, k.hour, k.minute, k.second);
  } catch (_) {
    return DateTime.now();
  }
}
