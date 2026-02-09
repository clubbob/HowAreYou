import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_response_model.dart';
import 'mood_face_icon.dart';

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
          children: TimeSlot.displaySlots.map((slot) {
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            hasResponse
                                ? MoodFaceIcon(
                                    mood: response!.mood.displayAsSelectable,
                                    size: 40,
                                    withShadow: false,
                                  )
                                : const Text(
                                    '—',
                                    style: TextStyle(fontSize: 32),
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              hasResponse
                                  ? response!.mood.displayAsSelectable.label
                                  : '없음',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: hasResponse
                                    ? response!.mood.displayAsSelectable.color
                                    : Colors.grey.shade600,
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

      // 2가지 상태로 집계: 괜찮아(좋아+괜찮아+보통), 별로(별로+힘들어)
      int okayCount = 0;
      int notGoodCount = 0;

      for (final response in dayResponses.values) {
        if (response != null) {
          switch (response.mood.displayAsSelectable) {
            case Mood.okay:
              okayCount++;
              break;
            case Mood.notGood:
              notGoodCount++;
              break;
            default:
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
              toY: okayCount.toDouble(),
              color: Colors.lightGreen,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: notGoodCount.toDouble(),
              color: Colors.deepOrange,
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                    final moodLabels = ['괜찮아', '별로'];
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
                      if (value.toInt() >= 0 && value.toInt() <= 10) {
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: const [
            _LegendItem(label: '괜찮아', color: Colors.lightGreen),
            _LegendItem(label: '별로', color: Colors.deepOrange),
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

/// 최근 7일 이력 그래프 위젯 (날짜별 상태를 막대 색으로 표시)
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

    final sortedEntries = historyResponses!.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final dateLabels = <String>[];
    final barColors = <Color>[];
    for (final entry in sortedEntries) {
      DateTime date;
      try {
        date = DateFormat('yyyy-MM-dd').parse(entry.key);
      } catch (_) {
        date = DateTime.now();
      }
      dateLabels.add(DateFormat('M/d', 'ko_KR').format(date));
      final dayResponses = entry.value;
      MoodResponseModel? response;
      for (final r in dayResponses.values) {
        if (r != null) {
          response = r;
          break;
        }
      }
      if (response == null) {
        barColors.add(Colors.grey.shade300);
      } else {
        final m = response.mood.displayAsSelectable;
        barColors.add(m == Mood.okay
            ? Colors.lightGreen
            : m == Mood.normal
                ? const Color(0xFFD4C4B0)
                : Colors.deepOrange);
      }
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
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.2,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < dateLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dateLabels[value.toInt()],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              barGroups: List.generate(
                sortedEntries.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: 1,
                      color: barColors[i],
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                  showingTooltipIndicators: [],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 4,
          children: [
            _LegendItem(label: '괜찮아', color: Colors.lightGreen),
            _LegendItem(label: '보통', color: Color(0xFFD4C4B0)),
            _LegendItem(label: '별로', color: Colors.deepOrange),
            _LegendItem(label: '없음', color: Colors.grey),
          ],
        ),
      ],
    );
  }
}
