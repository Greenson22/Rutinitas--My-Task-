// lib/features/daily/presentation/widgets/checklist_detail/checklist_control_panel.dart

import 'package:flutter/material.dart';
import '../../../data/models/daily_model.dart';

class ChecklistControlPanel extends StatefulWidget {
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

  // === PROPERTI BARU UNTUK FOLDING TREE ===
  final bool defaultCardExpanded;
  final ValueChanged<bool> onDefaultExpandedPrefChanged;
  final Function(bool) onTriggerAllExpansion;

  // === KONTROL SAKELAR BARU: AKSES IMPOR DATA DATA JSON ===
  final VoidCallback onImportJsonPressed;

  // === KONTROL PINDAH SEKSI LAZY-EXPAND ===
  final List<ChecklistSection> availableSections;
  final String currentSectionName;
  final ValueChanged<ChecklistSection>? onMoveToSection;

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
    required this.defaultCardExpanded,
    required this.onDefaultExpandedPrefChanged,
    required this.onTriggerAllExpansion,
    // --- MASUKKAN BARU KE CONSTRUCTOR ---
    required this.onImportJsonPressed,
    this.availableSections = const [],
    this.currentSectionName = '',
    this.onMoveToSection,
  });

  @override
  State<ChecklistControlPanel> createState() => _ChecklistControlPanelState();
}

class _ChecklistControlPanelState extends State<ChecklistControlPanel> {
  bool _isSectionPickerExpanded = false;

  @override
  Widget build(BuildContext context) {
    final targetSections = widget.availableSections
        .where((s) => s.sectionName != widget.currentSectionName)
        .toList();
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
                    controller: widget.singleInputController,
                    decoration: const InputDecoration(
                      hintText: 'Tambah sub-materi utama baru...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => widget.onAddRootItem(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.teal),
                  tooltip: 'Tambah Utama',
                  onPressed: widget.onAddRootItem,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.assignment_returned_outlined,
                    color: Colors.indigo,
                  ),
                  tooltip: 'Paste Banyak Baris dari Clipboard',
                  onPressed: widget.onPasteFromClipboard,
                ),
                // --- SAKELAR ICON BUTTON BARU KHUSUS IMPOR JSON ---
                IconButton(
                  icon: const Icon(
                    Icons.code_rounded,
                    color: Colors.deepOrange,
                  ),
                  tooltip: 'Impor Data dari JSON',
                  onPressed: widget.onImportJsonPressed,
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
                // --- BARIS KONTROL BARU: ATURAN DEFALT EXPAND / COLLAPSE MASAL ---
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree_outlined,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Default Anak Terbuka:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: widget.defaultCardExpanded,
                        activeColor: Colors.indigo,
                        onChanged: widget.onDefaultExpandedPrefChanged,
                      ),
                    ),
                    const Spacer(),
                    // Tombol cepat buka semua anak list
                    TextButton.icon(
                      onPressed: () => widget.onTriggerAllExpansion(true),
                      icon: const Icon(Icons.unfold_more, size: 14),
                      label: const Text(
                        'Buka Semua',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol cepat ciutkan semua anak list
                    TextButton.icon(
                      onPressed: () => widget.onTriggerAllExpansion(false),
                      icon: const Icon(Icons.unfold_less, size: 14),
                      label: const Text(
                        'Tutup Semua',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),

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
                        value: widget.subject.isDateActive,
                        activeColor: Colors.teal,
                        onChanged: widget.onDateActiveChanged,
                      ),
                    ),
                    if (widget.subject.isDateActive) ...[
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: widget.subject.dateType,
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
                        onChanged: widget.onDateTypeChanged,
                      ),
                    ],
                  ],
                ),
                if (widget.subject.isDateActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: widget.onSelectStartDate,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(
                            widget.subject.dateType == 'range'
                                ? 'Dari: ${widget.subject.date}'
                                : widget.subject.date ?? 'Pilih Tanggal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        if (widget.subject.dateType == 'range') ...[
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
                            onPressed: widget.onSelectEndDate,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Sampai: ${widget.subject.endDate}',
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
                if (widget.isEditMode && widget.subject.subMateri.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              activeColor: Colors.teal,
                              value: widget.isAllSelected,
                              onChanged: widget.onSelectAllChanged,
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
                              value: widget.isAllFinishedSelected,
                              onChanged: widget.onSelectAllFinishedChanged,
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
                        onPressed: widget.subject.subMateri.isEmpty
                            ? null
                            : widget.onMarkAllDone,
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
                        onPressed: widget.onToggleHideFinished,
                        icon: Icon(
                          widget.hideFinishedItems
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                        ),
                        label: Text(
                          widget.hideFinishedItems
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSectionPickerExpanded = !_isSectionPickerExpanded;
                    });
                  },
                  icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                  label: const Text(
                    'Pindah Seksi',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo[700],
                    side: BorderSide(color: Colors.indigo.shade200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isSectionPickerExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: targetSections
                              .map(
                                (section) => ListTile(
                                  dense: true,
                                  title: Text(
                                    section.sectionName,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  onTap: () {
                                    widget.onMoveToSection?.call(section);
                                    setState(() {
                                      _isSectionPickerExpanded = false;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        )
                      : const SizedBox.shrink(),
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
