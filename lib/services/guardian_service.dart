import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

/// 보호 대상자 전화번호로 사용자를 찾지 못했을 때 (앱 미설치·미로그인)
class NoSubjectUserException implements Exception {
  final String message;
  NoSubjectUserException(this.message);
  @override
  String toString() => message;
}

/// 보호자 전화번호로 사용자를 찾지 못했을 때
class NoGuardianUserException implements Exception {
  final String message;
  NoGuardianUserException(this.message);
  @override
  String toString() => message;
}

/// 대기 초대 생성됨 (가입 시 자동 연결)
class PendingInviteCreatedException implements Exception {
  final String message;
  PendingInviteCreatedException(this.message);
  @override
  String toString() => message;
}

/// 보호자가 담당하는 대상자(subject) 목록·이름 조회 및 보호 대상 추가.
/// PRD §9: subjects/{subjectUid} 문서 ID = 보호대상자 Firebase Auth UID (users/{uid}와 동일).
class GuardianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 보호자가 보호대상자와 연결된 날짜 (yyyy-MM-dd). 없으면 null (기존 데이터 호환).
  Future<String?> getGuardianPairedAt(String subjectId, String guardianUid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.subjectsCollection)
          .doc(subjectId)
          .get();
      if (!doc.exists) return null;
      final infos = doc.data()?['guardianInfos'];
      if (infos is! Map) return null;
      final info = infos[guardianUid];
      if (info is! Map) return null;
      final pairedAt = info['pairedAt'];
      return pairedAt is String ? pairedAt : null;
    } catch (e) {
      debugPrint('getGuardianPairedAt 오류: $e');
      return null;
    }
  }

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

  /// 보호자→대상자 대기 초대 생성 (대상자 미가입 시)
  Future<void> _createPendingGuardianInvite({
    required String subjectPhone,
    required String guardianUid,
    required String guardianPhone,
    String? guardianDisplayName,
  }) async {
    final normalized = _toE164Internal(subjectPhone);
    if (normalized.isEmpty) return;
    await _firestore.collection(AppConstants.pendingGuardianInvitesCollection).add({
      'subjectPhone': normalized,
      'guardianUid': guardianUid,
      'guardianPhone': guardianPhone,
      'guardianDisplayName': guardianDisplayName?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('GuardianService: 대기 초대 생성 subjectPhone=$normalized guardianUid=$guardianUid');
  }

  /// 대상자→보호자 대기 초대 생성 (보호자 미가입 시)
  Future<void> createPendingSubjectInvite({
    required String guardianPhone,
    required String subjectUid,
    required String subjectPhone,
    String? subjectDisplayName,
  }) async {
    final normalized = _toE164Internal(guardianPhone);
    if (normalized.isEmpty) return;
    await _firestore.collection(AppConstants.pendingSubjectInvitesCollection).add({
      'guardianPhone': normalized,
      'subjectUid': subjectUid,
      'subjectPhone': subjectPhone,
      'subjectDisplayName': subjectDisplayName?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('GuardianService: 대기 초대 생성 guardianPhone=$normalized subjectUid=$subjectUid');
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
      // 미가입 시 대기 등록 → 가입 시 자동 연결
      await _createPendingGuardianInvite(
        subjectPhone: subjectPhone.trim(),
        guardianUid: guardianUid,
        guardianPhone: guardianPhone,
        guardianDisplayName: guardianDisplayName,
      );
      throw PendingInviteCreatedException(
        '이 분이 아직 앱에 가입하지 않았습니다.\n'
        '가입하시면 자동으로 연결됩니다.',
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
        throw Exception('본인 핸드폰 번호는 추가할 수 없습니다. 보호할 분(대상자)의 핸드폰 번호를 입력해 주세요.');
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
        throw Exception('접근 권한이 없습니다. 잠시 후 다시 시도해 주세요.');
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
      'pairedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
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
        throw Exception('접근 권한이 없습니다. 잠시 후 다시 시도해 주세요.');
      }
      rethrow;
    }
  }

  /// 초대 링크로 들어온 보호자가 로그인 후 보호대상자와 연결 (보호자로 등록)
  /// 보호대상자가 링크를 보냈을 때, 링크를 연 보호자 측에서 호출.
  Future<void> acceptInviteAsGuardian({
    required String guardianUid,
    required String guardianPhone,
    String? guardianDisplayName,
    required String subjectId,
  }) async {
    if (guardianUid == subjectId) return;
    final docRef = _firestore.collection(AppConstants.subjectsCollection).doc(subjectId);
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
    if (paired.contains(guardianUid)) return;
    existingInfos[guardianUid] = {
      'phone': guardianPhone,
      'displayName': guardianDisplayName?.trim() ?? '',
      'pairedAt': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
    paired.add(guardianUid);
    if (docSnap.exists) {
      await docRef.update({'pairedGuardianUids': paired, 'guardianInfos': existingInfos});
    } else {
      await docRef.set({
        'pairedGuardianUids': paired,
        'guardianInfos': existingInfos,
      });
    }
  }

  /// 초대 링크로 들어온 사용자가 로그인 후 보호자와 연결 (보호대상자로 등록)
  Future<void> acceptInviteAsSubject({
    required String subjectUid,
    required String subjectPhone,
    String? subjectDisplayName,
    required String guardianUid,
  }) async {
    if (subjectUid == guardianUid) return;
    final guardianDoc = await _firestore.collection(AppConstants.usersCollection).doc(guardianUid).get();
    final guardianData = guardianDoc.data();
    final guardianPhone = (guardianData?['phone'] as String?)?.trim() ?? '';
    final guardianDisplayName = (guardianData?['displayName'] as String?)?.trim() ?? '';

    final docRef = _firestore.collection(AppConstants.subjectsCollection).doc(subjectUid);
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
    if (paired.contains(guardianUid)) return;
    existingInfos[guardianUid] = {
      'phone': guardianPhone,
      'displayName': guardianDisplayName,
    };
    paired.add(guardianUid);

    final newData = <String, dynamic>{
      'pairedGuardianUids': paired,
      'guardianInfos': existingInfos,
    };
    if (subjectDisplayName != null && subjectDisplayName.trim().isNotEmpty) {
      newData['displayName'] = subjectDisplayName.trim();
    }
    if (subjectPhone.isNotEmpty) {
      newData['phone'] = subjectPhone;
    }
    if (docSnap.exists) {
      await docRef.update({'pairedGuardianUids': paired, 'guardianInfos': existingInfos});
    } else {
      await docRef.set(newData);
    }
  }

  /// 보호자가 보호 대상을 목록에서 제거 (Cloud Function 호출 - Firestore permission-denied 우회)
  Future<void> removeSubjectFromGuardian({
    required String guardianUid,
    required String subjectId,
  }) async {
    if (guardianUid == subjectId) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('removeGuardianFromSubject');
      await callable.call({'subjectId': subjectId});
      debugPrint('GuardianService: 보호 대상 제거 완료 subjectId=$subjectId guardianUid=$guardianUid');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('GuardianService: 보호 대상 제거 실패 $e');
      final msg = switch (e.code) {
        'unauthenticated' => '로그인이 필요합니다.',
        'invalid-argument' => e.message ?? '잘못된 요청입니다.',
        'permission-denied' => '권한이 없습니다.',
        _ => e.message ?? '삭제에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      };
      throw Exception(msg);
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

  /// 보호자 표시 이름 (users 문서 displayName, 없으면 '보호자')
  Future<String> getGuardianDisplayName(String guardianUid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(guardianUid).get();
      if (doc.exists) {
        final name = doc.data()?['displayName'];
        if (name is String && name.trim().isNotEmpty) return name.trim();
      }
    } catch (_) {}
    return '보호자';
  }

  /// 대상자 전화번호 (users 문서 phone, 없으면 빈 문자열)
  Future<String> getSubjectPhone(String subjectId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(subjectId)
          .get();
      if (doc.exists) {
        final phone = doc.data()?['phone'];
        if (phone is String && phone.trim().isNotEmpty) {
          return _formatPhoneForDisplay(phone);
        }
      }
    } catch (_) {}
    return '';
  }

  static String _formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 10) {
      final d = digits.startsWith('82') ? digits.substring(2) : digits;
      if (d.length >= 10 && d.startsWith('10')) {
        return '010-${d.substring(2, 6)}-${d.substring(6)}';
      }
    }
    return phone;
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
