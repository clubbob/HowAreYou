import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'fcm_service.dart';

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
  Future<void> get authReady => _authReadyCompleter.future;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (!_authReadyCompleter.isCompleted) _authReadyCompleter.complete();
      final wasAuthenticated = _user != null;
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
        // 로그아웃 시에만 자동으로 AuthScreen으로 이동 (로그인 시에는 수동 처리)
        if (wasAuthenticated) {
          // 로그아웃이 감지되었을 때만 처리
          // Navigator는 각 화면에서 처리하므로 여기서는 처리하지 않음
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
      }
      debugPrint('verifyOTP: 완료');
      return null;
    } catch (e) {
      debugPrint('verifyOTP: 오류 $e');
      return e.toString();
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
