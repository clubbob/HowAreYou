import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../services/invite_pending_service.dart';
import '../utils/legal_dialog.dart';
import 'home_screen.dart';
import 'subject_mode_screen.dart';
import 'guardian_mode_screen.dart';

/// 커서가 맨 앞일 때 숫자 입력 시 기존 번호를 지우고 새로 입력
class _ReplaceWhenTypingAtStartFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text.isEmpty) return newValue;
    if (newValue.text.length != oldValue.text.length + 1) return newValue;
    if (newValue.text.substring(1) != oldValue.text) return newValue;
    if (!RegExp(r'^[0-9]').hasMatch(newValue.text)) return newValue;
    return TextEditingValue(
      text: newValue.text[0],
      selection: TextSelection.collapsed(offset: 1),
    );
  }
}

/// 오버플로우 없이 레이아웃되는 약관 동의 체크박스
class _AgreeCheckRow extends StatelessWidget {
  const _AgreeCheckRow({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.onViewTap,
    required this.required,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final VoidCallback onViewTap;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    softWrap: true,
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onViewTap,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      required ? '보기 (필수)' : '보기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.redirectToSubjectIfInvited = false,
    this.redirectToGuardianIfInvited = false,
  });

  final bool redirectToSubjectIfInvited;
  final bool redirectToGuardianIfInvited;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  String? _verificationId;
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;
  AnimationController? _shakeController;
  DateTime? _codeSentTime;
  bool _canResend = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _showTermsCheckboxes = true; // 최초/재가입 시 true, 일반 재로그인 시 false

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController!.reset();
      }
    });
    _phoneController.addListener(_onPhoneChanged);
    _phoneController.addListener(_checkAgreedPhone);
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _phoneFocusNode.hasFocus) {
            _phoneController.selection = TextSelection.collapsed(offset: 0);
          }
        });
      }
    });
    _codeFocusNode.addListener(() {
      if (_codeFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _codeFocusNode.hasFocus) {
            _codeController.selection = TextSelection.collapsed(offset: 0);
          }
        });
      }
    });
    // 이전 로그인 전화번호로 미리 채우기
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillLastPhone());
    // 6자리 입력 시 자동 인증 시도
    _codeController.addListener(() {
      // 에러 메시지가 있으면 입력 시 제거
      if (_errorMessage != null && _codeController.text.isNotEmpty) {
        setState(() {
          _errorMessage = null;
        });
      }
      if (_codeController.text.length == 6 && !_isLoading && _verificationId != null) {
        _verifyOTP();
      }
    });
  }

  void _onPhoneChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkAgreedPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      if (mounted) setState(() {
        _agreedToTerms = false;
        _agreedToPrivacy = false;
        _showTermsCheckboxes = true;
      });
      return;
    }
    final authService = Provider.of<AuthService>(context, listen: false);
    final agreed = await authService.isPhoneAgreed(phone);
    if (mounted) setState(() {
      _showTermsCheckboxes = !agreed; // 일반 재로그인: 체크박스 숨김 / 최초·탈퇴 후 재가입: 체크박스 표시
      if (agreed) {
        _agreedToTerms = true;
        _agreedToPrivacy = true;
      }
      // agreed가 false(신규)일 때는 기존 _agreedToTerms/_agreedToPrivacy를 유지
      // (사용자가 이미 체크한 경우 전화번호 입력 시 덮어쓰지 않음)
    });
  }

  Future<void> _prefillLastPhone() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final last = await authService.getLastLoginPhone();
    if (last == null || !mounted) return;
    final formatted = _formatPhoneNumber(last);
    if (_phoneController.text != formatted) {
      _phoneController.text = formatted;
      _phoneController.selection = TextSelection.collapsed(offset: 0);
    }
    _checkAgreedPhone();
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.removeListener(_checkAgreedPhone);
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  void _shakeInput() {
    if (mounted && _shakeController != null && !_shakeController!.isAnimating) {
      _shakeController!.forward(from: 0.0);
    }
  }

  /// 최초 가입 시 약관 동의 다이얼로그 표시 후 회원가입 완료
  Future<void> _showAgreementAndComplete(BuildContext context, AuthService authService, User user) async {
    bool agreedTerms = false;
    bool agreedPrivacy = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('서비스 이용을 위한 약관 동의'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '계정 생성 전에 이용약관과 개인정보처리방침에 동의해 주세요.',
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(
                        listTileTheme: ListTileThemeData(
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CheckboxListTile(
                            value: agreedTerms,
                            onChanged: (v) => setState(() => agreedTerms = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                const Text('이용약관에 동의 ', style: TextStyle(fontSize: 14)),
                                TextButton(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  onPressed: () => LegalDialog.showTerms(context),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('보기', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
                                      Text(' (필수)', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.none)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CheckboxListTile(
                            value: agreedPrivacy,
                            onChanged: (v) => setState(() => agreedPrivacy = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                const Text('개인정보처리방침에 동의 ', style: TextStyle(fontSize: 14)),
                                TextButton(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  onPressed: () => LegalDialog.showPrivacy(context),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('보기', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline)),
                                      Text(' (필수)', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.none)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await authService.signOut();
                    if (ctx.mounted) Navigator.of(ctx).pop(false);
                  },
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: agreedTerms && agreedPrivacy
                      ? () => Navigator.of(ctx).pop(true)
                      : null,
                  child: const Text('동의하고 계정 생성'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final err = await authService.completeNewUserSignUp(
      user,
      termsAgreedAt: DateTime.now(),
      privacyAgreedAt: DateTime.now(),
    );
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (context.mounted) await _navigateAfterLogin(context, authService);
  }

  /// 로그인 성공 후: 초대 링크로 들어왔으면 보호대상자/보호자 연결 후 해당 화면, 아니면 Home
  Future<void> _navigateAfterLogin(BuildContext context, AuthService authService) async {
    if (!context.mounted) return;
    if (widget.redirectToSubjectIfInvited) {
      final inviterId = await InvitePendingService.getPendingInviterId();
      if (inviterId != null && authService.user != null && context.mounted) {
        try {
          final uid = authService.user!.uid;
          final phone = authService.user!.phoneNumber ?? '';
          await GuardianService().acceptInviteAsSubject(
            subjectUid: uid,
            subjectPhone: phone,
            subjectDisplayName: authService.user!.displayName,
            guardianUid: inviterId,
          );
          await InvitePendingService.clearPendingInviterId();
        } catch (_) {}
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SubjectModeScreen()),
        );
        return;
      }
    }
    if (widget.redirectToGuardianIfInvited) {
      final subjectId = await InvitePendingService.getPendingSubjectId();
      if (subjectId != null && authService.user != null && context.mounted) {
        try {
          final uid = authService.user!.uid;
          final phone = authService.user!.phoneNumber ?? '';
          await GuardianService().acceptInviteAsGuardian(
            guardianUid: uid,
            guardianPhone: phone,
            guardianDisplayName: authService.user!.displayName,
            subjectId: subjectId,
          );
          await InvitePendingService.clearPendingSubjectId();
        } catch (_) {}
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GuardianModeScreen()),
        );
        return;
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen(skipAutoNavigation: true)),
    );
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

  /// 한국 휴대폰 번호 형식 검증 (010으로 시작, 11자리)
  bool _isValidKoreanMobile(String digits) {
    if (digits.length != 11) return false;
    return digits.startsWith('010');
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('핸드폰 번호를 입력해주세요.')),
      );
      return;
    }

    final digits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (!_isValidKoreanMobile(digits)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('010으로 시작하는 11자리 번호를 입력해 주세요.'),
          duration: Duration(seconds: 4),
        ),
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
                  '다른 핸드폰 번호로 로그인',
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
                '다른 핸드폰 번호로 로그인하면 기존 계정과 다른 계정으로 로그인됩니다. 계속하시겠습니까?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('취소', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('계속', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
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
      debugPrint('입력한 전화번호: ${_phoneController.text}');
      debugPrint('변환된 E.164 형식: $phoneNumber');
      
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
          try {
            final err = await authService.verifyWithCredential(
              credential,
              termsAgreedAt: _agreedToTerms ? DateTime.now() : null,
              privacyAgreedAt: _agreedToPrivacy ? DateTime.now() : null,
            );
            if (err != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              return;
            }
            if (mounted) await _navigateAfterLogin(context, authService);
          } on NeedAgreementException catch (e) {
            if (mounted) await _showAgreementAndComplete(context, authService, e.user);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('인증 실패 - 코드: ${e.code}, 메시지: ${e.message}');
          if (mounted) {
            setState(() => _isLoading = false);
            String errorMessage = '인증 실패';
            
            // 에러 코드에 따른 사용자 친화적 메시지
            switch (e.code) {
              case 'invalid-phone-number':
                errorMessage = '입력한 핸드폰 번호 형식이 올바르지 않습니다.\n010으로 시작하는 11자리 번호를 입력해 주세요.';
                break;
              case 'missing-phone-number':
                errorMessage = '핸드폰 번호를 입력해주세요.';
                break;
              case 'quota-exceeded':
                errorMessage = '일일 인증 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.';
                break;
              case 'too-many-requests':
                errorMessage = '너무 많은 요청이 발생했습니다. 5-10분 후 다시 시도해주세요.';
                break;
              default:
                errorMessage = '인증에 실패했습니다. 핸드폰 번호를 확인한 후 다시 시도해 주세요.';
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
              _errorMessage = null;
              _codeSentTime = DateTime.now();
              _canResend = false;
            });
            // 30초 후 재전송 가능하도록 설정
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) {
                setState(() {
                  _canResend = true;
                });
              }
            });
            // 자동 포커스 및 숫자 키패드 표시
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _codeFocusNode.requestFocus();
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
              _codeSentTime = DateTime.now();
              _canResend = false;
            });
            // 30초 후 재전송 가능하도록 설정
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) {
                setState(() {
                  _canResend = true;
                });
              }
            });
            // 자동 포커스 및 숫자 키패드 표시
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _codeFocusNode.requestFocus();
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
      setState(() {
        _errorMessage = '인증번호를 입력해 주세요.';
      });
      _shakeInput();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.verifyOTP(
        _verificationId!,
        _codeController.text,
        termsAgreedAt: _agreedToTerms ? DateTime.now() : null,
        privacyAgreedAt: _agreedToPrivacy ? DateTime.now() : null,
      )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => '로그인 요청이 지연되고 있습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.',
          );

      if (mounted) {
        setState(() => _isLoading = false);
        if (error == null) {
          await _navigateAfterLogin(context, authService);
        } else {
          setState(() => _errorMessage = error);
          _shakeInput();
          _codeController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _codeController.text.length,
          );
        }
      }
    } on NeedAgreementException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await _showAgreementAndComplete(context, Provider.of<AuthService>(context, listen: false), e.user);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is TimeoutException
              ? '요청이 지연되었습니다. 네트워크를 확인해 주세요.'
              : '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
        });
        _shakeInput();
        _codeController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _codeController.text.length,
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _codeController.clear();
      _canResend = false;
    });

    try {
      await _sendOTP();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호를 다시 보냈어요.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 타이틀 제거 - 시작 화면이므로 불필요
        automaticallyImplyLeading: false,
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
                _codeSent ? '인증번호 입력' : '오늘 어때?',
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
                _codeSent 
                    ? '문자로 받은 6자리 인증번호를 입력해 주세요.' 
                    : '매일 전화 대신 3초 확인.\n하루 한 번이면 충분해요.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_codeSent) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      decoration: InputDecoration(
                        labelText: '핸드폰 번호',
                        hintText: '01012345678',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        _ReplaceWhenTypingAtStartFormatter(),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '숫자만 입력하세요',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_showTermsCheckboxes) ...[
                  _AgreeCheckRow(
                    value: _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    label: '이용약관에 동의',
                    onViewTap: () => LegalDialog.showTerms(context),
                    required: true,
                  ),
                  const SizedBox(height: 8),
                  _AgreeCheckRow(
                    value: _agreedToPrivacy,
                    onChanged: (v) => setState(() => _agreedToPrivacy = v ?? false),
                    label: '개인정보처리방침에 동의',
                    onViewTap: () => LegalDialog.showPrivacy(context),
                    required: true,
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: (_isLoading || _phoneController.text.trim().isEmpty || (_showTermsCheckboxes && (!_agreedToTerms || !_agreedToPrivacy))) ? null : _sendOTP,
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
                      : const Text('인증번호 받기'),
                ),
                if (_showTermsCheckboxes) ...[
                  const SizedBox(height: 8),
                  Text(
                    '휴대폰 번호 인증 시 계정이 생성됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else ...[
                _shakeController != null
                    ? AnimatedBuilder(
                        animation: _shakeController!,
                        builder: (context, child) {
                          final offset = _shakeController!.value;
                          // 부드러운 좌우 흔들림 효과
                          final shakeOffset = 8.0 * (offset < 0.5 
                              ? -offset * 2 
                              : (offset - 0.5) * 2 - 1);
                          return Transform.translate(
                            offset: Offset(shakeOffset, 0),
                            child: child,
                          );
                        },
                        child: TextField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          decoration: InputDecoration(
                            hintText: '',
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
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 12,
                            color: Color(0xFF202124),
                          ),
                        ),
                      )
                    : TextField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        decoration: InputDecoration(
                          hintText: '',
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
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 12,
                          color: Color(0xFF202124),
                        ),
                      ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFD32F2F),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else if (_showTermsCheckboxes) ...[
                  const SizedBox(height: 8),
                  Text(
                    '인증번호는 안전하게 처리됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
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
                      : const Text('인증하기'),
                ),
                if (_showTermsCheckboxes) ...[
                  const SizedBox(height: 8),
                  Text(
                    '휴대폰 번호 인증 시 계정이 생성됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _codeSent = false;
                          _codeController.clear();
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        '핸드폰 번호 다시 입력',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    if (_canResend)
                      TextButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: Text(
                          '인증번호 다시 받기',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                  ],
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
