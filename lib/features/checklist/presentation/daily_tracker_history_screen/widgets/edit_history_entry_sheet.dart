import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/daily_model.dart';

class EditHistoryEntrySheet extends StatefulWidget {
  final String dateKey;
  final List<DailyLogEntry> entries;
  final Future<void> Function(List<DailyLogEntry> updated) onSave;

  const EditHistoryEntrySheet({
    super.key,
    required this.dateKey,
    required this.entries,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String dateKey,
    required List<DailyLogEntry> entries,
    required Future<void> Function(List<DailyLogEntry> updated) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditHistoryEntrySheet(
        dateKey: dateKey,
        entries: entries,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditHistoryEntrySheet> createState() => _EditHistoryEntrySheetState();
}

class _EditableEntry {
  final String itemName;
  String progress;
  final String itemType;
  int currentValue;
  final int targetValue;
  final List<_EditableEntry> children;
  late final TextEditingController controller;

  _EditableEntry({
    required this.itemName,
    required this.progress,
    required this.itemType,
    required this.currentValue,
    required this.targetValue,
    required this.children,
  }) {
    controller = TextEditingController(text: currentValue.toString());
  }

  factory _EditableEntry.fromDailyLogEntry(DailyLogEntry entry) {
    return _EditableEntry(
      itemName: entry.itemName,
      progress: entry.progress,
      itemType: entry.itemType,
      currentValue: entry.currentValue,
      targetValue: entry.targetValue,
      children: entry.children
          .map((child) => _EditableEntry.fromDailyLogEntry(child))
          .toList(),
    );
  }

  DailyLogEntry toDailyLogEntry() {
    int parsedValue = currentValue;
    if (itemType == 'progress' || itemType == 'countdown') {
      parsedValue = int.tryParse(controller.text) ?? currentValue;
    }

    return DailyLogEntry(
      itemName: itemName,
      progress: progress,
      itemType: itemType,
      currentValue: parsedValue,
      targetValue: targetValue,
      children: children.map((c) => c.toDailyLogEntry()).toList(),
    );
  }

  void dispose() {
    controller.dispose();
    for (var child in children) {
      child.dispose();
    }
  }
}

class _EditHistoryEntrySheetState extends State<EditHistoryEntrySheet> {
  late List<_EditableEntry> _editableEntries;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editableEntries = widget.entries
        .map((e) => _EditableEntry.fromDailyLogEntry(e))
        .toList();
  }

  @override
  void dispose() {
    for (var entry in _editableEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  String _formatDisplayDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const monthNames = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        final monthStr =
            (monthNum >= 1 && monthNum <= 12) ? monthNames[monthNum - 1] : parts[1];
        return '$day $monthStr $year';
      }
    } catch (_) {}
    return dateKey;
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
    });

    final updated = _editableEntries.map((e) => e.toDailyLogEntry()).toList();
    await widget.onSave(updated);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.edit_calendar_rounded, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDisplayDate(widget.dateKey),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Items List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: _editableEntries
                      .map((entry) => _buildEntryItem(entry, 0))
                      .toList(),
                ),
              ),

              const Divider(height: 1),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryItem(_EditableEntry entry, int depth) {
    final bool hasValueInput =
        entry.itemType == 'progress' || entry.itemType == 'countdown';

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 6, bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildStatusSelector(entry),
              ],
            ),
            if (hasValueInput) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    entry.itemType == 'countdown' ? 'Sisa:' : 'Nilai:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    height: 36,
                    child: TextField(
                      controller: entry.controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${entry.targetValue}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            if (entry.children.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...entry.children.map((child) => _buildEntryItem(child, depth + 1)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector(_EditableEntry entry) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Colors.teal.shade100,
        selectedForegroundColor: Colors.teal.shade900,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        textStyle: const TextStyle(fontSize: 11),
      ),
      segments: const [
        ButtonSegment<String>(
          value: 'belum',
          label: Text('Belum'),
        ),
        ButtonSegment<String>(
          value: 'sementara',
          label: Text('Sementara'),
        ),
        ButtonSegment<String>(
          value: 'selesai',
          label: Text('Selesai'),
        ),
      ],
      selected: {entry.progress},
      onSelectionChanged: (newSelection) {
        setState(() {
          entry.progress = newSelection.first;
        });
      },
    );
  }
}
