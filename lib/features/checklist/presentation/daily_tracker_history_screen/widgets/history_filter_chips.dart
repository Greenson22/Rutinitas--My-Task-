import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum HistoryFilterPreset {
  thisMonth,
  last7Days,
  last30Days,
  custom,
}

class HistoryFilterChips extends StatelessWidget {
  final HistoryFilterPreset selected;
  final DateTimeRange? customRange;
  final void Function(HistoryFilterPreset preset) onPresetChanged;
  final void Function(DateTimeRange range) onCustomRangeChanged;

  const HistoryFilterChips({
    super.key,
    required this.selected,
    this.customRange,
    required this.onPresetChanged,
    required this.onCustomRangeChanged,
  });

  String _formatCustomRangeLabel(DateTimeRange range) {
    final start = range.start;
    final end = range.end;

    final startMonth = DateFormat('MMM').format(start);
    final endMonth = DateFormat('MMM').format(end);

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}–${end.day} $startMonth';
    } else {
      return '${start.day} $startMonth – ${end.day} $endMonth';
    }
  }

  Future<void> _handleCustomRangeTap(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.teal,
                  onPrimary: Colors.white,
                ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      onCustomRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customLabel = customRange != null
        ? _formatCustomRangeLabel(customRange!)
        : 'Custom Range';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            context: context,
            label: 'Bulan Ini',
            preset: HistoryFilterPreset.thisMonth,
            isSelected: selected == HistoryFilterPreset.thisMonth,
            onSelected: () => onPresetChanged(HistoryFilterPreset.thisMonth),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: '7 Hari',
            preset: HistoryFilterPreset.last7Days,
            isSelected: selected == HistoryFilterPreset.last7Days,
            onSelected: () => onPresetChanged(HistoryFilterPreset.last7Days),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: '30 Hari',
            preset: HistoryFilterPreset.last30Days,
            isSelected: selected == HistoryFilterPreset.last30Days,
            onSelected: () => onPresetChanged(HistoryFilterPreset.last30Days),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context: context,
            label: customLabel,
            preset: HistoryFilterPreset.custom,
            isSelected: selected == HistoryFilterPreset.custom,
            onSelected: () => _handleCustomRangeTap(context),
            icon: Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required HistoryFilterPreset preset,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
  }) {
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      label: Text(label),
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.teal,
            )
          : null,
      selectedColor: Colors.teal,
      backgroundColor: Colors.teal.shade50,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.teal.shade900,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? Colors.teal : Colors.teal.shade200,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
