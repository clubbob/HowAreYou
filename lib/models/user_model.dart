enum UserRole {
  guardian,
  subject,
  both,
}

class UserModel {
  final String uid;
  final String phone;
  final UserRole role;
  final List<String> fcmTokens;
  final String? displayName;

  UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    this.fcmTokens = const [],
    this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final roleRaw = map['role'];
    final roleStr = roleRaw is String ? roleRaw : 'subject';
    final fcmRaw = map['fcmTokens'];
    final fcmList = fcmRaw is List
        ? List<String>.from(fcmRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty))
        : <String>[];
    return UserModel(
      uid: uid,
      phone: map['phone'] is String ? map['phone'] as String : '',
      role: _roleFromString(roleStr),
      fcmTokens: fcmList,
      displayName: map['displayName'] is String ? map['displayName'] as String? : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'role': _roleToString(role),
      'fcmTokens': fcmTokens,
      if (displayName != null) 'displayName': displayName,
    };
  }

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'guardian':
        return UserRole.guardian;
      case 'subject':
        return UserRole.subject;
      case 'both':
        return UserRole.both;
      default:
        return UserRole.subject;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.guardian:
        return 'guardian';
      case UserRole.subject:
        return 'subject';
      case UserRole.both:
        return 'both';
    }
  }
}
