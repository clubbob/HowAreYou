import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/guardian_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import '../utils/constants.dart';
import '../widgets/status_display_widgets.dart';
import 'no_response_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final String guardianUid;
  final GuardianService guardianService;
  final MoodService moodService;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.guardianUid,
    required this.guardianService,
    required this.moodService,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<TimeSlot, MoodResponseModel?>? _responses;
  Map<String, Map<TimeSlot, MoodResponseModel?>>? _historyResponses;
  String _fallbackName = '이름 없음';
  late final Stream<String> _nameStream;

  @override
  void initState() {
    super.initState();
    _loadResponses();
    _loadHistory();
    _loadFallbackName();
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

  Future<void> _loadResponses() async {
    final responses =
        await widget.moodService.getTodayResponses(widget.subjectId);
    if (mounted) {
      setState(() {
        _responses = responses;
      });
    }
  }

  Future<void> _loadHistory() async {
    final history =
        await widget.moodService.getLast7DaysResponses(widget.subjectId);
    if (mounted) {
      setState(() {
        _historyResponses = history;
      });
    }
  }
  
  Future<void> _loadFallbackName() async {
    final name = await widget.guardianService.getSubjectDisplayName(widget.subjectId);
    if (mounted) {
      setState(() {
        _fallbackName = name;
      });
    }
  }

  Future<void> _showSetNameDialog(BuildContext context) async {
    final currentName = await widget.guardianService.getSubjectDisplayNameForGuardian(
      widget.subjectId,
      widget.guardianUid,
    );
    final initialText = currentName == '이름 없음' ? '' : currentName;
    final controller = TextEditingController(text: initialText);
    final focusNode = FocusNode();
    
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
        
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('보호 대상 이름'),
              content: SizedBox(
                width: 320,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: '이름(별칭)',
                    hintText: '예: 엄마, 아빠',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  autofocus: true,
                  enabled: true,
                  readOnly: false,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    setState(() {});
                  },
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
      },
    );
    
    focusNode.dispose();
    
    await Future.delayed(const Duration(milliseconds: 100));
    controller.dispose();
    
    if (!mounted) return;
    
    if (newName != null && newName.isNotEmpty) {
      try {
        await widget.guardianService.setSubjectDisplayNameByGuardian(
          guardianUid: widget.guardianUid,
          subjectId: widget.subjectId,
          displayName: newName,
        );
        
        if (!mounted) return;
        
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이름이 저장되었습니다.')),
            );
          }
        });
      } catch (e) {
        if (!mounted) return;
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('저장 실패: $e')),
            );
          }
        });
      }
    } else if (newName != null && newName.isEmpty) {
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(widget.guardianUid)
            .update({
          'subjectLabels.${widget.subjectId}': FieldValue.delete(),
        });
        
        if (!mounted) return;
        
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이름이 삭제되었습니다.')),
            );
          }
        });
      } catch (e) {
        if (!mounted) return;
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('삭제 실패: $e')),
            );
          }
        });
      }
    }
  }

  void _handleNoResponseTap(String subjectName, TimeSlot slot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoResponseScreen(
          subjectName: subjectName,
          subjectId: widget.subjectId,
          slot: slot,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보호 대상 상태'),
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
      body: StreamBuilder<String>(
        stream: _nameStream,
        initialData: _fallbackName,
        builder: (context, nameSnapshot) {
          final subjectName = nameSnapshot.data ?? _fallbackName;
          
          if (_responses == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 24,
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
                const SizedBox(height: 16),
                TodayStatusWidget(
                  responses: _responses,
                  onNoResponseTap: (slot) => _handleNoResponseTap(subjectName, slot),
                  noResponseSubjectName: subjectName,
                ),
                if (_historyResponses != null && _historyResponses!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  StatusHistoryTable(historyResponses: _historyResponses),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
