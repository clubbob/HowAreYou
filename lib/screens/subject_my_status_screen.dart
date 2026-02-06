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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // 보호자 지정 여부 확인
    final hasGuardian = await _guardianService.hasGuardian(widget.subjectId);
    
    // 보호자가 지정되어 있을 때만 상태 데이터 로드
    if (hasGuardian) {
      final today = await _moodService.getTodayResponses(widget.subjectId);
      final history = await _moodService.getLast7DaysResponses(widget.subjectId);
      if (mounted) {
        setState(() {
          _todayResponses = today;
          _historyResponses = history;
          _hasGuardian = true;
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 상태 보기'),
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
                        // 오늘 상태
                        TodayStatusWidget(responses: _todayResponses),
                        // 최근 7일 추이 및 이력
                        if (_historyResponses != null &&
                            _historyResponses!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          StatusTrendChart(historyResponses: _historyResponses),
                          const SizedBox(height: 24),
                          StatusHistoryTable(historyResponses: _historyResponses),
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
                          '상태를 확인하려면 먼저 보호자를 지정해주세요.\n\n보호 대상자 모드에서 "보호자 지정" 메뉴를 이용해주세요.',
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
