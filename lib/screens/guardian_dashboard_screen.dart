import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
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
import '../utils/legal_dialog.dart';
import '../main.dart';
import 'subject_detail_screen.dart';
import 'auth_screen.dart';
import 'guardian_mode_screen.dart';
import 'inquiry_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

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

  /// 안부 확인 탭: 상태 로드 후 미기록/오래된 순 정렬
  Future<List<_SubjectCheckStatus>> _loadAndSortCheckSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) return [];
    final statuses = await Future.wait(subjectIds.map((id) async {
      final today = await _moodService.getTodayResponses(id, forGuardian: true);
      final last7 = await _moodService.getLast7DaysResponses(id, forGuardian: true);
      final streak = await _moodService.getStreak(id);
      DateTime? latest;
      for (final dayMap in last7.values) {
        for (final r in dayMap.values) {
          if (r != null && (latest == null || r.answeredAt.isAfter(latest))) {
            latest = r.answeredAt;
          }
        }
      }
      final hasToday = today.values.any((r) => r != null);
      return _SubjectCheckStatus(id, hasToday, latest, streak?.currentStreak ?? 0);
    }));
    // 정렬: 미기록 먼저 → 기록 없음(최상단) → 오래된 순
    statuses.sort((a, b) {
      final aHas = a.hasRespondedToday ?? false;
      final bHas = b.hasRespondedToday ?? false;
      if (aHas != bHas) {
        return aHas ? 1 : -1; // 미기록 먼저
      }
      final aAt = a.latestAnsweredAt;
      final bAt = b.latestAnsweredAt;
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return -1; // 기록 없음 → 최상단
      if (bAt == null) return 1;
      return aAt.compareTo(bAt); // 오래된 순 (주의 대상 우선)
    });
    return statuses;
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
        const SnackBar(content: Text('핸드폰 번호를 입력해주세요.')),
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
        debugPrint('stack: $stack');
        if (e is PendingInviteCreatedException) {
          _nameController.clear();
          _phoneController.clear();
          _refreshList(userId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.green.shade700),
          );
          return;
        }
        String message = '등록에 실패했습니다.';
        if (e is NoSubjectUserException) {
          message = e.message;
        } else if (e is PendingInviteCreatedException) {
          message = e.message;
        } else if (e is FirebaseException) {
          final fe = e as FirebaseException;
          if (fe.code == 'permission-denied') {
            message = '접근 권한이 없습니다. Firestore 규칙을 확인해 주세요.';
          } else {
            message = fe.message ?? fe.code;
          }
        } else if (e is TimeoutException) {
          message = '요청 시간이 초과되었습니다. 네트워크를 확인해 주세요.';
        } else {
          final str = e.toString();
          if (str.startsWith('Exception: ')) {
            message = str.substring('Exception: '.length).split('\n').first.trim();
          } else if (str.contains('permission-denied')) {
            message = '접근 권한이 없습니다. Firestore 규칙을 확인해 주세요.';
          } else if (str.contains('이미 보호 대상') || str.contains('이미 등록')) {
            message = '이미 보호 대상으로 등록된 분입니다.';
          } else if (str.contains('본인 핸드폰 번호')) {
            message = '본인 핸드폰 번호는 추가할 수 없습니다.';
          } else {
            final first = str.split(RegExp(r' at |\n')).first.trim();
            if (first.length > 0 && first.length < 200) message = first;
          }
        }
        // 실제 오류 원인 표시 (진단용 - 다음 등록 시도 시 원인 확인)
        final rawError = e.toString().split('\n').first;
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            icon: Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 48),
            title: const Text('보호 대상 추가 실패'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  Text('오류: $rawError', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('확인'),
              ),
            ],
          ),
        );
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
        title: Text(widget.initialTabIndex == 0 ? '안부 확인' : '보호 대상 관리'),
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GuardianSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('로그아웃하시겠습니까?'),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade800,
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('로그아웃'),
                          ),
                        ),
                      ],
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
            return widget.initialTabIndex == 0
                ? FutureBuilder<List<_SubjectCheckStatus>>(
                    future: _loadAndSortCheckSubjects(subjectIds),
                    builder: (context, statusSnapshot) {
                      if (statusSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final sorted = statusSnapshot.data ??
                          subjectIds.map((id) => _SubjectCheckStatus(id, null, null, 0)).toList();
                      return _buildCheckTab(context, sorted, userId!);
                    },
                  )
                : _buildManageTab(context, subjectIds, userId!);
          },
        ),
      ),
    );
  }

  /// 오늘 기록한 보호대상자 이름 목록 로드 후 문구 생성
  Future<String> _loadRecordedSubjectsMessage(
    List<_SubjectCheckStatus> statuses,
    String guardianUid,
  ) async {
    final recorded = statuses.where((s) => s.hasRespondedToday == true).toList();
    if (recorded.isEmpty) return '오늘 아직 안부가 없습니다.\n간단히 확인해보세요.';

    final names = await Future.wait(
      recorded.map((s) => _guardianService.getSubjectDisplayNameForGuardian(s.subjectId, guardianUid)),
    );
    final quoted = names.map((n) => '"$n"').join(', ');
    return '오늘 ${quoted}분이 기록을 남겼습니다.';
  }

  Widget _buildCheckTab(BuildContext context, List<_SubjectCheckStatus> statuses, String userId) {
    if (statuses.isEmpty) {
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
            Icon(Icons.visibility_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '등록된 보호 대상이 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '보호 대상을 추가한 뒤 안부를 확인할 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const GuardianDashboardScreen(initialTabIndex: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline, size: 22),
                label: const Text('보호 대상 추가하러 가기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5C6BC0),
                  side: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final allRecorded = statuses.isNotEmpty && statuses.every((s) => s.hasRespondedToday == true);
    final noneRecorded = statuses.every((s) => s.hasRespondedToday != true);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        // 오늘 확인 완료 배지 + 기록한 보호대상자 이름 메시지
        FutureBuilder<String>(
          future: _loadRecordedSubjectsMessage(statuses, userId),
          builder: (context, msgSnapshot) {
            final message = msgSnapshot.data ?? '오늘 안부를 확인해 보세요.';
            return Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: allRecorded ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: allRecorded ? Colors.green.shade200 : Colors.grey.shade200,
                ),
              ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: allRecorded ? Colors.green.shade900 : Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Text(
          '보호 대상 (${statuses.length}명)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...statuses.map((s) {
          return _SubjectListItem(
            subjectId: s.subjectId,
            guardianUid: userId,
            guardianService: _guardianService,
            moodService: _moodService,
            initialStatus: s,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubjectDetailScreen(
                    subjectId: s.subjectId,
                    guardianUid: userId,
                    guardianService: _guardianService,
                    moodService: _moodService,
                  ),
                ),
              );
            },
            // 안부 확인 탭에서는 삭제 버튼 숨김 (실수 방지)
          );
        }),
      ],
    );
  }

  Widget _buildManageTab(BuildContext context, List<String> subjectIds, String userId) {
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
                              labelText: '보호 대상 핸드폰 번호',
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

    // 보호 대상이 1명 이상이면 목록 + 추가 폼 + 초대
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
                          return _SubjectManagementItem(
                            subjectId: subjectId,
                            guardianUid: userId,
                            guardianService: _guardianService,
                            onUpdated: () async => _refreshList(userId),
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
                          labelText: '보호 대상 핸드폰 번호',
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
  }
}

