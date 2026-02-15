import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'fcm_service.dart';
import 'notification_service.dart';
import '../utils/permission_helper.dart';

/// 최초 가입 시 약관 동의가 필요할 때 던지는 예외
class NeedAgreementException implements Exception {
  final User user;
  NeedAgreementException(this.user);
}

/// 전화번호 인증 로그인. 한 번 로그인하면 앱을 닫았다 켜도 유지되며, 로그아웃 버튼을 누르기 전까지 유지됨.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Completer<void> _authReadyCompleter = Completer<void>();

  User? _user;
  UserModel? _userModel;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isAuthenticated => _user != null;

  /// 앱 시작 시 저장된 로그인 상태가 복원될 때까지 기다릴 때 사용
  /// Firebase Auth는 한 번 로그인하면 기기에서 자동으로 유지됨(명시적 로그아웃 전까지).
  Future<void> get authReady => _authReadyCompleter.future;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (!_authReadyCompleter.isCompleted) _authReadyCompleter.complete();
      final wasAuthenticated = _user != null;
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
        // 로그인 시 일일 알림 스케줄링
        NotificationService.instance.checkAndScheduleIfNeeded(user.uid).catchError((e) {
          debugPrint('알림 스케줄링 오류 (무시): $e');
        });
      } else {
        _userModel = null;
        notifyListeners();
        // 로그아웃 시 알림 취소
        if (wasAuthenticated) {
          NotificationService.instance.cancelAllNotifications().catchError((e) {
            debugPrint('알림 취소 오류 (무시): $e');
          });
        }
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data is Map<String, dynamic>) {
          _userModel = UserModel.fromMap(data, uid);
        }
      }
      notifyListeners();
      // FCM은 화면 블로킹 없이 백그라운드에서 초기화
      FCMService.instance.initialize(uid).catchError((e) {
        debugPrint('FCM 초기화 지연/실패 (무시): $e');
      });
    } catch (e, stack) {
      debugPrint('사용자 데이터 로드 오류: $e');
      debugPrint('스택: $stack');
      notifyListeners();
    }
  }

  Future<String?> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('인증 실패: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // verificationId는 반환하지 않고 저장만 함
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// OTP 인증 성공 후 공통 처리. 신규 사용자(users 문서 없음)는 약관 동의 필요 시 [NeedAgreementException] 던짐.
  Future<void> _processAfterSignIn(
    User user, {
    DateTime? termsAgreedAt,
    DateTime? privacyAgreedAt,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      if (termsAgreedAt == null || privacyAgreedAt == null) {
        throw NeedAgreementException(user);
      }
    }

    final phoneNumber = user.phoneNumber ?? '';
    debugPrint('verifyOTP: 사용자 문서 확보 시도');
    await _ensureUserDocument(
      user.uid,
      phoneNumber,
      termsAgreedAt: termsAgreedAt,
      privacyAgreedAt: privacyAgreedAt,
    );
    debugPrint('verifyOTP: 사용자 문서 확보 완료');
    await _ensureSubjectDocument(user.uid);
    debugPrint('verifyOTP: 보호대상자 문서 확보 완료');
    await _saveLastLoginPhone(phoneNumber);
    await addAgreedPhone(phoneNumber);
    FCMService.instance.initialize(user.uid).catchError((e) {
      debugPrint('FCM 초기화 지연/실패 (무시): $e');
    });
    _checkTodayNotificationAfterLogin(user.uid);
  }

  /// 자동 인증(verificationCompleted) 시 credential로 직접 로그인. 신규 사용자는 [NeedAgreementException] 던짐.
  Future<String?> verifyWithCredential(
    PhoneAuthCredential credential, {
    DateTime? termsAgreedAt,
    DateTime? privacyAgreedAt,
  }) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return '인증에 실패했습니다.';
    try {
      await _processAfterSignIn(
        user,
        termsAgreedAt: termsAgreedAt,
        privacyAgreedAt: privacyAgreedAt,
      );
      return null;
    } on NeedAgreementException {
      rethrow;
    }
  }

  /// 최초 가입 시 약관 동의 후 호출. users/subjects 문서 생성 후 로그인 완료.
  Future<String?> completeNewUserSignUp(
    User user, {
    required DateTime termsAgreedAt,
    required DateTime privacyAgreedAt,
  }) async {
    try {
      await _processAfterSignIn(
        user,
        termsAgreedAt: termsAgreedAt,
        privacyAgreedAt: privacyAgreedAt,
      );
      await _loadUserData(user.uid);
      return null;
    } catch (e) {
      debugPrint('completeNewUserSignUp 오류: $e');
      return '처리 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  Future<String?> verifyOTP(
    String verificationId,
    String smsCode, {
    DateTime? termsAgreedAt,
    DateTime? privacyAgreedAt,
  }) async {
    try {
      debugPrint('verifyOTP: signIn 시도');
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      debugPrint('verifyOTP: signIn 완료 uid=${user?.uid}');

      if (user != null) {
        await _processAfterSignIn(
          user,
          termsAgreedAt: termsAgreedAt,
          privacyAgreedAt: privacyAgreedAt,
        );
      }
      debugPrint('verifyOTP: 완료');
      return null;
    } on NeedAgreementException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyOTP: FirebaseAuthException - 코드: ${e.code}, 메시지: ${e.message}');
      // Firebase Auth 에러 코드를 한글 메시지로 변환
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = '인증번호가 일치하지 않아요.\n다시 한 번 확인해 주세요.';
          break;
        case 'invalid-verification-id':
          errorMessage = '인증 세션이 만료되었습니다. 핸드폰 번호를 다시 입력해주세요.';
          break;
        case 'session-expired':
          errorMessage = '인증 세션이 만료되었습니다. 핸드폰 번호를 다시 입력해주세요.';
          break;
        case 'too-many-requests':
          errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
          break;
        case 'network-request-failed':
          errorMessage = '네트워크 연결을 확인해주세요.';
          break;
        default:
          errorMessage = '인증에 실패했습니다. 잠시 후 다시 시도해주세요.';
      }
      return errorMessage;
    } catch (e) {
      debugPrint('verifyOTP: 오류 $e');
      return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }
  
  /// 마지막 로그인 전화번호 저장
  Future<void> _saveLastLoginPhone(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_login_phone', phoneNumber);
    } catch (e) {
      debugPrint('마지막 로그인 번호 저장 실패: $e');
    }
  }
  
  /// 마지막 로그인 전화번호 가져오기
  Future<String?> getLastLoginPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_login_phone');
    } catch (e) {
      debugPrint('마지막 로그인 번호 읽기 실패: $e');
      return null;
    }
  }

  static const String _agreedPhonesKey = 'agreed_phones';

  /// 회원 탈퇴 시 해당 전화번호를 약관 동의 목록에서 제거 (재가입 시 약관 다시 동의)
  Future<void> _removeAgreedPhone(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalized = _toE164(phoneNumber);
      if (normalized.isEmpty) return;
      final list = prefs.getStringList(_agreedPhonesKey) ?? [];
      if (list.contains(normalized)) {
        list.remove(normalized);
        await prefs.setStringList(_agreedPhonesKey, list);
      }
    } catch (e) {
      debugPrint('약관 동의 전화번호 제거 실패: $e');
    }
  }

  /// 로그인 성공 시 해당 전화번호를 약관 동의 완료 목록에 추가
  Future<void> addAgreedPhone(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalized = _toE164(phoneNumber);
      if (normalized.isEmpty) return;
      final list = prefs.getStringList(_agreedPhonesKey) ?? [];
      if (!list.contains(normalized)) {
        list.add(normalized);
        await prefs.setStringList(_agreedPhonesKey, list);
      }
    } catch (e) {
      debugPrint('약관 동의 전화번호 저장 실패: $e');
    }
  }

  /// 해당 전화번호가 이전에 약관 동의한 번호인지 확인
  Future<bool> isPhoneAgreed(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_agreedPhonesKey) ?? [];
      final normalized = _toE164(phoneNumber);
      return normalized.isNotEmpty && list.contains(normalized);
    } catch (e) {
      return false;
    }
  }

  /// Firestore/지정자 조회와 맞추기 위해 E.164로 통일 (+821012345678)
  static String _toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return input.trim();
    if (digits.startsWith('82') && digits.length >= 11) {
      return '+$digits';
    }
    if (digits.length >= 9 && digits.startsWith('010')) {
      return '+82${digits.substring(1)}';
    }
    if (digits.length >= 10 && digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    if (!input.trim().startsWith('+')) {
      return '+82$digits';
    }
    return input.trim();
  }

  /// PRD §9: users 문서 ID = Auth UID. 생성/갱신만 담당.
  Future<void> _ensureUserDocument(
    String uid,
    String phone, {
    DateTime? termsAgreedAt,
    DateTime? privacyAgreedAt,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    final normalizedPhone = _toE164(phone);

    if (!doc.exists) {
      final data = <String, dynamic>{
        'phone': normalizedPhone,
        'role': 'subject',
        'fcmTokens': [],
      };
      if (termsAgreedAt != null) {
        data['termsAgreedAt'] = Timestamp.fromDate(termsAgreedAt);
      }
      if (privacyAgreedAt != null) {
        data['privacyAgreedAt'] = Timestamp.fromDate(privacyAgreedAt);
      }
      await userRef.set(data);
    } else {
      // 이미 있는 사용자도 전화번호를 E.164로 갱신 (지정자 조회 일치용)
      final updateData = <String, dynamic>{'phone': normalizedPhone};
      if (termsAgreedAt != null) {
        updateData['termsAgreedAt'] = Timestamp.fromDate(termsAgreedAt);
      }
      if (privacyAgreedAt != null) {
        updateData['privacyAgreedAt'] = Timestamp.fromDate(privacyAgreedAt);
      }
      await userRef.set(updateData, SetOptions(merge: true));
    }
  }

  /// subjects 문서 초기화 및 리마인드 필드 설정
  /// 신규 사용자: nextReminderAt을 오늘/내일 19:00으로 설정
  /// 기존 사용자: 필드가 없으면 초기화
  Future<void> _ensureSubjectDocument(String uid) async {
    try {
      final subjectRef = _firestore.collection('subjects').doc(uid);
      final doc = await subjectRef.get();
      
      // 현재 시간 (Asia/Seoul 기준)
      final now = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'));
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // 19:00 이전이면 오늘 19:00, 이후면 내일 19:00
      final reminderTime = now.hour < 19
          ? tz.TZDateTime(tz.getLocation('Asia/Seoul'), now.year, now.month, now.day, 19, 0)
          : tz.TZDateTime(tz.getLocation('Asia/Seoul'), now.year, now.month, now.day + 1, 19, 0);
      
      if (!doc.exists) {
        // 신규 사용자: subjects 문서 생성 및 리마인드 필드 초기화
        await subjectRef.set({
          'nextReminderAt': Timestamp.fromDate(reminderTime),
          'reminderSentForDate': null,
          'lastResponseAt': null,
          'lastResponseDate': null,
        }, SetOptions(merge: true));
        debugPrint('_ensureSubjectDocument: 신규 사용자 subjects 문서 생성 완료');
      } else {
        // 기존 사용자: 필드가 없으면 초기화
        final data = doc.data();
        final needsUpdate = <String, dynamic>{};
        
        if (data == null || !data.containsKey('nextReminderAt')) {
          needsUpdate['nextReminderAt'] = Timestamp.fromDate(reminderTime);
        }
        if (data == null || !data.containsKey('reminderSentForDate')) {
          needsUpdate['reminderSentForDate'] = null;
        }
        if (data == null || !data.containsKey('lastResponseAt')) {
          needsUpdate['lastResponseAt'] = null;
        }
        if (data == null || !data.containsKey('lastResponseDate')) {
          needsUpdate['lastResponseDate'] = null;
        }
        
        if (needsUpdate.isNotEmpty) {
          await subjectRef.update(needsUpdate);
          debugPrint('_ensureSubjectDocument: 기존 사용자 필드 초기화 완료');
        }
      }
    } catch (e) {
      debugPrint('_ensureSubjectDocument 오류: $e');
      // 오류가 발생해도 로그인 플로우는 계속 진행
    }
  }

  /// 로그인 완료 후 오늘 알림 체크 (백그라운드)
  void _checkTodayNotificationAfterLogin(String userId) {
    // 비동기로 실행하여 로그인 플로우를 방해하지 않음
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // 알림 권한이 허용되어 있는지 확인
        if (Platform.isAndroid) {
          final isGranted = await PermissionHelper.isNotificationPermissionGranted();
          if (!isGranted) return; // 권한이 없으면 알림 표시하지 않음
        }
        
        // 오늘 알림 체크 및 스케줄링
        await NotificationService.instance.checkAndScheduleIfNeeded(userId);
      } catch (e) {
        debugPrint('[AuthService] 로그인 후 오늘 알림 체크 오류: $e');
      }
    });
  }

  /// 회원 탈퇴 시 재인증용 OTP 전송. [verificationId]를 반환 (실패 시 null)
  Future<String?> sendReauthOTP() async {
    final user = _user;
    if (user == null) return null;
    final phoneNumber = user.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) return null;

    final completer = Completer<String?>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {
        // 재인증은 수동 입력 플로우 사용 (자동 인증 시 codeSent 대기)
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      timeout: const Duration(seconds: 60),
    );
    try {
      return await completer.future.timeout(
        const Duration(seconds: 65),
        onTimeout: () => throw TimeoutException('인증번호 전송 시간이 초과되었습니다.'),
      );
    } catch (e) {
      debugPrint('sendReauthOTP 오류: $e');
      return null;
    }
  }

  /// 재인증 후 계정 삭제 (회원 탈퇴)
  Future<String?> reauthenticateAndDeleteAccount(String verificationId, String smsCode) async {
    final user = _user;
    if (user == null) return '로그인이 필요합니다.';

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await user.reauthenticateWithCredential(credential);
      return await _deleteAccountCore();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return '인증번호가 일치하지 않아요. 다시 확인해 주세요.';
      }
      if (e.code == 'invalid-verification-id' || e.code == 'session-expired') {
        return '인증 세션이 만료되었습니다. 다시 시도해 주세요.';
      }
      return e.message ?? '회원 탈퇴에 실패했습니다.';
    } catch (e, stack) {
      debugPrint('reauthenticateAndDeleteAccount 오류: $e');
      debugPrint('$stack');
      return '회원 탈퇴 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  /// 삭제 로직 (Firestore + Auth). 재인증 후 호출하거나, requires-recent-login 없이 성공하는 경우 사용
  Future<String?> _deleteAccountCore() async {
    final uid = _user?.uid;
    if (uid == null) return '로그인이 필요합니다.';

    try {
      // 1. subjects/{uid} (보호대상자 문서) 및 prompts 삭제
      final subjectRef = _firestore.collection(AppConstants.subjectsCollection).doc(uid);
      final promptsSnap = await subjectRef.collection(AppConstants.promptsCollection).get();
      for (final doc in promptsSnap.docs) {
        await doc.reference.delete();
      }
      await subjectRef.delete();

      // 2. 다른 보호대상자 문서에서 본인을 보호자로 제거
      final subjectsSnap = await _firestore.collection(AppConstants.subjectsCollection).get();
      for (final doc in subjectsSnap.docs) {
        if (doc.id == uid) continue;
        final data = doc.data();
        final paired = data['pairedGuardianUids'] as List?;
        final infos = data['guardianInfos'] as Map?;
        if (paired == null || !paired.contains(uid)) continue;
        final newPaired = List<String>.from(paired)..remove(uid);
        final newInfos = Map<String, dynamic>.from(infos ?? {})..remove(uid);
        await doc.reference.update({
          'pairedGuardianUids': newPaired,
          'guardianInfos': newInfos,
        });
      }

      // 3. FCM 토큰 제거 (users 문서 삭제 전에 호출 필요)
      await FCMService.instance.removeToken(uid);

      // 4. users/{uid} 삭제
      await _firestore.collection(AppConstants.usersCollection).doc(uid).delete();

      // 5. 약관 동의 목록에서 제거 (재가입 시 약관 다시 동의)
      final phone = _user!.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        await _removeAgreedPhone(phone);
      }

      // 6. Firebase Auth 계정 삭제 (마지막 - 삭제 후 자동 로그아웃)
      await _user!.delete();

      _user = null;
      _userModel = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'REQUIRES_REAUTH'; // UI에서 재인증 플로우로 전환
      }
      return e.message ?? '회원 탈퇴에 실패했습니다.';
    } catch (e, stack) {
      debugPrint('계정 삭제 오류: $e');
      debugPrint('$stack');
      return '회원 탈퇴 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    }
  }

  /// 회원 탈퇴. 성공 시 null. 재인증 필요 시 'REQUIRES_REAUTH' 반환
  Future<String?> deleteAccount() async {
    return _deleteAccountCore();
  }

  Future<void> signOut() async {
    try {
      if (_user != null) {
        await FCMService.instance.removeToken(_user!.uid);
      }
      await _auth.signOut();
      _user = null;
      _userModel = null;
      
      // SharedPreferences 초기화 (선택적 - 필요시 주석 해제)
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('last_login_phone');
      
      notifyListeners();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      // 오류가 발생해도 상태는 초기화
      _user = null;
      _userModel = null;
      notifyListeners();
      rethrow;
    }
  }
}
