import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/guardian_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../utils/constants.dart';
import '../widgets/status_display_widgets.dart';
import 'no_response_screen.dart';
import 'guardian_dashboard_screen.dart';

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
  String? _guardianPairedAt; // 보호자 연결일 (yyyy-MM-dd), null이면 전체 표시(기존 호환)
  late final Stream<String> _nameStream;

  @override
  void initState() {
    super.initState();
    _loadResponses();
    _loadFallbackName();
    _loadGuardianPairedAtAndHistory();
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
    // 보호자용: note 필드 제외
    final responses =
        await widget.moodService.getTodayResponses(widget.subjectId, excludeNote: true);
    if (mounted) {
      setState(() {
        _responses = responses;
      });
    }
  }

  Future<void> _loadGuardianPairedAtAndHistory() async {
    final pairedAt = await widget.guardianService.getGuardianPairedAt(
      widget.subjectId,
      widget.guardianUid,
    );
    // 연결일(pairedAt) 이후만 조회 → 연결 전 날짜에 "기록 없음"이 보이는 오해 방지
    final history = await widget.moodService.getResponsesFromDate(
      widget.subjectId,
      fromDateStr: pairedAt,
      maxDays: 7,
      excludeNote: true,
    );
    if (mounted) {
      setState(() {
        _guardianPairedAt = pairedAt;
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
        title: const Text('전달된 안부'),
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
        ],
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
                // 대상 이름
                Text(
                  subjectName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // 오늘 기록 상태 (최상단 강조 영역)
                TodayStatusWidget(
                  responses: _responses,
                  onNoResponseTap: (slot) =>
                      _handleNoResponseTap(subjectName, slot),
                  noResponseSubjectName: subjectName,
                  isGuardianView: true,
                ),
                // 최근 7일 기록 그래프
                if (_historyResponses != null &&
                    _historyResponses!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  StatusHistoryTable(
                    historyResponses: _historyResponses,
                    isGuardianView: true,
                  ),
                ],
                const SizedBox(height: 32),
                // 안내 박스 (하단 보조 영역)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '최근 안부가 기록되었는지만 확인할 수 있어요.\n자세한 내용은 공유되지 않습니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
