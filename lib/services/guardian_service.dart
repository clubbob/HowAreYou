import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// 보호 대상자 전화번호로 사용자를 찾지 못했을 때 (앱 미설치·미로그인)
class NoSubjectUserException implements Exception {
  final String message;
  NoSubjectUserException(this.message);
  @override
  String toString() => message;
}

/// 보호자가 담당하는 대상자(subject) 목록·이름 조회 및 보호 대상 추가.
/// PRD §9: subjects/{subjectUid} 문서 ID = 보호대상자 Firebase Auth UID (users/{uid}와 동일).
class GuardianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 보호 대상자에게 보호자가 지정되어 있는지 확인.
  /// [subjectId] = 보호대상자 Auth UID (subjects 문서 ID와 동일).
  Future<bool> hasGuardian(String subjectId) async {
    try {
      final subjectDoc = await _firestore
          .collection(AppConstants.subjectsCollection)
          .doc(subjectId)
          .get();
      
      if (!subjectDoc.exists) {
        return false;
      }
      
      final data = subjectDoc.data();
      final pairedGuardianUids = data?['pairedGuardianUids'];
      
      if (pairedGuardianUids is List) {
        return pairedGuardianUids.isNotEmpty;
      }
      
      return false;
    } catch (e) {
      debugPrint('보호자 확인 오류: $e');
      return false;
    }
  }

  static String _toE164Internal(String input) {
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

  /// 전화번호로 사용자 찾기 (여러 형식 시도 - Firestore/로그인 저장 형식과 맞추기 위함)
  Future<QuerySnapshot> _findUserByPhone(String rawInput) async {
    final digits = rawInput.replaceAll(RegExp(r'[^\d]'), '');
    final candidates = <String>{
      _toE164Internal(rawInput),
      digits,
      if (digits.startsWith('010')) '82${digits.substring(1)}',
      if (digits.startsWith('010')) '+82${digits.substring(1)}',
      if (digits.length >= 10) '+$digits',
    };
    for (final phone in candidates) {
      if (phone.isEmpty) continue;
      try {
        final q = await _firestore
            .collection(AppConstants.usersCollection)
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          debugPrint('GuardianService: 전화번호로 사용자 찾음 phone=$phone uid=${q.docs.first.id}');
          return q;
        }
      } catch (e) {
        debugPrint('GuardianService: users 쿼리 오류 phone=$phone → $e');
        rethrow;
      }
    }
    debugPrint('GuardianService: 전화번호로 사용자 없음 입력="$rawInput" 시도형식=$candidates');
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('phone', isEqualTo: '__never_match__')
        .limit(1)
        .get();
  }

  /// 전화번호로 사용자 문서 한 건 조회 (보호대상자/보호자 추가 시 공통). 없으면 null.
  Future<DocumentSnapshot?> getUserByPhone(String rawInput) async {
    final q = await _findUserByPhone(rawInput.trim());
    if (q.docs.isEmpty) return null;
    return q.docs.first;
  }

  /// E.164 등 전화번호 정규화 (GuardianScreen 등에서 공통 사용)
  static String toE164(String input) => _toE164Internal(input);

  /// 보호 대상(대상자) 전화번호로 나를 보호자로 등록 → 보호 대상 목록에 추가.
  /// [subjectPhone] 대상자 전화번호. users 쿼리로 찾은 uid = subjectUid 로 subjects 문서 사용 (PRD §9).
  /// 성공 시 추가된 보호대상자 uid(subjectUid) 반환.
  Future<String> addMeAsGuardianToSubject({
    required String subjectPhone,
    required String guardianUid,
    required String guardianPhone,
    String? guardianDisplayName,
  }) async {
    debugPrint('GuardianService: 보호대상자 등록 시도 subjectPhone=$subjectPhone guardianUid=$guardianUid');
    final usersQuery = await _findUserByPhone(subjectPhone.trim());
    if (usersQuery.docs.isEmpty) {
      throw NoSubjectUserException(
        '이 전화번호로 가입된 사용자가 없습니다.\n\n'
        '보호 대상자가 앱을 설치하고, 한 번이라도 로그인해야 등록할 수 있습니다.',
      );
    }
    final subjectDoc = usersQuery.docs.first;
    final subjectId = subjectDoc.id;
    final subjectData = subjectDoc.data() as Map<String, dynamic>? ?? {};
    debugPrint('GuardianService: 보호대상자 uid=$subjectId, subjects 문서 읽기 시도');

    // 본인 체크: 프로덕션 모드에서는 본인을 보호대상으로 추가할 수 없음
    // 개발 모드(kDebugMode)에서는 테스트를 위해 허용
    if (subjectId == guardianUid) {
      if (kDebugMode) {
        // 개발 모드: 허용 (테스트 편의)
        debugPrint('[개발 모드] 본인을 보호대상으로 추가합니다. (프로덕션에서는 차단됨)');
      } else {
        // 프로덕션 모드: 차단
        throw Exception('본인 전화번호는 추가할 수 없습니다. 보호할 분(대상자)의 전화번호를 입력해 주세요.');
      }
    }

    final docRef = _firestore
        .collection(AppConstants.subjectsCollection)
        .doc(subjectId);
    DocumentSnapshot docSnap;
    try {
      docSnap = await docRef.get();
    } catch (e) {
      debugPrint('GuardianService: subjects 문서 읽기 실패 → $e');
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('보호대상자 정보를 읽을 권한이 없습니다. Firebase Console에서 Firestore 규칙을 배포했는지 확인해 주세요. (firebase deploy --only firestore:rules)');
      }
      rethrow;
    }
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

    // pairedGuardianUids에 보호자 UID 추가 (명시적으로 배열 구성)
    paired.add(guardianUid);
    
    // 보호 대상자 정보 가져오기 (displayName, phone)
    final subjectDisplayName = subjectData['displayName'] is String
        ? (subjectData['displayName'] as String).trim()
        : '';
    final subjectPhoneNormalized = subjectData['phone'] is String
        ? (subjectData['phone'] as String).trim()
        : subjectPhone.trim();
    
    // 문서가 존재하면 update 사용, 없으면 set 사용
    // update() 사용 시에도 규칙이 작동하도록 항상 pairedGuardianUids와 guardianInfos만 업데이트
    try {
      if (docSnap.exists) {
        debugPrint('GuardianService: subjects 문서 업데이트 시도');
        await docRef.update({
          'pairedGuardianUids': paired,
          'guardianInfos': existingInfos,
        });
      } else {
        debugPrint('GuardianService: subjects 새 문서 생성 시도');
        final newData = <String, dynamic>{
          'pairedGuardianUids': paired,
          'guardianInfos': existingInfos,
        };
        if (subjectDisplayName.isNotEmpty) {
          newData['displayName'] = subjectDisplayName;
        }
        if (subjectPhoneNormalized.isNotEmpty) {
          newData['phone'] = subjectPhoneNormalized;
        }
        await docRef.set(newData);
      }
      debugPrint('GuardianService: 보호대상자 등록 완료 subjectId=$subjectId');
      return subjectId;
    } catch (e) {
      debugPrint('GuardianService: subjects 쓰기 실패 → $e');
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('보호대상자로 등록할 권한이 없습니다. Firestore 규칙을 배포해 주세요. (firebase deploy --only firestore:rules)');
      }
      rethrow;
    }
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
