import 'package:flutter/material.dart';
import '../../../data/models/daily_model.dart';
import '../../../utils/item_color_helper.dart';

/// Menampilkan legenda warna untuk item checklist yang selesai pada rentang
/// tanggal aktif di [DailyTrackerHistoryScreen].
class HistoryColorLegend extends StatelessWidget {
  final List<String> dateKeys;
  final Map<String, List<DailyLogEntry>> dailyLogs;

  const HistoryColorLegend({
    super.key,
    required this.dateKeys,
    required this.dailyLogs,
  });

  List<String> _collectCompletedItemNames() {
    final names = <String>{};

    void collectFromEntries(List<DailyLogEntry> entries) {
      for (final entry in entries) {
        if (entry.progress == 'selesai') {
          names.add(entry.itemName);
        }
        if (entry.children.isNotEmpty) {
          collectFromEntries(entry.children);
        }
      }
    }

    for (final key in dateKeys) {
      final entries = dailyLogs[key];
      if (entries != null) {
        collectFromEntries(entries);
      }
    }

    final sorted = names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final itemNames = _collectCompletedItemNames();
    if (itemNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Keterangan Warna',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: itemNames.map((name) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: Key('legend_color_$name'),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorFromItemName(name),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