/// 안부 확인 탭 정렬용: subjectId + 오늘 기록 여부 + 마지막 기록 시각 + 스트릭
class _SubjectCheckStatus {
  final String subjectId;
  final bool? hasRespondedToday;
  final DateTime? latestAnsweredAt;
  final int currentStreak;

  _SubjectCheckStatus(this.subjectId, this.hasRespondedToday, this.latestAnsweredAt, [this.currentStreak = 0]);
}

/// 보호대상자 연결 상태 배지 - 아이콘 + 텍스트
class _SubjectStatusBadge extends StatelessWidget {
  final bool isStillPaired;

  const _SubjectStatusBadge({required this.isStillPaired});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isStillPaired ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStillPaired ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isStillPaired ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: isStillPaired ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isStillPaired ? '연결' : '비연결',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isStillPaired ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// 보호 대상 관리 탭용 아이템 - 이름 + 수정 + 삭제만 (기록 미표시)
class _SubjectManagementItem extends StatefulWidget {
  final String subjectId;
  final String guardianUid;
  final GuardianService guardianService;
  final Future<void> Function() onUpdated;

  const _SubjectManagementItem({
    required this.subjectId,
    required this.guardianUid,
    required this.guardianService,
    required this.onUpdated,
  });

  @override
  State<_SubjectManagementItem> createState() => _SubjectManagementItemState();
}

class _SubjectManagementItemState extends State<_SubjectManagementItem> {
  String _displayName = '…';
  String _subjectPhone = '';
  late final Stream<String> _nameStream;
  late final Future<bool> _isStillPairedFuture;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadPhone();
    _isStillPairedFuture = widget.guardianService.isGuardianStillPairedBySubject(
      widget.subjectId,
      widget.guardianUid,
    );
    _nameStream = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(widget.guardianUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return '이름 없음';
      final labels = doc.data()?['subjectLabels'];
      if (labels is Map) {
        final v = labels[widget.subjectId];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '이름 없음';
    });
  }

