import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../services/mood_service.dart';
import '../services/fcm_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import '../utils/constants.dart';
import '../main.dart';
import 'subject_detail_screen.dart';
import 'auth_screen.dart';

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

  void _refreshList(String userId) {
    setState(() {
      _subjectIdsFuture = _guardianService.getSubjectIdsForGuardian(userId);
    });
  }

  Future<void> _showAddSubjectDialog(BuildContext context, String userId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isAdding = false;
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('보호 대상 추가'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이름(별칭)과 전화번호를 입력하세요. 본인 번호는 추가할 수 없습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '이름(별칭)',
                        hintText: '예: 엄마, 아빠 (선택)',
                      ),
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: '보호 대상 전화번호',
                        hintText: '01012345678',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '전화번호를 입력하세요.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isAdding ? null : () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: isAdding
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isAdding = true);
                        try {
                          final subjectId = await _guardianService
                              .addMeAsGuardianToSubject(
                            subjectPhone: phoneController.text.trim(),
                            guardianUid: userId,
                            guardianPhone: authService.userModel?.phone ??
                                authService.user?.phoneNumber ??
                                '',
                            guardianDisplayName:
                                authService.userModel?.displayName,
                          ).timeout(
                            const Duration(seconds: 15),
                            onTimeout: () => throw TimeoutException(
                              '요청이 지연되고 있습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.',
                            ),
                          );
                          final name = nameController.text.trim();
                          if (name.isNotEmpty && ctx.mounted) {
                            await _guardianService
                                .setSubjectDisplayNameByGuardian(
                              guardianUid: userId,
                              subjectId: subjectId,
                              displayName: name,
                            ).timeout(
                              const Duration(seconds: 10),
                              onTimeout: () {},
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e, stack) {
                          if (ctx.mounted) {
                            setDialogState(() => isAdding = false);
                            debugPrint('보호대상자 추가 오류: $e');
                            debugPrint('$stack');
                            if (e is NoSubjectUserException) {
                              await showDialog<void>(
                                context: ctx,
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
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('등록에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        }
                      },
                style: AppButtonStyles.primaryFilled,
                child: isAdding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('추가'),
              ),
            ],
          );
        },
      ),
    );
    if (added == true && mounted) {
      _refreshList(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보호 대상이 추가되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('보호자 확인')),
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
        title: const Text('보호자 확인'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leadingWidth: 80,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
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
      body: Column(
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '등록된 보호 대상이 없습니다.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _showAddSubjectDialog(context, userId),
                            icon: const Icon(Icons.person_add, size: 22),
                            label: const Text('보호 대상 추가'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 보호 대상이 1명 이상이면 목록 표시 (선택 시 상세 화면으로 이동)
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '보호 대상 (${subjectIds.length}명)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showAddSubjectDialog(context, userId),
                          icon: const Icon(Icons.person_add, size: 22),
                          label: const Text('보호 대상 추가'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
                );
              },
            ),
          ),
        ],
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
    final today = await widget.moodService.getTodayResponses(widget.subjectId);
    final last7 = await widget.moodService.getLast7DaysResponses(widget.subjectId);
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
        final hasRespondedToday = _todayResponses?.values.any((r) => r != null) ?? false;
        final subtitleText = _todayResponses == null
            ? '로딩 중...'
            : _latestAnsweredAt == null
                ? '최근 응답: 없음'
                : '최근 응답: ${DateFormat('yyyy년 M월 d일 H시 m분', 'ko_KR').format(_latestAnsweredAt!)}';
        final subtitleColor = hasRespondedToday
            ? Colors.green.shade700
            : Colors.grey.shade700;

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
            subtitle: Text(
              subtitleText,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
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
          onTap: () => Navigator.of(context).pop(),
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
                    subtitle: const Text('보호 대상 상태 알림 소리 재생'),
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
