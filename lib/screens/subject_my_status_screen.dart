import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mood_service.dart';
import '../services/auth_service.dart';
import '../services/guardian_service.dart';
import '../models/mood_response_model.dart';
import '../widgets/status_display_widgets.dart';
import '../main.dart';
import 'auth_screen.dart';

/// 보호 대상자 자신의 상태 이력 화면
class SubjectMyStatusScreen extends StatefulWidget {
  final String subjectId;

  const SubjectMyStatusScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<SubjectMyStatusScreen> createState() => _SubjectMyStatusScreenState();
}

class _SubjectMyStatusScreenState extends State<SubjectMyStatusScreen> {
  final MoodService _moodService = MoodService();
  final GuardianService _guardianService = GuardianService();
  Map<TimeSlot, MoodResponseModel?>? _todayResponses;
  Map<String, Map<TimeSlot, MoodResponseModel?>>? _historyResponses;
  bool _isLoading = true;
  bool _hasGuardian = false;
  bool _showExtendedHistory = false; // 30일 확장 여부

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildSummaryText(Map<String, Map<TimeSlot, MoodResponseModel?>> historyResponses) {
    // 기록 여부 요약 (7일 또는 30일)
    final dayCount = historyResponses.length;
    final dayLabel = dayCount == 30 ? '30일' : '7일';

    int totalDaysWithRecord = 0;
    for (final dayResponses in historyResponses.values) {
      final hasRecord = dayResponses.values.any((response) => response != null);
      if (hasRecord) {
        totalDaysWithRecord++;
      }
    }

    String summaryText;
    if (totalDaysWithRecord == 0) {
      summaryText = '최근 $dayLabel 동안 남겨진 기록이 아직 없어요.';
    } else {
      summaryText = '최근 $dayLabel 동안 기록이 있었습니다.';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summaryText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData({bool loadExtended = false}) async {
    setState(() => _isLoading = true);
    
    // 보호자 지정 여부 확인
    final hasGuardian = await _guardianService.hasGuardian(widget.subjectId);
    
    // 보호자가 지정되어 있을 때만 상태 데이터 로드
    if (hasGuardian) {
      final today = await _moodService.getTodayResponses(widget.subjectId);
      final history = loadExtended || _showExtendedHistory
          ? await _moodService.getLast30DaysResponses(widget.subjectId)
          : await _moodService.getLast7DaysResponses(widget.subjectId);
      if (mounted) {
        setState(() {
          _todayResponses = today;
          _historyResponses = history;
          _hasGuardian = true;
          _isLoading = false;
          if (loadExtended) {
            _showExtendedHistory = true;
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasGuardian = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExtendedHistory() async {
    if (_showExtendedHistory) return; // 이미 확장된 경우 스킵
    
    setState(() => _isLoading = true);
    final history = await _moodService.getLast30DaysResponses(widget.subjectId);
    if (mounted) {
      setState(() {
        _historyResponses = history;
        _showExtendedHistory = true;
        _isLoading = false;
      });
    }
  }

  Widget _buildRecordInfoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.grey.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _showExtendedHistory 
                  ? '이 화면에서 최근 30일 기록을 확인할 수 있습니다.'
                  : '이 화면에서 최근 7일 기록을 확인할 수 있습니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('최근 컨디션'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasGuardian
              ? RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 기록 회수 가능성 안내
                        _buildRecordInfoBanner(),
                        // 오늘 상태
                        TodayStatusWidget(responses: _todayResponses),
                        // 최근 이력 그래프
                        if (_historyResponses != null &&
                            _historyResponses!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSummaryText(_historyResponses!),
                          const SizedBox(height: 12),
                          StatusHistoryTable(historyResponses: _historyResponses),
                          // 더 보기 버튼 (7일만 보여줄 때만 표시)
                          if (!_showExtendedHistory && _historyResponses!.length == 7) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _loadExtendedHistory,
                                icon: const Icon(Icons.expand_more, size: 18),
                                label: const Text('더 보기 (최근 30일)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF5C6BC0),
                                  side: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '보호자가 지정되지 않았습니다',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '안부를 전달하려면 먼저 보호자를 지정해주세요.\n\n보호 대상자 모드에서 "보호자 지정" 메뉴를 이용해주세요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
