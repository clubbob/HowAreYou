import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      _user = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
        notifyListeners();
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
      // FCM 서비스 초기화 (모바일에서만)
      await FCMService.instance.initialize(uid);
      notifyListeners();
    } catch (e, stack) {
      debugPrint('사용자 데이터 로드 오류: $e');
      debugPrint('스택: $stack');
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
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // 사용자 문서가 없으면 생성
        await _ensureUserDocument(user.uid, user.phoneNumber ?? '');
        // FCM 서비스 초기화
        await FCMService.instance.initialize(user.uid);
      }
      
      return null;
    } catch (e) {
      return e.toString();
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
    if (_user != null) {
      await FCMService.instance.removeToken(_user!.uid);
    }
    await _auth.signOut();
    _user = null;
    _userModel = null;
    notifyListeners();
  }
}
