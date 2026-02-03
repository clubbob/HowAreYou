import 'package:flutter/material.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../widgets/status_display_widgets.dart';

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
  Map<TimeSlot, MoodResponseModel?>? _todayResponses;
  Map<String, Map<TimeSlot, MoodResponseModel?>>? _historyResponses;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final today = await _moodService.getTodayResponses(widget.subjectId);
    final history = await _moodService.getLast7DaysResponses(widget.subjectId);
    if (mounted) {
      setState(() {
        _todayResponses = today;
        _historyResponses = history;
        _isLoading = false;
      });
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
            ),
    );
  }
}
