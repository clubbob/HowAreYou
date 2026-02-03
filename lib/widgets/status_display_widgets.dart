import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_response_model.dart';

/// 오늘 상태 표시 위젯 (보호자/보호대상자 공통)
class TodayStatusWidget extends StatelessWidget {
  final Map<TimeSlot, MoodResponseModel?>? responses;
  final void Function(TimeSlot)? onNoResponseTap;
  final String? noResponseSubjectName;

  const TodayStatusWidget({
    super.key,
    required this.responses,
    this.onNoResponseTap,
    this.noResponseSubjectName,
  });

  @override
  Widget build(BuildContext context) {
    if (responses == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final response = responses![slot];
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
                    onTap: isNoResponse && onNoResponseTap != null
                        ? () => onNoResponseTap!(slot)
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
                          hasResponse
                              ? response!.mood.buildColoredIcon(size: 40)
                              : const Text(
                                  '—',
                                  style: TextStyle(fontSize: 32),
                                ),
                          Text(
                            hasResponse ? '응답함' : '회신 없음',
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
    );
  }
}

/// 최근 7일 상태 추이 그래프 위젯 (보호자/보호대상자 공통)
class StatusTrendChart extends StatelessWidget {
  final Map<String, Map<TimeSlot, MoodResponseModel?>>? historyResponses;

  const StatusTrendChart({
    super.key,
    required this.historyResponses,
  });

  @override
  Widget build(BuildContext context) {
    if (historyResponses == null || historyResponses!.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = historyResponses!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final chartData = <BarChartGroupData>[];
    final xLabels = <String>[];
    int index = 0;

    for (final entry in sortedEntries) {
      final dateStr = entry.key;
      final dayResponses = entry.value;

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

      chartData.add(
        BarChartGroupData(
          x: index,
          groupVertically: false,
          barRods: [
            BarChartRodData(
              toY: goodCount.toDouble(),
              color: Colors.green,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: normalCount.toDouble(),
              color: Colors.orange,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
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

    if (chartData.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY = chartData
        .map((group) => group.barRods
            .map((rod) => rod.toY)
            .reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Container(
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
              maxY: maxY > 0 ? maxY + 0.5 : 3,
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
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(label: '좋아', color: Colors.green),
            const SizedBox(width: 16),
            _LegendItem(label: '보통', color: Colors.orange),
            const SizedBox(width: 16),
            _LegendItem(label: '안좋아', color: Colors.red),
          ],
        ),
      ],
    );
  }
}

/// 범례 아이템 위젯
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// 최근 7일 이력 테이블 위젯 (보호자/보호대상자 공통)
class StatusHistoryTable extends StatelessWidget {
  final Map<String, Map<TimeSlot, MoodResponseModel?>>? historyResponses;

  const StatusHistoryTable({
    super.key,
    required this.historyResponses,
  });

  @override
  Widget build(BuildContext context) {
    if (historyResponses == null || historyResponses!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        // 테이블 데이터
        ...historyResponses!.entries.map((entry) {
          final dateStr = entry.key;
          final dayResponses = entry.value;
          DateTime date;
          try {
            date = DateFormat('yyyy-MM-dd').parse(dateStr);
          } catch (_) {
            date = DateTime.now();
          }
          final dateLabel = DateFormat('M/d (E)', 'ko_KR').format(date);
          final isToday = dateStr ==
              DateFormat('yyyy-MM-dd').format(DateTime.now());
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
                              color: hasR
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: hasR
                                ? Center(
                                    child: r!.mood.buildColoredIcon(size: 28),
                                  )
                                : const Text(
                                    '—',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 24),
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
        }).toList(),
      ],
    );
  }
}
