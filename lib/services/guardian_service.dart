import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// 보호자가 담당하는 대상자(subject) 목록·이름 조회 및 보호 대상 추가
class GuardianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return input.trim();
    if (digits.startsWith('82') && digits.length >= 11) return '+$digits';
    if (digits.length >= 9 && digits.startsWith('010')) {
      return '+82${digits.substring(1)}';
    }
    if (digits.length >= 10 && digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    if (!input.trim().startsWith('+')) return '+82$digits';
    return input.trim();
  }

  /// 전화번호로 사용자 찾기 (여러 형식 시도)
  Future<QuerySnapshot> _findUserByPhone(String rawInput) async {
    final digits = rawInput.replaceAll(RegExp(r'[^\d]'), '');
    final candidates = <String>{
      _toE164(rawInput),
      digits,
      if (digits.startsWith('010')) '82${digits.substring(1)}',
    };
    for (final phone in candidates) {
      if (phone.isEmpty) continue;
      final q = await _firestore
          .collection(AppConstants.usersCollection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return q;
    }
    // 빈 결과를 반환하기 위해 limit(1)로 쿼리하되, 결과는 비어있을 것
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('phone', isEqualTo: '__never_match__')
        .limit(1)
        .get();
  }

  /// 보호 대상(대상자) 전화번호로 나를 보호자로 등록 → 보호 대상 목록에 추가
  /// [subjectPhone] 대상자 전화번호, [guardianUid/Phone/DisplayName] 현재 보호자 정보
  /// 성공 시 추가된 대상자 ID(subjectId) 반환
  Future<String> addMeAsGuardianToSubject({
    required String subjectPhone,
    required String guardianUid,
    required String guardianPhone,
    String? guardianDisplayName,
  }) async {
    final usersQuery = await _findUserByPhone(subjectPhone.trim());
    if (usersQuery.docs.isEmpty) {
      throw Exception('이 전화번호로 가입된 사용자가 없습니다. 보호할 분이 앱에 가입했는지 확인해 주세요.');
    }
    final subjectDoc = usersQuery.docs.first;
    final subjectId = subjectDoc.id;
    if (subjectId == guardianUid) {
      throw Exception('본인 전화번호는 추가할 수 없습니다. 보호할 분(대상자)의 전화번호를 입력해 주세요.');
    }

    final docRef = _firestore
        .collection(AppConstants.subjectsCollection)
        .doc(subjectId);
    final docSnap = await docRef.get();
    final existingData = docSnap.data() as Map<String, dynamic>?;
    final existingInfosRaw = existingData?['guardianInfos'];
    final existingInfos = existingInfosRaw is Map
        ? Map<String, dynamic>.from(
            (existingInfosRaw as Map).map((k, v) => MapEntry(
                  k.toString(),
                  v is Map ? Map<String, dynamic>.from(v) : v,
                )))
        : <String, dynamic>{};
    final paired = List<String>.from(existingData?['pairedGuardianUids'] ?? []);
    if (paired.contains(guardianUid)) {
      throw Exception('이미 보호 대상으로 등록된 분입니다.');
    }
    existingInfos[guardianUid] = {
      'phone': guardianPhone,
      'displayName': guardianDisplayName?.trim() ?? '',
    };

    await docRef.set({
      'pairedGuardianUids': FieldValue.arrayUnion([guardianUid]),
      'guardianInfos': existingInfos,
    }, SetOptions(merge: true));
    return subjectId;
  }

  /// 이 보호자 UID가 등록된 대상자(subject) ID 목록
  Future<List<String>> getSubjectIdsForGuardian(String guardianUid) async {
    final snapshot = await _firestore
        .collection(AppConstants.subjectsCollection)
        .where('pairedGuardianUids', arrayContains: guardianUid)
        .get();

    return snapshot.docs.map((d) => d.id).toList();
  }

  /// 대상자 표시 이름 (users 문서 displayName, 없으면 '이름 없음')
  Future<String> getSubjectDisplayName(String subjectId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(subjectId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final name = data?['displayName'];
        if (name is String && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
    } catch (_) {}
    return '이름 없음';
  }

  /// 보호자가 지정한 대상자 별칭이 있으면 그대로, 없으면 getSubjectDisplayName
  Future<String> getSubjectDisplayNameForGuardian(
    String subjectId,
    String guardianUid,
  ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(guardianUid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final labels = data?['subjectLabels'];
        if (labels is Map) {
          final v = labels[subjectId];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
    } catch (_) {}
    return getSubjectDisplayName(subjectId);
  }

  /// 보호자가 대상자에게 붙인 이름(별칭) 저장
  Future<void> setSubjectDisplayNameByGuardian({
    required String guardianUid,
    required String subjectId,
    required String displayName,
  }) async {
    final docRef = _firestore
        .collection(AppConstants.usersCollection)
        .doc(guardianUid);
    
    // 문서가 존재하는지 확인
    final docSnap = await docRef.get();
    
    if (docSnap.exists) {
      // 문서가 있으면 update 사용
      await docRef.update({
        'subjectLabels.$subjectId': displayName.trim(),
      });
    } else {
      // 문서가 없으면 set으로 생성 (merge: true 사용)
      await docRef.set({
        'subjectLabels': {
          subjectId: displayName.trim(),
        },
      }, SetOptions(merge: true));
    }
  }
}
