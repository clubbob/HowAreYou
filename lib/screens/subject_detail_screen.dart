import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/guardian_service.dart';
import '../services/mood_service.dart';
import '../models/mood_response_model.dart';
import '../utils/button_styles.dart';
import '../utils/constants.dart';
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
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

  Widget _buildTrendChart() {
    if (_historyResponses == null || _historyResponses!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 날짜별 좋아/보통/안좋아 개수 계산
    // 날짜를 정렬하여 오른쪽이 최근 날짜가 되도록 처리
    final sortedEntries = _historyResponses!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // 날짜 오름차순 정렬 (오래된 날짜부터)
    
    final chartData = <BarChartGroupData>[];
    final xLabels = <String>[];
    int index = 0;

    // 정렬된 순서대로 순회 (왼쪽이 오래된 날짜, 오른쪽이 최근 날짜)
    for (final entry in sortedEntries) {
      final dateStr = entry.key;
      final dayResponses = entry.value;
      
      // 각 기분별 개수 계산
      int goodCount = 0;
      int normalCount = 0;
      int badCount = 0;
      
      for (final response in dayResponses.values) {
        if (response != null) {
          switch (response.mood) {
            case Mood.good:
              goodCount++;
              break;
            case Mood.normal:
              normalCount++;
              break;
            case Mood.bad:
              badCount++;
              break;
          }
        }
      }
      
      DateTime date;
      try {
        date = DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (_) {
        date = DateTime.now();
      }
      
      final dateLabel = DateFormat('M/d', 'ko_KR').format(date);
      xLabels.add(dateLabel);
      
      // 각 날짜에 좋아/보통/안좋아 막대를 나란히 표시
      chartData.add(
        BarChartGroupData(
          x: index,
          groupVertically: false,
          barRods: [
            // 좋아 (초록색)
            BarChartRodData(
              toY: goodCount.toDouble(),
              color: Colors.green,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            // 보통 (노란색)
            BarChartRodData(
              toY: normalCount.toDouble(),
              color: Colors.orange,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            // 안좋아 (빨간색)
            BarChartRodData(
              toY: badCount.toDouble(),
              color: Colors.red,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      index++;
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 3,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.grey.shade800,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final moodLabels = ['좋아', '보통', '안좋아'];
                final moodLabel = rodIndex < moodLabels.length 
                    ? moodLabels[rodIndex] 
                    : '';
                return BarTooltipItem(
                  '$moodLabel: ${rod.toY.toInt()}개',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < xLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        xLabels[value.toInt()],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                '응답 개수',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() <= 3) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          barGroups: chartData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보호 대상 상세'),
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
                Text(
                  '오늘 상태',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
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
                                ? () => _handleNoResponseTap(subjectName, slot)
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
                                    style: const TextStyle(fontSize: 32),
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
                if (_historyResponses != null && _historyResponses!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    '최근 7일 추세',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '각 날짜별 좋아/보통/안좋아 응답 개수',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTrendChart(),
                  const SizedBox(height: 8),
                  // 범례
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('좋아', Colors.green),
                      const SizedBox(width: 16),
                      _buildLegendItem('보통', Colors.orange),
                      const SizedBox(width: 16),
                      _buildLegendItem('안좋아', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '최근 7일 이력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 테이블 헤더
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            '날짜',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: TimeSlot.values.map((slot) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    slot.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._historyResponses!.entries.map((entry) {
                    final dateStr = entry.key;
                    final dayResponses = entry.value;
                    DateTime date;
                    try {
                      date = DateFormat('yyyy-MM-dd').parse(dateStr);
                    } catch (_) {
                      date = DateTime.now();
                    }
                    final dateLabel = DateFormat('M/d (E)', 'ko_KR').format(date);
                    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: isToday ? Colors.blue.shade700 : Colors.grey[700],
                                fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: TimeSlot.values.map((slot) {
                                final r = dayResponses[slot];
                                final hasR = r != null;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: hasR ? Colors.green.shade50 : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        hasR ? r!.mood.emoji : '—',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
