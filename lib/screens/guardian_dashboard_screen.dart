import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../services/mood_service.dart';
import '../services/fcm_service.dart';
import '../utils/permission_helper.dart';
import 'dart:io' show Platform;
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import '../utils/constants.dart';
import '../utils/invite_link_helper.dart';
import '../main.dart';
import 'subject_detail_screen.dart';
import 'auth_screen.dart';
import 'guardian_mode_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  final GuardianService _guardianService = GuardianService();
  final MoodService _moodService = MoodService();
  Future<List<String>>? _subjectIdsFuture;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isAdding = false;

  static const double _inputRadius = 12;
  static const double _inputMinHeight = 56;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 보호자 대시보드 진입 시 FCM 초기화 (알림 수신을 위해)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  Future<void> _initializeFCM() async {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.user?.uid;
    if (userId == null) {
      debugPrint('[보호자 대시보드] 사용자 ID가 없음');
      return;
    }

    debugPrint('[보호자 대시보드] FCM 초기화 시작');

    // Android에서 알림 권한 확인 및 요청
    if (Platform.isAndroid) {
      try {
        final isGranted = await PermissionHelper.isNotificationPermissionGranted();
        debugPrint('[보호자 대시보드] 알림 권한 상태: $isGranted');
        if (!isGranted && mounted) {
          debugPrint('[보호자 대시보드] 알림 권한 요청 시작');
          final granted = await PermissionHelper.requestNotificationPermission(context, isForSubject: false);
          debugPrint('[보호자 대시보드] 알림 권한 요청 결과: $granted');
        } else {
          debugPrint('[보호자 대시보드] 알림 권한이 이미 허용되어 있음');
        }
      } catch (e) {
        debugPrint('[보호자 대시보드] 알림 권한 요청 오류: $e');
      }
    }

    // FCM 초기화 (토큰 저장) - 강제로 다시 초기화하여 토큰이 확실히 저장되도록 함
    try {
      await FCMService.instance.initialize(userId, context: context, forceReinitialize: true);
      debugPrint('[보호자 대시보드] FCM 초기화 완료');
    } catch (e) {
      debugPrint('[보호자 대시보드] FCM 초기화 오류: $e');
    }
  }

  void _refreshList(String userId) {
    setState(() {
      _subjectIdsFuture = _guardianService.getSubjectIdsForGuardian(userId);
    });
  }

  Future<void> _addSubject(BuildContext context, String userId) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요.')),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final subjectId = await _guardianService.addMeAsGuardianToSubject(
        subjectPhone: _phoneController.text.trim(),
        guardianUid: userId,
        guardianPhone: authService.userModel?.phone ??
            authService.user?.phoneNumber ??
            '',
        guardianDisplayName: authService.userModel?.displayName,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          '요청이 지연되고 있습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.',
        ),
      );

      final name = _nameController.text.trim();
      if (name.isNotEmpty && mounted) {
        await _guardianService.setSubjectDisplayNameByGuardian(
          guardianUid: userId,
          subjectId: subjectId,
          displayName: name,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {},
        );
      }

      if (mounted) {
        _nameController.clear();
        _phoneController.clear();
        _refreshList(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보호 대상이 추가되었습니다.')),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        debugPrint('보호대상자 추가 오류: $e');
        debugPrint('$stack');
        if (e is NoSubjectUserException) {
          await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              icon: Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 48),
              title: const Text('경고'),
              content: Text(e.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('등록에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _showInviteBottomSheet(BuildContext context, String userId) {
    final inviteUrl = InviteLinkHelper.buildInviteUrl(userId);
    final screenHeight = MediaQuery.of(context).size.height;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: screenHeight * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '보호 대상 초대 링크',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 내용
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 공유 예시 문구 카드
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '공유 예시 문구',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  final fullMessage = InviteLinkHelper.getFullInviteMessage(userId);
                                  Clipboard.setData(
                                    ClipboardData(text: fullMessage),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('문구가 복사되었습니다'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                tooltip: '복사',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            InviteLinkHelper.getFullInviteMessage(userId),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 공유 버튼
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await InviteLinkHelper.shareInvite(userId);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.share, size: 22),
                        label: const Text('공유하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C6BC0),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('보호 대상 관리')),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    if (_subjectIdsFuture == null) {
      _subjectIdsFuture = _guardianService
          .getSubjectIdsForGuardian(userId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => <String>[],
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('보호 대상 관리'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () {
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // 이전 화면이 없으면 GuardianModeScreen으로 이동
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GuardianModeScreen()),
                );
              }
            } catch (e) {
              // pop() 실패 시 GuardianModeScreen으로 이동
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GuardianModeScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 18),
                const SizedBox(width: 4),
                const Text('뒤로', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
        actions: [
          // 로그아웃 버튼 (테스트용)
          TextButton.icon(
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('로그아웃', style: TextStyle(fontSize: 14)),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && context.mounted) {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                // 로그아웃 후 AuthScreen으로 이동
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                } else if (MyApp.navigatorKey.currentContext != null) {
                  // context가 없으면 전역 Navigator 사용
                  Navigator.of(MyApp.navigatorKey.currentContext!).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 보호 대상 목록
            Expanded(
              child: FutureBuilder<List<String>>(
              future: _subjectIdsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Text(
                      snapshot.hasError
                          ? '오류: ${snapshot.error}'
                          : '보호 대상 목록을 불러올 수 없습니다.',
                    ),
                  );
                }
                final subjectIds = snapshot.data!;
                if (subjectIds.isEmpty) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      24 + MediaQuery.of(context).padding.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. 보호 대상 목록 (빈 상태)
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '등록된 보호 대상이 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        // 2. 보호 대상 추가 버튼
                        const SizedBox(height: 32),
                        const Text(
                          '보호 대상 추가',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 10),
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: '보호 대상 이름(별칭)',
                              hintText: '예: 엄마, 아빠',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_inputRadius),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400 ?? Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_inputRadius),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400 ?? Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_inputRadius),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                16,
                                16,
                              ),
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            canRequestFocus: true,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 10),
                          child: TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: '보호 대상 전화번호',
                              hintText: '01012345678 (숫자만)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_inputRadius),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400 ?? Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_inputRadius),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400 ?? Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(_inputRadius),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                20,
                                16,
                                16,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            canRequestFocus: true,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: _inputMinHeight,
                          child: ElevatedButton(
                            onPressed: _isAdding ? null : () => _addSubject(context, userId),
                            style: AppButtonStyles.primaryElevated,
                            child: _isAdding
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('보호 대상 추가'),
                          ),
                        ),
                        // 3. 초대 영역
                        const SizedBox(height: 32),
                        const Text(
                          '링크로 보호 대상 초대',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '링크를 보내면 보호대상자는 앱이 없어도 설치 후 자동 연결됩니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _showInviteBottomSheet(context, userId),
                            icon: const Icon(Icons.link, size: 22),
                            label: const Text('보호 대상에게 초대 링크 보내기'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size(double.infinity, 56),
                              foregroundColor: const Color(0xFF5C6BC0),
                              side: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        // 4. 안내
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '안내',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '이 서비스는 안부 전달을 위한 참고 정보만 제공합니다.\n판단이나 조치를 위한 용도가 아닙니다.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 보호 대상이 1명 이상이면 목록 표시 (선택 시 상세 화면으로 이동)
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + MediaQuery.of(context).padding.bottom + 24,
                  ),
                  children: [
                    // 1. 보호 대상 목록
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '보호 대상 (${subjectIds.length}명)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...subjectIds.map((subjectId) {
                          return _SubjectListItem(
                            subjectId: subjectId,
                            guardianUid: userId,
                            guardianService: _guardianService,
                            moodService: _moodService,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SubjectDetailScreen(
                                    subjectId: subjectId,
                                    guardianUid: userId,
                                    guardianService: _guardianService,
                                    moodService: _moodService,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                    // 2. 보호 대상 추가 버튼
                    const SizedBox(height: 28),
                    const Text(
                      '보호 대상 추가',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '보호 대상 이름(별칭)',
                          hintText: '예: 엄마, 아빠 (선택)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400 ?? Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400 ?? Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            20,
                            16,
                            16,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.words,
                        canRequestFocus: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: '보호 대상 전화번호',
                          hintText: '01012345678 (숫자만)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400 ?? Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                            borderSide: BorderSide(
                              color: Colors.grey.shade400 ?? Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(_inputRadius),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            20,
                            16,
                            16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        canRequestFocus: true,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: _inputMinHeight,
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : () => _addSubject(context, userId),
                        style: AppButtonStyles.primaryElevated,
                        child: _isAdding
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('보호 대상 추가'),
                      ),
                    ),
                    // 3. 초대 영역
                    const SizedBox(height: 32),
                    const Text(
                      '링크로 보호 대상 초대',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '링크를 보내면 보호대상자는 앱이 없어도 설치 후 자동 연결됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _showInviteBottomSheet(context, userId),
                        icon: const Icon(Icons.link, size: 22),
                        label: const Text('보호 대상에게 초대 링크 보내기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          alignment: Alignment.centerLeft,
                          minimumSize: const Size(double.infinity, 56),
                          foregroundColor: const Color(0xFF5C6BC0),
                          side: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    // 4. 안내
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '안내',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이 서비스는 안부 전달을 위한 참고 정보만 제공합니다.\n판단이나 조치를 위한 용도가 아닙니다.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// 보호 대상 목록 아이템. [subjectId] = 보호대상자 Auth UID (PRD §9).
class _SubjectListItem extends StatefulWidget {
  final String subjectId;
  final String guardianUid;
  final GuardianService guardianService;
  final MoodService moodService;
  final VoidCallback onTap;

  const _SubjectListItem({
    required this.subjectId,
    required this.guardianUid,
    required this.guardianService,
    required this.moodService,
    required this.onTap,
  });

  @override
  State<_SubjectListItem> createState() => _SubjectListItemState();
}

class _SubjectListItemState extends State<_SubjectListItem> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _subjectName = '…';
  Map<TimeSlot, MoodResponseModel?>? _todayResponses;
  DateTime? _latestAnsweredAt;
  String _fallbackName = '이름 없음';
  late final Stream<String> _nameStream;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadResponses();
    _nameStream = _firestore
        .collection(AppConstants.usersCollection)
        .doc(widget.guardianUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return '이름 없음';
      }
      final data = doc.data();
      final labels = data?['subjectLabels'];
      if (labels is Map) {
        final v = labels[widget.subjectId];
        if (v is String && v.trim().isNotEmpty) {
          return v.trim();
        }
      }
      return '이름 없음';
    });
  }

  Future<void> _loadName() async {
    final name = await widget.guardianService.getSubjectDisplayName(widget.subjectId);
    if (mounted) {
      setState(() {
        _fallbackName = name;
      });
    }
  }

  Future<void> _loadResponses() async {
    // 보호자용: note 필드 제외
    final today = await widget.moodService.getTodayResponses(widget.subjectId, excludeNote: true);
    final last7 = await widget.moodService.getLast7DaysResponses(widget.subjectId, excludeNote: true);
    DateTime? latest;
    for (final dayMap in last7.values) {
      for (final r in dayMap.values) {
        if (r != null && (latest == null || r.answeredAt.isAfter(latest))) {
          latest = r.answeredAt;
        }
      }
    }
    if (mounted) {
      setState(() {
        _todayResponses = today;
        _latestAnsweredAt = latest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _nameStream,
      initialData: _fallbackName,
      builder: (context, nameSnapshot) {
        final subjectName = nameSnapshot.data ?? _fallbackName;
        final hasRespondedToday =
            _todayResponses?.values.any((r) => r != null) ?? false;
        final hasAnyRecordLast7 = _latestAnsweredAt != null;

        // 상태 요약 문구 (기록 여부만 표현)
        final String statusText;
        if (_todayResponses == null) {
          statusText = '기록 정보를 불러오는 중입니다.';
        } else if (hasRespondedToday) {
          statusText = '오늘 기록이 전달되었습니다.';
        } else if (hasAnyRecordLast7) {
          statusText = '최근 7일 내에 기록이 있었습니다.';
        } else {
          statusText = '최근 7일 내 기록이 없습니다.';
        }

        final statusColor =
            hasAnyRecordLast7 ? Colors.green.shade700 : Colors.grey.shade700;

        // 최근 기록 날짜 (시간은 공유하지 않음)
        final String dateText;
        if (_latestAnsweredAt == null) {
          dateText = '최근 전달: 없음';
        } else {
          final dateStr =
              DateFormat('yyyy년 M월 d일', 'ko_KR').format(_latestAnsweredAt!);
          dateText = '최근 전달: $dateStr';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              subjectName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 32),
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}

/// 보호자 설정 화면
class GuardianSettingsScreen extends StatefulWidget {
  const GuardianSettingsScreen({super.key});

  @override
  State<GuardianSettingsScreen> createState() => _GuardianSettingsScreenState();
}

class _GuardianSettingsScreenState extends State<GuardianSettingsScreen> {
  bool _notificationSoundEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await FCMService.instance.getNotificationSoundEnabled();
    if (mounted) {
      setState(() {
        _notificationSoundEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotificationSound(bool value) async {
    setState(() {
      _notificationSoundEnabled = value;
    });
    await FCMService.instance.setNotificationSoundEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () {
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // 이전 화면이 없으면 GuardianDashboardScreen으로 이동
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
                );
              }
            } catch (e) {
              // pop() 실패 시 GuardianDashboardScreen으로 이동
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GuardianDashboardScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 18),
                const SizedBox(width: 4),
                const Text('뒤로', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text('알림 소리'),
                    subtitle: const Text('안부 전달 알림 소리 재생'),
                    trailing: Switch(
                      value: _notificationSoundEnabled,
                      onChanged: _toggleNotificationSound,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
