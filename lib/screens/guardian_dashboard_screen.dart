import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import 'no_response_screen.dart';

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
                          final subjectId =
                              await _guardianService.addMeAsGuardianToSubject(
                            subjectPhone: phoneController.text.trim(),
                            guardianUid: userId,
                            guardianPhone: authService.userModel?.phone ??
                                authService.user?.phoneNumber ??
                                '',
                            guardianDisplayName:
                                authService.userModel?.displayName,
                          );
                          final name = nameController.text.trim();
                          if (name.isNotEmpty && ctx.mounted) {
                            await _guardianService
                                .setSubjectDisplayNameByGuardian(
                              guardianUid: userId,
                              subjectId: subjectId,
                              displayName: name,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() => isAdding = false);
                            final msg =
                                e.toString().replaceFirst('Exception: ', '');
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
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
      _subjectIdsFuture = _guardianService.getSubjectIdsForGuardian(userId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('보호자 확인'),
        leadingWidth: 72,
        leading: Center(
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_ios_new, size: 20),
                    const SizedBox(width: 4),
                    const Text('뒤로', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<String>>(
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
                  TextButton.icon(
                    onPressed: () => _showAddSubjectDialog(context, userId),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: const Text('보호 대상 추가'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...subjectIds.map((subjectId) {
              return _SubjectStatusCard(
                subjectId: subjectId,
                guardianUid: userId,
                guardianService: _guardianService,
                moodService: _moodService,
                onNoResponseTap: (name, slot) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NoResponseScreen(
                        subjectName: name,
                        subjectId: subjectId,
                        slot: slot,
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
    );
  }
}

class _SubjectStatusCard extends StatefulWidget {
  final String subjectId;
  final String guardianUid;
  final GuardianService guardianService;
  final MoodService moodService;
  final void Function(String subjectName, TimeSlot slot) onNoResponseTap;

  const _SubjectStatusCard({
    required this.subjectId,
    required this.guardianUid,
    required this.guardianService,
    required this.moodService,
    required this.onNoResponseTap,
  });

  @override
  State<_SubjectStatusCard> createState() => _SubjectStatusCardState();
}

class _SubjectStatusCardState extends State<_SubjectStatusCard> {
  String _subjectName = '…';
  Map<TimeSlot, MoodResponseModel?>? _responses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await widget.guardianService.getSubjectDisplayNameForGuardian(
      widget.subjectId,
      widget.guardianUid,
    );
    final responses =
        await widget.moodService.getTodayResponses(widget.subjectId);
    if (mounted) {
      setState(() {
        _subjectName = name;
        _responses = responses;
      });
    }
  }

  Future<void> _showSetNameDialog(BuildContext context) async {
    final controller = TextEditingController(text: _subjectName);
    final focusNode = FocusNode();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            focusNode.requestFocus();
          } catch (_) {}
        });
        return AlertDialog(
          title: const Text('보호 대상 이름'),
          content: SizedBox(
            width: 320,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: '이름(별칭)',
                hintText: '예: 엄마, 아빠 (PC에서 직접 입력)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) {
                final n = v.trim();
                Navigator.pop(ctx, n.isEmpty ? null : n);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final n = controller.text.trim();
                Navigator.pop(ctx, n.isEmpty ? null : n);
              },
              style: AppButtonStyles.primaryFilled,
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    focusNode.dispose();
    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        await widget.guardianService.setSubjectDisplayNameByGuardian(
          guardianUid: widget.guardianUid,
          subjectId: widget.subjectId,
          displayName: newName,
        );
        if (mounted) {
          setState(() => _subjectName = newName);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이름이 저장되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_responses == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          title: Text(_subjectName),
          trailing: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _subjectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  onPressed: () => _showSetNameDialog(context),
                  tooltip: '이름 설정',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: TimeSlot.values.map((slot) {
                final response = _responses![slot];
                final hasResponse = response != null;
                final isNoResponse = !hasResponse;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: isNoResponse
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: isNoResponse
                            ? () => widget.onNoResponseTap(_subjectName, slot)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slot.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasResponse
                                    ? response!.mood.emoji
                                    : '—',
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                hasResponse
                                    ? '응답함'
                                    : '회신 없음',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isNoResponse
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
