import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';

/// 메모 상세 보기 화면 (1주일 단위 표시)
class MemoDetailScreen extends StatefulWidget {
  final String subjectId;
  final String? initialDate; // 초기 표시할 날짜 (선택)

  const MemoDetailScreen({
    super.key,
    required this.subjectId,
    this.initialDate,
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  final MoodService _moodService = MoodService();
  Map<String, Map<TimeSlot, MoodResponseModel?>>? _allResponses;
  bool _isLoading = true;
  int _currentWeekOffset = 0; // 현재 표시 중인 주차 (0 = 최근 1주일)

  @override
  void initState() {
    super.initState();
    _loadAllMemos();
  }

  Future<void> _loadAllMemos() async {
    setState(() => _isLoading = true);
    
    // 최대 30일치 데이터 로드 (약 4주)
    final responses = await _moodService.getLast30DaysResponses(widget.subjectId);
    
    if (mounted) {
      setState(() {
        _allResponses = responses;
        _isLoading = false;
        
        // initialDate가 있으면 해당 주차로 이동
        if (widget.initialDate != null) {
          _currentWeekOffset = _getWeekOffsetForDate(widget.initialDate!);
        }
      });
    }
  }

  /// 특정 날짜가 속한 주차 계산 (0 = 최근 1주일)
  int _getWeekOffsetForDate(String dateStr) {
    if (_allResponses == null) return 0;
    
    final dates = _allResponses!.keys.toList()..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    
    try {
      final targetDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      for (int i = 0; i < dates.length; i += 7) {
        final weekStartDate = DateFormat('yyyy-MM-dd').parse(dates[i]);
        final weekEndDate = weekStartDate.add(const Duration(days: 6));
        
        if (targetDate.isAfter(weekEndDate.subtract(const Duration(milliseconds: 1))) &&
            targetDate.isBefore(weekStartDate.add(const Duration(days: 1)))) {
          return i ~/ 7;
        }
      }
    } catch (_) {}
    
    return 0;
  }

  /// 현재 주차의 메모 목록 가져오기
  List<MapEntry<String, String>> _getCurrentWeekMemos() {
    if (_allResponses == null) return [];
    
    // 날짜 내림차순 정렬
    final dates = _allResponses!.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // 현재 주차 범위 계산 (7일씩)
    final startIndex = _currentWeekOffset * 7;
    final endIndex = (startIndex + 7).clamp(0, dates.length);
    final weekDates = dates.sublist(startIndex, endIndex);
    
    // 메모가 있는 날짜만 필터링
    final memos = <MapEntry<String, String>>[];
    
    for (final dateStr in weekDates) {
      final dayResponses = _allResponses![dateStr];
      if (dayResponses == null) continue;
      
      for (final response in dayResponses.values) {
        if (response != null && response.note != null && response.note!.trim().isNotEmpty) {
          memos.add(MapEntry(dateStr, response.note!));
          break; // 하루에 하나만 추가
        }
      }
    }
    
    return memos;
  }

  /// 총 주차 수 계산
  int _getTotalWeeks() {
    if (_allResponses == null || _allResponses!.isEmpty) return 1;
    return ((_allResponses!.length - 1) ~/ 7) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메모'),
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
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final weekMemos = _getCurrentWeekMemos();
    final totalWeeks = _getTotalWeeks();
    
    if (weekMemos.isEmpty && _currentWeekOffset == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '메모가 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // 주차 네비게이션
        if (totalWeeks > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentWeekOffset < totalWeeks - 1
                      ? () {
                          setState(() {
                            _currentWeekOffset++;
                          });
                        }
                      : null,
                  color: _currentWeekOffset < totalWeeks - 1
                      ? Colors.blue
                      : Colors.grey,
                ),
                Text(
                  '${_currentWeekOffset + 1}주 전',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentWeekOffset > 0
                      ? () {
                          setState(() {
                            _currentWeekOffset--;
                          });
                        }
                      : null,
                  color: _currentWeekOffset > 0 ? Colors.blue : Colors.grey,
                ),
              ],
            ),
          ),
        // 메모 리스트
        Expanded(
          child: weekMemos.isEmpty
              ? Center(
                  child: Text(
                    '이 주에는 메모가 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: weekMemos.length,
                  itemBuilder: (context, index) {
                    final entry = weekMemos[index];
                    final dateStr = entry.key;
                    final memo = entry.value;
                    
                    // 날짜 파싱 및 포맷팅
                    DateTime? date;
                    try {
                      date = DateFormat('yyyy-MM-dd').parse(dateStr);
                    } catch (_) {
                      date = null;
                    }
                    
                    final formattedDate = date != null
                        ? DateFormat('M월 d일 (E)', 'ko_KR').format(date)
                        : dateStr;
                    
                    // 해당 날짜의 mood 찾기
                    Mood? mood;
                    final dayResponses = _allResponses![dateStr];
                    if (dayResponses != null) {
                      for (final response in dayResponses.values) {
                        if (response != null) {
                          mood = response.mood;
                          break;
                        }
                      }
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 날짜와 감정
                            Row(
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                if (mood != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    mood.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    mood.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 메모 내용 (전체 표시)
                            Text(
                              memo,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade800,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
