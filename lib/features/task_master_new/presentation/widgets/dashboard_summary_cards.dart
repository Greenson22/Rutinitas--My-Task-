import 'package:flutter/material.dart';

/// Empat kartu ringkasan dashboard: kategori aktif, tugas aktif, target
/// tercapai hari ini, dan durasi Jurnal hari ini.
class DashboardSummaryCards extends StatelessWidget {
  const DashboardSummaryCards({
    super.key,
    required this.activeCategoryCount,
    required this.activeTaskCount,
    required this.completedTargetsToday,
    required this.journalMinutesToday,
  });

  final int activeCategoryCount;
  final int activeTaskCount;
  final int completedTargetsToday;
  final int journalMinutesToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryStatCard(
                cardKey: const Key('summaryActiveCategories'),
                icon: Icons.category_outlined,
                label: 'Kategori aktif',
                value: '$activeCategoryCount',
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryStatCard(
                cardKey: const Key('summaryActiveTasks'),
                icon: Icons.checklist_rounded,
                label: 'Tugas aktif',
                value: '$activeTaskCount',
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryStatCard(
                cardKey: const Key('summaryCompletedTargets'),
                icon: Icons.flag_rounded,
                label: 'Target tercapai',
                value: '$completedTargetsToday',
                color: Colors.orange[800]!,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryStatCard(
                cardKey: const Key('summaryJournalMinutes'),
                icon: Icons.schedule_rounded,
                label: 'Jurnal hari ini',
                value: formatMinutes(journalMinutesToday),
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Memformat menit menjadi teks ringkas berbahasa Indonesia.
String formatMinutes(int minutes) {
  if (minutes <= 0) return '0 mnt';
  if (minutes < 60) return '$minutes mnt';

  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) return '$hours jam';
  return '$hours jam $remaining mnt';
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.cardKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final Key cardKey;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
