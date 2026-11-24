import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/daily_model.dart';
import '../../../utils/item_color_helper.dart';

class HistoryBarChart extends StatelessWidget {
  final List<String> dateKeys; // sorted ascending, 'yyyy-MM-dd'
  final Map<String, List<DailyLogEntry>> dailyLogs;
  final double Function(List<DailyLogEntry>) countTotal;
  final double Function(List<DailyLogEntry>) countFinished;

  const HistoryBarChart({
    super.key,
    required this.dateKeys,
    required this.dailyLogs,
    required this.countTotal,
    required this.countFinished,
  });

  String _formatBottomTitle(String dateKey, bool showMonth) {
    try {
      final parsed = DateTime.parse(dateKey);
      if (showMonth) {
        return '${parsed.day}/${parsed.month}';
      }
      return '${parsed.day}';
    } catch (_) {
      return dateKey;
    }
  }

  String _formatTooltipDate(String dateKey) {
    try {
      final parsed = DateTime.parse(dateKey);
      return DateFormat('d MMM').format(parsed);
    } catch (_) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dateKeys.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded, size: 36, color: Colors.grey.shade400),
              const SizedBox(height: 6),
              Text(
                'Tidak ada data untuk grafik pada rentang ini',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool showMonth = dateKeys.length > 14;

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < dateKeys.length; i++) {
      final key = dateKeys[i];
      final entries = dailyLogs[key] ?? [];
      final total = countTotal(entries);
      final finished = countFinished(entries);
      final double percentage = total > 0 ? (finished / total) * 100 : 0.0;

      final finishedEntries =
          entries.where((e) => e.progress == 'selesai').toList();

      final List<BarChartRodStackItem> stackItems = [];
      if (finishedEntries.isNotEmpty && percentage > 0) {
        final double segmentHeight = percentage / finishedEntries.length;
        double currentY = 0;
        for (final entry in finishedEntries) {
          stackItems.add(
            BarChartRodStackItem(
              currentY,
              currentY + segmentHeight,
              colorFromItemName(entry.itemName),
            ),
          );
          currentY += segmentHeight;
        }
      }

      final bool isZero = stackItems.isEmpty;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: isZero ? 5.0 : percentage,
              color: isZero ? Colors.grey.shade200 : Colors.transparent,
              rodStackItems: stackItems,
              width: dateKeys.length > 20
                  ? 6
                  : dateKeys.length > 10
                      ? 10
                      : 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: Colors.grey.shade100,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= dateKeys.length) return null;
                final dateKey = dateKeys[groupIndex];
                final entries = dailyLogs[dateKey] ?? [];
                final total = countTotal(entries);
                final finished = countFinished(entries);
                final percent = total > 0 ? ((finished / total) * 100).round() : 0;
                final formattedDate = _formatTooltipDate(dateKey);

                final String finishedText = finished % 1 == 0
                    ? finished.toInt().toString()
                    : finished.toStringAsFixed(1);
                final String totalText = total % 1 == 0
                    ? total.toInt().toString()
                    : total.toStringAsFixed(1);

                return BarTooltipItem(
                  '$formattedDate\n$percent%\n($finishedText/$totalText)',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey));
                  } else if (value == 50) {
                    return const Text('50%', style: TextStyle(fontSize: 10, color: Colors.grey));
                  } else if (value == 100) {
                    return const Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dateKeys.length) {
                    return const SizedBox.shrink();
                  }

                  // Hindari tumpang tindih label jika jumlah bar banyak
                  if (dateKeys.length > 20 && index % 3 != 0 && index != dateKeys.length - 1) {
                    return const SizedBox.shrink();
                  } else if (dateKeys.length > 10 && dateKeys.length <= 20 && index % 2 != 0 && index != dateKeys.length - 1) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _formatBottomTitle(dateKeys[index], showMonth),
                      style: const TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }
}
