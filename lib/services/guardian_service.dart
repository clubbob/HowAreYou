import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/constants.dart';
import 'subscription_service.dart';

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

  /// 보호자 구독 상태. 프리미엄이면 isRestricted: false (보호대상자 무제한)
  Future<SubscriptionState> getSubscriptionState(String guardianUid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(guardianUid).get();
      final data = doc.data();
      final status = data?['subscriptionStatus'] is String ? data!['subscriptionStatus'] as String : '';
      DateTime? expiry;
      final exp = data?['subscriptionExpiry'];
      if (exp != null) {
        if (exp is Timestamp) expiry = exp.toDate();
        else if (exp is DateTime) expiry = exp;
      }
      return SubscriptionState.evaluate(
        subscriptionStatus: status,
        subscriptionExpiry: expiry,
      );
    } catch (e) {
      debugPrint('getSubscriptionState 오류: $e');
      return SubscriptionState.evaluate(subscriptionStatus: '');
    }
  }

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

  static Timestamp _epochTimestamp() => Timestamp.fromDate(DateTime(1970, 1, 1));

  /// 보호 대상(대상자) 전화번호로 나를 보호자로 등록 → Callable Function 호출 (서버 레벨 제한 적용)
  Future<String> addMeAsGuardianToSubject({
    required String subjectPhone,
    required String guardianUid,
    required String guardianPhone,
    String? guardianDisplayName,
  }) async {
    debugPrint('GuardianService: 보호대상자 등록 시도 subjectPhone=$subjectPhone guardianUid=$guardianUid');
    final usersQuery = await _findUserByPhone(subjectPhone.trim());
    if (usersQuery.docs.isEmpty) {
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
    final subjectId = usersQuery.docs.first.id;
    if (subjectId == guardianUid && !kDebugMode) {
      throw Exception('본인 핸드폰 번호는 추가할 수 없습니다. 보호할 분(대상자)의 핸드폰 번호를 입력해 주세요.');
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addGuardianToSubject');
      final result = await callable.call({
        'subjectPhone': subjectPhone.trim(),
        'guardianPhone': guardianPhone,
        'guardianDisplayName': guardianDisplayName?.trim() ?? '',
      });
      final data = result.data as Map;
      final id = data['subjectId'] as String?;
      debugPrint('GuardianService: 보호대상자 등록 완료 subjectId=$id');
      return id ?? subjectId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('GuardianService: addGuardianToSubject 실패 $e');
      final msg = switch (e.code) {
        'unauthenticated' => '로그인이 필요합니다.',
        'invalid-argument' => e.message ?? '잘못된 요청입니다.',
        'permission-denied' => '권한이 없습니다.',
        'resource-exhausted' => e.message ?? '무료 플랜에서는 보호대상자 2명까지 등록할 수 있습니다.',
        'failed-precondition' => e.message ?? '이 분이 아직 앱에 가입하지 않았습니다.',
        _ => e.message ?? '등록에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      };
      throw Exception(msg);
    }
  }

  /// 초대 링크로 들어온 보호자가 로그인 후 보호대상자와 연결 (보호자로 등록)
  /// Callable addGuardianToSubject 호출 (서버 레벨 제한 적용)
  Future<void> acceptInviteAsGuardian({
    required String guardianUid,
    required String guardianPhone,
    String? guardianDisplayName,
    required String subjectId,
  }) async {
    if (guardianUid == subjectId) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addGuardianToSubject');
      await callable.call({
        'subjectId': subjectId,
        'guardianPhone': guardianPhone,
        'guardianDisplayName': guardianDisplayName?.trim() ?? '',
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception(e.message ?? '무료 플랜에서는 보호대상자 2명까지 등록할 수 있습니다.');
      }
      rethrow;
    }
  }

  /// 초대 링크로 들어온 사용자가 로그인 후 보호자와 연결 (보호대상자로 등록)
  /// 보호대상자가 전화번호로 찾은 보호자를 추가 (Callable addGuardianToSubjectBySubjectInvite)
  /// - subject = caller, guardianUid = 추가할 보호자 (프리미엄 체크 적용)
  Future<void> addGuardianBySubjectInvite({
    required String guardianUid,
    String? subjectPhone,
    String? subjectDisplayName,
    String? guardianDisplayName,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addGuardianToSubjectBySubjectInvite');
      await callable.call({
        'guardianUid': guardianUid,
        if (subjectPhone != null && subjectPhone.isNotEmpty) 'subjectPhone': subjectPhone.trim(),
        if (subjectDisplayName != null && subjectDisplayName.isNotEmpty) 'subjectDisplayName': subjectDisplayName.trim(),
        if (guardianDisplayName != null && guardianDisplayName.isNotEmpty) 'guardianDisplayName': guardianDisplayName.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception(e.message ?? '무료 플랜에서는 보호대상자 2명까지 등록할 수 있습니다.');
      }
      rethrow;
    }
  }

  /// 보호대상자가 초대 링크로 보호자 추가 (Callable addGuardianToSubjectBySubjectInvite 호출)
  Future<void> acceptInviteAsSubject({
    required String subjectUid,
    required String subjectPhone,
    String? subjectDisplayName,
    required String guardianUid,
  }) async {
    if (subjectUid == guardianUid) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('addGuardianToSubjectBySubjectInvite');
      await callable.call({
        'guardianUid': guardianUid,
        'subjectPhone': subjectPhone.trim(),
        'subjectDisplayName': subjectDisplayName?.trim() ?? '',
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception(e.message ?? '무료 플랜에서는 보호대상자 2명까지 등록할 수 있습니다.');
      }
      rethrow;
    }
  }

  /// 보호대상자가 보호자를 자신의 목록에서 제거 (Callable removeGuardianFromSubjectBySubject)
  /// Callable 미배포·네트워크 오류 시 Firestore 규칙 허용 범위에서 직접 pairedGuardianUids 제거(폴백).
  Future<void> removeGuardianBySubject({
    required String subjectUid,
    required String guardianUid,
  }) async {
    if (subjectUid == guardianUid) return;
    final g = guardianUid.trim();
    if (g.isEmpty) return;

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('removeGuardianFromSubjectBySubject');
      await callable.call({'guardianUid': g});
      return;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('GuardianService: removeGuardianBySubject Callable 실패 → Firestore 폴백: $e');
      if (e.code == 'unauthenticated') {
        throw Exception('로그인이 필요합니다.');
      }
      if (e.code == 'invalid-argument' || e.code == 'failed-precondition') {
        final m = e.message ?? '';
        if (m.isNotEmpty) throw Exception(m);
      }
      // not-found(함수 미배포)·deadline·unavailable 등 → 폴백
    } catch (e) {
      debugPrint('GuardianService: removeGuardianBySubject Callable 오류 → Firestore 폴백: $e');
    }

    await _removeGuardianPairingFirestore(subjectUid, g);
  }

  /// subjects 문서에서 보호자 연결만 제거 (보호대상자 본인 규칙: pairedGuardianUids 크기 감소 허용)
  Future<void> _removeGuardianPairingFirestore(String subjectUid, String guardianUid) async {
    final subjectRef =
        FirebaseFirestore.instance.collection(AppConstants.subjectsCollection).doc(subjectUid);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(subjectRef);
        if (!snap.exists) {
          throw Exception('보호 대상 정보를 찾을 수 없습니다.');
        }
        final data = snap.data()!;
        final raw = data['pairedGuardianUids'];
        final paired = <String>[
          if (raw is List) ...raw.map((e) => e.toString().trim()),
        ];
        if (!paired.contains(guardianUid)) {
          throw Exception('이미 삭제되었거나 목록에 없는 보호자입니다.');
        }
        final newPaired = paired.where((id) => id != guardianUid).toList();
        final infos = Map<String, dynamic>.from(
          (data['guardianInfos'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {},
        );
        infos.remove(guardianUid);
        tx.update(subjectRef, {
          'pairedGuardianUids': newPaired,
          'guardianInfos': infos,
        });
      });
    } on FirebaseException catch (e) {
      debugPrint('GuardianService: Firestore 폴백 실패 $e');
      if (e.code == 'permission-denied') {
        throw Exception('삭제 권한이 없습니다. 앱을 최신으로 업데이트한 뒤 다시 시도해 주세요.');
      }
      throw Exception('삭제에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.');
    }
  }

  /// 보호자가 보호 대상을 목록에서 제거 (Callable removeGuardianFromSubject)
  /// Callable 실패 시 규칙상 보호자 본인이 subjects에서 자신만 제거 가능 → Firestore 폴백
  Future<void> removeSubjectFromGuardian({
    required String guardianUid,
    required String subjectId,
  }) async {
    if (guardianUid == subjectId) return;
    final sid = subjectId.trim();
    final gid = guardianUid.trim();
    if (sid.isEmpty || gid.isEmpty) return;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('removeGuardianFromSubject');
      await callable.call({'subjectId': sid});
      debugPrint('GuardianService: 보호 대상 제거 완료 subjectId=$sid guardianUid=$gid');
      return;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('GuardianService: removeSubjectFromGuardian Callable 실패 → Firestore 폴백: $e');
      if (e.code == 'unauthenticated') {
        throw Exception('로그인이 필요합니다.');
      }
      if (e.code == 'invalid-argument' || e.code == 'failed-precondition') {
        final m = e.message ?? '';
        if (m.isNotEmpty) throw Exception(m);
      }
    } catch (e) {
      debugPrint('GuardianService: removeSubjectFromGuardian Callable 오류 → Firestore 폴백: $e');
    }

    await _removeGuardianSelfFromSubjectFirestore(gid, sid);
  }

  /// 보호자가 subjects/{subjectId}에서 본인 UID만 제거 (canRemoveSelfAsGuardian 규칙)
  Future<void> _removeGuardianSelfFromSubjectFirestore(
    String guardianUid,
    String subjectId,
  ) async {
    final subjectRef = _firestore.collection(AppConstants.subjectsCollection).doc(subjectId);
    final userRef = _firestore.collection(AppConstants.usersCollection).doc(guardianUid);
    try {
      await _firestore.runTransaction((tx) async {
        // Firestore: 트랜잭션 안에서는 모든 read를 먼저 한 뒤에만 write 가능
        final snap = await tx.get(subjectRef);
        final userSnap = await tx.get(userRef);

        if (!snap.exists) {
          throw Exception('보호 대상 정보를 찾을 수 없습니다.');
        }
        final data = snap.data()!;
        final raw = data['pairedGuardianUids'];
        final paired = <String>[
          if (raw is List) ...raw.map((e) => e.toString().trim()),
        ];
        if (!paired.contains(guardianUid)) {
          throw Exception('이미 삭제되었거나 목록에 없는 보호 대상입니다.');
        }
        final newPaired = paired.where((id) => id != guardianUid).toList();
        final infos = Map<String, dynamic>.from(
          (data['guardianInfos'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {},
        );
        infos.remove(guardianUid);

        tx.update(subjectRef, {
          'pairedGuardianUids': newPaired,
          'guardianInfos': infos,
        });

        if (userSnap.exists) {
          final count = (userSnap.data()?['guardianSubjectCount'] as num?)?.toInt() ?? 0;
          if (count > 0) {
            tx.update(userRef, {
              'guardianSubjectCount': FieldValue.increment(-1),
            });
          }
        }
      });
      debugPrint('GuardianService: Firestore 폴백으로 보호 대상 제거 완료 subjectId=$subjectId');
    } on FirebaseException catch (e) {
      debugPrint('GuardianService: 보호 대상 Firestore 폴백 실패 $e');
      if (e.code == 'permission-denied') {
        throw Exception('삭제 권한이 없습니다. 앱을 최신으로 업데이트한 뒤 다시 시도해 주세요.');
      }
      throw Exception('삭제에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.');
    }
  }

  /// 보호대상자가 보호자를 아직 유지하는지 (subjects/{subjectId}.pairedGuardianUids에 guardianUid 포함)
  Future<bool> isGuardianStillPairedBySubject(String subjectId, String guardianUid) async {
    try {
      final doc = await _firestore.collection(AppConstants.subjectsCollection).doc(subjectId).get();
      if (!doc.exists) return false;
      final paired = List<String>.from(doc.data()?['pairedGuardianUids'] ?? []);
      return paired.contains(guardianUid);
    } catch (_) {
      return false;
    }
  }

  /// 보호자가 보호대상자를 아직 목록에 가지고 있는지
  Future<bool> isGuardianStillHasSubject(String guardianUid, String subjectId) async {
    final ids = await getSubjectIdsForGuardian(guardianUid);
    return ids.contains(subjectId);
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
