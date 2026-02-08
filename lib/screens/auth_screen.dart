import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/button_styles.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 한국 전화번호를 E.164 형식으로 변환 (+821012345678)
  String _toE164(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
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
  
  /// 전화번호를 읽기 쉬운 형식으로 변환 (010-1111-2222)
  /// +82 10 xxxx xxxx → 010-xxxx-xxxx (digits가 10으로 시작하는 10자리)
  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('+82')) {
      final digits = phone.substring(3);
      if (digits.length == 10 && digits.startsWith('10')) {
        return '010-${digits.substring(2, 6)}-${digits.substring(6)}';
      }
      if (digits.length == 9 && digits.startsWith('10')) {
        return '010-${digits.substring(2, 5)}-${digits.substring(5)}';
      }
      if (digits.length == 10) {
        return '010-${digits.substring(0, 4)}-${digits.substring(4)}';
      }
      if (digits.length == 9) {
        return '010-${digits.substring(0, 3)}-${digits.substring(3)}';
      }
    }
    // 이미 010- 형식이거나 다른 형식인 경우 그대로 반환
    if (phone.contains('-')) {
      return phone;
    }
    // 숫자만 있는 경우
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11 && digits.startsWith('010')) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    return phone;
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 입력해주세요.')),
      );
      return;
    }

    final phoneNumber = _toE164(_phoneController.text);
    
    // 이전에 로그인한 번호와 다른 경우 경고 다이얼로그 표시
    final authService = Provider.of<AuthService>(context, listen: false);
    final lastLoginPhone = await authService.getLastLoginPhone();
    
    if (lastLoginPhone != null && lastLoginPhone != phoneNumber) {
      // 다른 번호로 로그인 시도 - 경고 다이얼로그 표시
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '다른 전화번호로 로그인',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이전에 로그인한 번호와 다른 번호입니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '이전 번호: ${_formatPhoneNumber(lastLoginPhone)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '입력한 번호: ${_formatPhoneNumber(phoneNumber)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '다른 전화번호로 로그인하면 기존 계정과 다른 계정으로 로그인됩니다. 계속하시겠습니까?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '계속',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      
      if (shouldContinue != true) {
        // 사용자가 취소한 경우
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // Windows/데스크톱에서는 전화 인증이 지원되지 않음 (웹 제외)
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('전화 인증은 Android 또는 iOS에서만 지원됩니다. 실제 기기에서 테스트해주세요.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    try {
      debugPrint('인증 코드 전송 시도: $phoneNumber');
      // 에뮬레이터 등에서 콜백이 늦게 오면 로딩이 멈추지 않을 수 있음 → 10초 후 강제 해제
      Future.delayed(const Duration(seconds: 10), () {
        if (!mounted) return;
        if (_isLoading || (!_codeSent && _verificationId != null)) {
          setState(() {
            _isLoading = false;
            if (_verificationId != null) _codeSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증 코드 입력란을 확인해 주세요. 코드가 있다면 입력 후 인증하기를 누르세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('자동 인증 완료: ${credential.smsCode}');
          if (mounted) setState(() => _isLoading = false);
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.verifyOTP('', credential.smsCode ?? '');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen(skipAutoNavigation: true)),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('인증 실패 - 코드: ${e.code}, 메시지: ${e.message}');
          if (mounted) {
            setState(() => _isLoading = false);
            String errorMessage = '인증 실패';
            
            // 에러 코드에 따른 구체적인 메시지
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = '전화번호 형식이 올바르지 않습니다.\n입력한 번호: $phoneNumber';
                break;
              case 'missing-phone-number':
                errorMessage = '전화번호를 입력해주세요.';
                break;
              case 'quota-exceeded':
                errorMessage = '일일 인증 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.';
                break;
              case 'too-many-requests':
                errorMessage = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
                break;
              default:
                errorMessage = '인증 실패: ${e.message ?? e.code}\n\n전화번호: $phoneNumber\n\nFirebase Console에서 테스트 전화번호가 등록되어 있는지 확인해주세요.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 8),
                action: SnackBarAction(
                  label: '확인',
                  onPressed: () {},
                ),
              ),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('인증 코드 전송 성공: verificationId=$verificationId');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('인증 코드가 전송되었습니다.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('자동 인증 코드 타임아웃: $verificationId');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('인증 코드를 수동으로 입력해주세요.'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            _verificationId = verificationId;
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e, stack) {
      debugPrint('인증 코드 전송 예외 발생: $e');
      debugPrint('스택: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_codeController.text.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService
          .verifyOTP(_verificationId!, _codeController.text)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => '로그인 요청이 지연되고 있습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.',
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (error == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen(skipAutoNavigation: true)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), duration: const Duration(seconds: 5)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final msg = e is TimeoutException ? (e.message ?? '요청이 지연되었습니다. 네트워크를 확인해 주세요.') : '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                _codeSent ? '인증 코드 입력' : '지금 어때?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: Color(0xFF202124),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent ? '문자로 받은 6자리 코드를 입력하세요' : '전화번호로 로그인하세요',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: '전화번호',
                    hintText: '010-1234-5678',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('인증 코드 전송'),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 12,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('인증 확인'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _codeSent = false;
                      _codeController.clear();
                    });
                  },
                  child: Text(
                    '전화번호 다시 입력',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
