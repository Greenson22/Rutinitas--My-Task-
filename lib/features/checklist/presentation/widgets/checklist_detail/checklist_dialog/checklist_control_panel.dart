// lib/features/daily/presentation/widgets/checklist_detail/checklist_control_panel.dart

import 'package:flutter/material.dart';
import '../../../../data/models/daily_model.dart';

class ChecklistControlPanel extends StatelessWidget {
  final DailySubject subject;
  final TextEditingController singleInputController;
  final VoidCallback onAddRootItem;
  final VoidCallback onPasteFromClipboard;
  final ValueChanged<bool> onDateActiveChanged;
  final ValueChanged<String?> onDateTypeChanged;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final bool isEditMode;
  final bool isAllSelected;
  final ValueChanged<bool?> onSelectAllChanged;
  final bool isAllFinishedSelected;
  final ValueChanged<bool?> onSelectAllFinishedChanged;
  final VoidCallback onMarkAllDone;
  final bool hideFinishedItems;
  final VoidCallback onToggleHideFinished;

  const ChecklistControlPanel({
    super.key,
    required this.subject,
    required this.singleInputController,
    required this.onAddRootItem,
    required this.onPasteFromClipboard,
    required this.onDateActiveChanged,
    required this.onDateTypeChanged,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.isEditMode,
    required this.isAllSelected,
    required this.onSelectAllChanged,
    required this.isAllFinishedSelected,
    required this.onSelectAllFinishedChanged,
    required this.onMarkAllDone,
    required this.hideFinishedItems,
    required this.onToggleHideFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: singleInputController,
                    decoration: const InputDecoration(
                      hintText: 'Tambah sub-materi utama baru...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => onAddRootItem(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.teal),
                  tooltip: 'Tambah Utama',
                  onPressed: onAddRootItem,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.assignment_returned_outlined,
                    color: Colors.indigo,
                  ),
                  tooltip: 'Paste Banyak Baris dari Clipboard',
                  onPressed: onPasteFromClipboard,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Aktifkan Tanggal:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: subject.isDateActive,
                        activeColor: Colors.teal,
                        onChanged: onDateActiveChanged,
                      ),
                    ),
                    if (subject.isDateActive) ...[
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: subject.dateType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        isDense: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'single',
                            child: Text('Biasa'),
                          ),
                          DropdownMenuItem(
                            value: 'range',
                            child: Text('Rentang'),
                          ),
                        ],
                        onChanged: onDateTypeChanged,
                      ),
                    ],
                  ],
                ),
                if (subject.isDateActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: onSelectStartDate,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            subject.dateType == 'range'
                                ? 'Dari: ${subject.date}'
                                : subject.date ?? 'Pilih Tanggal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        if (subject.dateType == 'range') ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onSelectEndDate,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Sampai: ${subject.endDate}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (isEditMode && subject.subMateri.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              activeColor: Colors.teal,
                              value: isAllSelected,
                              onChanged: onSelectAllChanged,
                            ),
                            const Text(
                              'Pilih Semua Item',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              activeColor: Colors.green,
                              value: isAllFinishedSelected,
                              onChanged: onSelectAllFinishedChanged,
                            ),
                            const Text(
                              'Pilih Semua Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: subject.subMateri.isEmpty
                            ? null
                            : onMarkAllDone,
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text(
                          'Tandai Semua Selesai',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: onToggleHideFinished,
                        icon: Icon(
                          hideFinishedItems
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                        ),
                        label: Text(
                          hideFinishedItems
                              ? 'Tampilkan Selesai'
                              : 'Sembunyikan Selesai',
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey[700],
                          side: BorderSide(color: Colors.blueGrey.shade200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