  Future<void> _loadName() async {
    final name = await widget.guardianService.getSubjectDisplayNameForGuardian(
      widget.subjectId,
      widget.guardianUid,
    );
    if (mounted) setState(() => _displayName = name);
  }

  Future<void> _loadPhone() async {
    final phone = await widget.guardianService.getSubjectPhone(widget.subjectId);
    if (mounted) setState(() => _subjectPhone = phone);
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: _displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름(별칭) 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '예: 엄마, 아빠',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  style: AppButtonStyles.primaryElevated,
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    try {
      await widget.guardianService.setSubjectDisplayNameByGuardian(
        guardianUid: widget.guardianUid,
        subjectId: widget.subjectId,
        displayName: result,
      );
      await widget.onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이름이 수정되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정에 실패했습니다: ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  Future<void> _showRemoveDialog(BuildContext context, String subjectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('보호 대상 삭제'),
        content: Text(
          '"$subjectName"을(를) 보호 대상 목록에서 삭제하시겠습니까?\n\n'
          '삭제해도 보호대상자 앱에는 영향이 없습니다.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: AppButtonStyles.primaryElevated,
                  child: const Text('삭제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.guardianService.removeSubjectFromGuardian(
        guardianUid: widget.guardianUid,
        subjectId: widget.subjectId,
      );
      await widget.onUpdated();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보호 대상이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제에 실패했습니다: ${e.toString().split('\n').first}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _nameStream,
      initialData: _displayName,
      builder: (context, snapshot) {
        final name = snapshot.data ?? _displayName;
        return FutureBuilder<bool>(
          future: _isStillPairedFuture,
          builder: (context, pairedSnapshot) {
            final isStillPaired = pairedSnapshot.data ?? true;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _SubjectStatusBadge(isStillPaired: isStillPaired),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (_subjectPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _subjectPhone,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 22, color: Colors.grey[600]),
                          tooltip: '이름 수정',
                          onPressed: () => _showEditDialog(context),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 22, color: Colors.grey[600]),
                          tooltip: '삭제',
                          onPressed: () => _showRemoveDialog(context, name),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 보호 대상 목록 아이템. [subjectId] = 보호대상자 Auth UID (PRD §9).
class _SubjectListItem extends StatefulWidget {
  final String subjectId;
  final String guardianUid;
  final GuardianService guardianService;
  final MoodService moodService;
  final _SubjectCheckStatus? initialStatus;
  final VoidCallback onTap;
  final Future<void> Function(String subjectId)? onRemove;

  const _SubjectListItem({
    required this.subjectId,
    required this.guardianUid,
    required this.guardianService,
    required this.moodService,
    this.initialStatus,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<_SubjectListItem> createState() => _SubjectListItemState();
}

class _SubjectListItemState extends State<_SubjectListItem> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _subjectName = '…';
  String _subjectPhone = '';
  Map<TimeSlot, MoodResponseModel?>? _todayResponses;
  DateTime? _latestAnsweredAt;
  int _currentStreak = 0;
  String _fallbackName = '이름 없음';
  late final Stream<String> _nameStream;
  late final Future<bool> _isStillPairedFuture;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadPhone();
    _loadResponses();
    _isStillPairedFuture = widget.guardianService.isGuardianStillPairedBySubject(
      widget.subjectId,
      widget.guardianUid,
    );
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

  Future<void> _loadPhone() async {
    final phone = await widget.guardianService.getSubjectPhone(widget.subjectId);
    if (mounted) setState(() => _subjectPhone = phone);
  }

  Future<void> _showRemoveDialog(BuildContext context, String subjectName) async {
    if (widget.onRemove == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('보호 대상 삭제'),
        content: Text(
          '"$subjectName"을(를) 보호 대상 목록에서 삭제하시겠습니까?\n\n'
          '삭제해도 보호대상자 앱에는 영향이 없습니다.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: AppButtonStyles.primaryElevated,
                  child: const Text('삭제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await widget.guardianService.removeSubjectFromGuardian(
        guardianUid: widget.guardianUid,
        subjectId: widget.subjectId,
      );
      await widget.onRemove!(widget.subjectId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보호 대상이 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제에 실패했습니다: ${e.toString().split('\n').first}'),
          ),
        );
      }
    }
  }

  Future<void> _loadResponses() async {
    if (widget.initialStatus != null) {
      final s = widget.initialStatus!;
      if (mounted) {
        setState(() {
          _todayResponses = s.hasRespondedToday == true
              ? {
                  TimeSlot.daily: MoodResponseModel(
                    subjectId: widget.subjectId,
                    dateSlot: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    slot: TimeSlot.daily,
                    answeredAt: s.latestAnsweredAt ?? DateTime.now(),
                    mood: Mood.normal,
                    note: null,
                  ),
                }
              : {TimeSlot.daily: null};
          _latestAnsweredAt = s.latestAnsweredAt;
          _currentStreak = s.currentStreak;
        });
      }
      return;
    }
    // 보호자용: prompts만 (기록 여부만, mood/note 비공개)
    final today = await widget.moodService.getTodayResponses(widget.subjectId, forGuardian: true);
    final last7 = await widget.moodService.getLast7DaysResponses(widget.subjectId, forGuardian: true);
    final streak = await widget.moodService.getStreak(widget.subjectId);
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
        _currentStreak = streak?.currentStreak ?? 0;
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

        // 오늘 기록 ✅ / 오늘은 아직 기록이 없습니다 (공포 유도 금지)
        final String statusText;
        if (_todayResponses == null) {
          statusText = '기록 정보를 불러오는 중입니다.';
        } else if (hasRespondedToday) {
          statusText = '오늘 확인 완료 ✅';
        } else {
          statusText = '오늘은 아직 기록이 없습니다.';
        }

        final statusColor = hasRespondedToday
            ? Colors.green.shade700
            : Colors.grey.shade700;

        // 최근 기록: 년월일 시간 / 없음
        final String dateText;
        if (_latestAnsweredAt == null) {
          dateText = '최근 기록: 없음';
        } else {
          dateText = '최근 기록: ${DateFormat('yyyy년 M월 d일 HH:mm', 'ko_KR').format(_latestAnsweredAt!)}';
        }

        return FutureBuilder<bool>(
          future: _isStillPairedFuture,
          builder: (context, pairedSnapshot) {
            final isStillPaired = pairedSnapshot.data ?? true;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SubjectStatusBadge(isStillPaired: isStillPaired),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (_subjectPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _subjectPhone,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                          const SizedBox(height: 6),
                          if (_currentStreak >= 1) ...[
                            Text(
                              _currentStreak == 1 ? '오늘 기록했어요' : '$_currentStreak일 연속 기록 중',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          if (!hasRespondedToday) ...[
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onRemove != null)
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 22, color: Colors.grey[600]),
                            tooltip: '보호 대상 삭제',
                            onPressed: () => _showRemoveDialog(context, subjectName),
                          ),
                        const Icon(Icons.chevron_right, size: 32),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            );
          },
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
  String _appVersion = '-';
  ({String phone, DateTime? createdAt, String subscriptionStatus, DateTime? subscriptionExpiry})? _accountInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final enabled = await FCMService.instance.getNotificationSoundEnabled();
    final accountInfo = await authService.getAccountInfo();
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _notificationSoundEnabled = enabled;
        _accountInfo = accountInfo;
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    // 1단계: 탈퇴 안내
    final firstChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '탈퇴하면 데이터는 삭제됩니다.\n\n'
          '• 사용자 정보 삭제\n'
          '• 보호대상자/보호자 연결 해제\n'
          '• 기록 데이터 삭제\n\n'
          '연 결제(12,000원)는 스토어에서 자동 갱신됩니다. '
          '탈퇴만 하면 결제는 멈추지 않습니다. 과금 멈추려면 스토어에서 직접 취소하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('store'),
            child: const Text('과금 멈추러 가기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('continue'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('탈퇴 계속'),
          ),
        ],
      ),
    );
    if (firstChoice == null || firstChoice == 'cancel' || !context.mounted) return;

    if (firstChoice == 'store') {
      await _openSubscriptionManagement();
      return;
    }

    // 2단계: 유료 결제 중이면 한 번 더 확인
    final authService = Provider.of<AuthService>(context, listen: false);
    final accountInfo = await authService.getAccountInfo();
    final isSubscriptionActive = accountInfo.subscriptionStatus == '활성' ||
        accountInfo.subscriptionStatus == '만료 예정';

    if (isSubscriptionActive && context.mounted) {
      final secondChoice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('연 결제가 진행 중입니다'),
          content: const Text(
            '탈퇴해도 결제는 멈추지 않습니다. 계속하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: Text('취소', style: TextStyle(color: Colors.grey.shade700)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('store'),
              child: const Text('과금 멈추러 가기'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('delete'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('탈퇴'),
            ),
          ],
        ),
      );
      if (secondChoice == null || secondChoice == 'cancel' || !context.mounted) return;
      if (secondChoice == 'store') {
        await _openSubscriptionManagement();
        return;
      }
    }

    if (!context.mounted) return;

    var error = await authService.deleteAccount();
    if (!context.mounted) return;

    if (error == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    if (error == 'REQUIRES_REAUTH') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호를 전송 중입니다...')),
      );
      final verificationId = await authService.sendReauthOTP();
      if (!context.mounted) return;
      if (verificationId == null || verificationId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호 전송에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증번호를 전송했습니다. 6자리를 입력해 주세요.')),
      );

      final smsCode = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('본인 인증'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '인증번호 6자리',
                counterText: '',
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      if (smsCode == null || smsCode.length != 6 || !context.mounted) return;

      error = await authService.reauthenticateAndDeleteAccount(verificationId, smsCode);
      if (!context.mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
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
                // [ 계정 정보 ]
                _buildSettingsSectionHeader('계정 정보'),
                _buildAccountInfoCard(),
                const SizedBox(height: 24),
                // [ 결제 ]
                _buildSettingsSectionHeader('결제'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_card_outlined),
                    title: const Text('스토어에서 결제 취소'),
                    subtitle: const Text('연 12,000원 자동 갱신. 취소는 스토어에서 직접'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openSubscriptionManagement(),
                  ),
                ),
                const SizedBox(height: 24),
                // [ 알림 설정 ]
                _buildSettingsSectionHeader('알림 설정'),
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
                const SizedBox(height: 24),
                // [ 고객지원 ]
                _buildSettingsSectionHeader('고객지원'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.contact_support_outlined),
                        title: const Text('1:1 문의'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final uid = Provider.of<AuthService>(context, listen: false).user?.uid;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InquiryScreen(userId: uid),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('이용약관'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => LegalDialog.showTerms(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('개인정보처리방침'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => LegalDialog.showPrivacy(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code_outlined),
                        title: const Text('오픈소스 라이선스'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: '지금 어때',
                          applicationVersion: _appVersion,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('버전 정보'),
                        trailing: Text(_appVersion, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // [ 계정 관리 ]
                _buildSettingsSectionHeader('계정 관리'),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                    title: Text(
                      '회원 탈퇴',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('계정 및 모든 데이터가 영구적으로 삭제됩니다'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAccountInfoCard() {
    final info = _accountInfo;
    if (info == null) return const Card(child: ListTile(title: Text('계정 정보를 불러오는 중...')));
    final dateFormat = DateFormat('yyyy.MM.dd');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountInfoRow(Icons.phone_outlined, '휴대폰 번호', AuthService.formatPhoneForDisplay(info.phone)),
            const Divider(height: 24),
            _buildAccountInfoRow(
              Icons.calendar_today_outlined,
              '가입일',
              info.createdAt != null ? dateFormat.format(info.createdAt!) : '-',
            ),
            const Divider(height: 24),
            _buildAccountInfoRow(
              Icons.credit_card_outlined,
              '결제 상태',
              info.subscriptionStatus,
            ),
            const Divider(height: 24),
            _buildAccountInfoRow(
              Icons.event_outlined,
              '다음 결제일',
              info.subscriptionExpiry != null ? dateFormat.format(info.subscriptionExpiry!) : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _openSubscriptionManagement() async {
    String url;
    try {
      if (Platform.isIOS) {
        url = 'https://apps.apple.com/account/subscriptions';
      } else if (Platform.isAndroid) {
        url = 'https://play.google.com/store/account/subscriptions';
      } else {
        url = 'https://play.google.com/store/account/subscriptions';
      }
    } catch (_) {
      url = 'https://play.google.com/store/account/subscriptions';
    }
    await _launchSettingsUrl(url);
  }

  Future<void> _launchSettingsUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

}
