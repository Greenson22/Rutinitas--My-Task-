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

  // === KONTROL MODE MONITOR & DAILY TRACKER ===
  final ValueChanged<bool>? onToggleMonitorMode;
  final ValueChanged<bool>? onToggleDailyTracker;

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
    this.onToggleMonitorMode,
    this.onToggleDailyTracker,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Input Tambah Sub-Materi + Aksi Cepat (Tambah, Paste, JSON)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.singleInputController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tambah sub-materi baru...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (_) => widget.onAddRootItem(),
                ),
              ),
              const SizedBox(width: 6),
              _buildActionIcon(
                icon: Icons.add_rounded,
                color: Colors.teal,
                tooltip: 'Tambah Utama',
                onTap: widget.onAddRootItem,
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                icon: Icons.assignment_returned_outlined,
                color: Colors.indigo,
                tooltip: 'Paste Banyak Baris dari Clipboard',
                onTap: widget.onPasteFromClipboard,
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                icon: Icons.code_rounded,
                color: Colors.deepOrange,
                tooltip: 'Impor Data dari JSON',
                onTap: widget.onImportJsonPressed,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Kartu Pengaturan (Mode Monitor, Default Anak Terbuka, Tanggal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Mode Monitor
                Row(
                  children: [
                    Icon(
                      widget.subject.isMonitorMode
                          ? Icons.monitor_heart_rounded
                          : Icons.monitor_heart_outlined,
                      size: 18,
                      color: widget.subject.isMonitorMode
                          ? Colors.indigo
                          : Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mode Monitor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: widget.subject.isMonitorMode,
                        activeColor: Colors.indigo,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: widget.onToggleMonitorMode,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                // Daily Tracker
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 17,
                      color: widget.subject.isDailyTrackerEnabled
                          ? Colors.teal
                          : Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Daily Tracker',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: widget.subject.isDailyTrackerEnabled,
                        activeColor: Colors.teal,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: widget.onToggleDailyTracker,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                // Default Anak Terbuka & Buka/Tutup Semua
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree_outlined,
                      size: 17,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Anak Terbuka:',
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: widget.onDefaultExpandedPrefChanged,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => widget.onTriggerAllExpansion(true),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.unfold_more, size: 14, color: Colors.indigo),
                            SizedBox(width: 2),
                            Text(
                              'Buka',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => widget.onTriggerAllExpansion(false),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.unfold_less, size: 14, color: Colors.blueGrey),
                            SizedBox(width: 2),
                            Text(
                              'Tutup',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                // Aktifkan Tanggal
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 8),
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: widget.onDateActiveChanged,
                      ),
                    ),
                    if (widget.subject.isDateActive) ...[
                      const Spacer(),
                      DropdownButton<String>(
                        value: widget.subject.dateType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
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
                    padding: const EdgeInsets.only(top: 4.0, left: 24.0),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: widget.onSelectStartDate,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            widget.subject.dateType == 'range'
                                ? 'Dari: ${widget.subject.date}'
                                : widget.subject.date ?? 'Pilih Tanggal',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.subject.dateType == 'range') ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '—',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onSelectEndDate,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sampai: ${widget.subject.endDate}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (widget.isEditMode && widget.subject.subMateri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          activeColor: Colors.teal,
                          value: widget.isAllSelected,
                          onChanged: widget.onSelectAllChanged,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            ),

          const SizedBox(height: 8),

          // 3. Tombol Tandai Semua Selesai & Sembunyikan Selesai
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.subject.subMateri.isEmpty
                      ? null
                      : widget.onMarkAllDone,
                  icon: const Icon(Icons.done_all, size: 15),
                  label: const Text(
                    'Tandai Selesai',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onToggleHideFinished,
                  icon: Icon(
                    widget.hideFinishedItems
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 15,
                  ),
                  label: Text(
                    widget.hideFinishedItems
                        ? 'Tampilkan Selesai'
                        : 'Sembunyi Selesai',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueGrey[700],
                    side: BorderSide(color: Colors.blueGrey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4. Pindah Seksi
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _isSectionPickerExpanded = !_isSectionPickerExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.drive_file_move_outlined,
                          size: 16,
                          color: Colors.indigo[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pindah Seksi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[700],
                            ),
                          ),
                        ),
                        Icon(
                          _isSectionPickerExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Colors.indigo[700],
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isSectionPickerExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(height: 1),
                            ...targetSections.map(
                              (section) => ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.folder_outlined,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
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
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
