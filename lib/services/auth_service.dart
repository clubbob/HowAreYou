import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import '../models/user_model.dart';
import 'fcm_service.dart';
import 'notification_service.dart';
import '../utils/permission_helper.dart';

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

  Future<String?> verifyOTP(String verificationId, String smsCode) async {
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
        final phoneNumber = user.phoneNumber ?? '';
        debugPrint('verifyOTP: 사용자 문서 확보 시도');
        await _ensureUserDocument(user.uid, phoneNumber);
        debugPrint('verifyOTP: 사용자 문서 확보 완료');
        await _saveLastLoginPhone(phoneNumber);
        // FCM은 로그인 완료 후 백그라운드에서 초기화 (에뮬레이터에서 getToken 지연 시 로딩 멈춤 방지)
        FCMService.instance.initialize(user.uid).catchError((e) {
          debugPrint('FCM 초기화 지연/실패 (무시): $e');
        });
        // 로그인 완료 후 오늘 18:00 이전이고 아직 기록하지 않았다면 즉시 알림 표시
        _checkTodayNotificationAfterLogin(user.uid);
      }
      debugPrint('verifyOTP: 완료');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('verifyOTP: FirebaseAuthException - 코드: ${e.code}, 메시지: ${e.message}');
      // Firebase Auth 에러 코드를 한글 메시지로 변환
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = '인증번호가 일치하지 않아요.\n다시 한 번 확인해 주세요.';
          break;
        case 'invalid-verification-id':
          errorMessage = '인증 세션이 만료되었습니다. 전화번호를 다시 입력해주세요.';
          break;
        case 'session-expired':
          errorMessage = '인증 세션이 만료되었습니다. 전화번호를 다시 입력해주세요.';
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
  Future<void> _ensureUserDocument(String uid, String phone) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    final normalizedPhone = _toE164(phone);

    if (!doc.exists) {
      await userRef.set({
        'phone': normalizedPhone,
        'role': 'subject',
        'fcmTokens': [],
      });
    } else {
      // 이미 있는 사용자도 전화번호를 E.164로 갱신 (지정자 조회 일치용)
      await userRef.set(
        {'phone': normalizedPhone},
        SetOptions(merge: true),
      );
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
