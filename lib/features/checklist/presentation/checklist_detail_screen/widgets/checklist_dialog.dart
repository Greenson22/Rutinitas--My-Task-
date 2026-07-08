// lib/features/daily/presentation/widgets/checklist_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/utils/string_helper.dart';
import '../../../data/models/daily_model.dart';
import 'checklist_dialog/change_color_dialog.dart';
import 'checklist_dialog/checklist_control_panel.dart';
import 'checklist_dialog/checklist_tree_view.dart';
import 'checklist_dialog/checklist_note_view.dart';
import '../controllers/checklist_dialog_controller.dart';
import '../../../../../core/presentation/widgets/base_popup_dialog.dart';

class DailyChecklistDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onDataChanged;
  final List<DailySubject> allAvailableSubjects;
  final List<ChecklistGroup>? allAvailableGroups;
  final VoidCallback? onCustomClosePressed;
  final String? baseDir;

  const DailyChecklistDialog({
    super.key,
    required this.subject,
    required this.onDataChanged,
    required this.allAvailableSubjects,
    this.allAvailableGroups,
    this.onCustomClosePressed,
    this.baseDir,
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends ChecklistDialogController {
  // =========================================================================
  // IMPLEMENTASI SEMUA VIEW & DIALOG (UI ONLY)
  // =========================================================================

  Future<bool> showConfirmDialogView({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Konfirmasi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void showEditSubjectNameDialogView() {
    final editController = TextEditingController(
      text: widget.subject.subjectName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Judul Checklist'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Nama Judul Baru',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() => widget.subject.subjectName = newName);
                widget.onDataChanged();
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void addChildSubMateriDialogView(SubSubjectItem parentItem) {
    final childController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Anak di bawah "${parentItem.subjectName}"'),
        content: TextField(
          controller: childController,
          decoration: const InputDecoration(
            hintText: 'Nama anak sub-materi...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = childController.text.trim();
              if (text.isNotEmpty) {
                addChildSubMateriData(parentItem, text);
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void showImportJsonDialogView() {
    final TextEditingController jsonFieldController = TextEditingController();
    const String completeJsonTemplate =
        '[\n'
        '  {\n'
        '    "nama_materi": "Contoh Normal Item",\n'
        '    "progress": "belum",\n'
        '    "finishedDate": null,\n'
        '    "itemType": "normal",\n'
        '    "currentValue": 0,\n'
        '    "targetValue": 0,\n'
        '    "isDisabled": false,\n'
        '    "linkedSubjectName": null,\n'
        '    "accumulatorItemName": null,\n'
        '    "linkedExternalCardName": null,\n'
        '    "linkedExternalItemName": null,\n'
        '    "sub_materi": []\n'
        '  }\n'
        ']';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Impor Data dari JSON'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Tempel data teks JSON sesuai format:',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        const ClipboardData(text: completeJsonTemplate),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '📋 Template JSON disalin ke clipboard!',
                            ),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.copy_all,
                      size: 14,
                      color: Colors.indigo,
                    ),
                    label: const Text(
                      'Salin Template',
                      style: TextStyle(fontSize: 11, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonFieldController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                decoration: const InputDecoration(
                  hintText:
                      '[\n  {\n    "nama_materi": "Nama Item Baru",\n    "itemType": "normal"\n  }\n]',
                  border: OutlineInputBorder(),
                  fillColor: Color(0xFFF8F9FA),
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final String rawInput = jsonFieldController.text;
              Navigator.pop(context);
              if (rawInput.trim().isNotEmpty) {
                try {
                  importSubMateriFromJson(rawInput);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Sukses mengimpor dari data JSON!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memuat JSON! Detail: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text(
              'Impor Konten',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> selectSubjectDatePicker(bool isEndDate) async {
    DateTime initialDate = DateTime.now();
    String? dateToParse = isEndDate
        ? widget.subject.endDate
        : widget.subject.date;
    if (dateToParse != null && dateToParse.isNotEmpty) {
      try {
        initialDate = DateTime.parse(dateToParse);
      } catch (_) {}
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        String formatted =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        if (isEndDate) {
          widget.subject.endDate = formatted;
        } else {
          widget.subject.date = formatted;
        }
      });
      widget.onDataChanged();
    }
  }

  void pasteFromClipboardView() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clipboard kosong.')));
      return;
    }
    List<String> lines = data.text!
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    bool konfirmasi = await showConfirmDialogView(
      title: 'Konfirmasi Paste Banyak List',
      content:
          'Apakah Anda yakin ingin menambahkan ${lines.length} item baru dari clipboard?',
    );

    if (konfirmasi) {
      pasteFromClipboardData(lines);
    }
  }

  void deleteSingleSubMateriView(SubSubjectItem item) async {
    bool confirm = await showConfirmDialogView(
      title: 'Hapus Sub-Materi',
      content:
          'Apakah Anda yakin ingin menghapus "${item.subjectName}" beserta seluruh turunannya?',
    );
    if (confirm) {
      deleteSingleSubMateriData(item);
    }
  }

  void handleTapToggleStatusView(SubSubjectItem target) {
    if (target.linkedSubjectName != null &&
        target.linkedSubjectName!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Item ini dikunci oleh penyelesaian Card "${target.linkedSubjectName}"',
          ),
          backgroundColor: Colors.amber[800],
        ),
      );
      return;
    }
    if (target.itemType == 'progress' || target.itemType == 'countdown') {
      showUpdateProgressValueDialogView(target);
      return;
    }
    handleTapToggleStatusData(target);
  }

  void showUpdateProgressValueDialogView(SubSubjectItem item) {
    final valueController = TextEditingController();

    bool isCountdown = item.itemType == 'countdown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isCountdown
              ? 'Input Angka Pengurang untuk "${item.subjectName}"'
              : 'Input Angka Tambahan untuk "${item.subjectName}"',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCountdown
                  // Ganti dengan helper baru global
                  ? 'Sisa saat ini: ${StringHelper.formatRibuan(item.currentValue)}'
                  : 'Progres saat ini: ${StringHelper.formatRibuan(item.currentValue)} / ${StringHelper.formatRibuan(item.targetValue)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: isCountdown
                    ? 'Jumlah Angka Pengurang (Misal: 5)'
                    : 'Jumlah Angka Tambahan (Misal: 1.000)',
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                if (val.isEmpty) return;
                String cleanText = val.replaceAll('.', '');

                // Ganti regex lokal dengan pemanggilan global helper
                String formattedText = StringHelper.formatRibuan(
                  int.tryParse(cleanText) ?? 0,
                );

                valueController.value = TextEditingValue(
                  text: formattedText,
                  selection: TextSelection.collapsed(
                    offset: formattedText.length,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final String rawText = valueController.text
                  .replaceAll('.', '')
                  .trim();
              final int? addValue = int.tryParse(rawText);
              if (addValue != null && addValue > 0) {
                Navigator.pop(context);
                updateProgressValueData(item, addValue, isCountdown);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(
              isCountdown ? 'Kurangi' : 'Tambah',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void handleToggleItemTypeView(SubSubjectItem item, String targetType) {
    if (targetType == 'normal') {
      updateItemTypeData(item, 'normal', 0);
    } else {
      final targetController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            targetType == 'countdown'
                ? 'Set Target Angka Awal Hitung Mundur'
                : 'Set Target Angka Progres',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: targetController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nil Value (Misal: 10, 1.000, 1.000.000)',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              if (val.isEmpty) return;
              String cleanText = val.replaceAll('.', '');
              String formattedText = cleanText.replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (match) => '.',
              );
              targetController.value = TextEditingValue(
                text: formattedText,
                selection: TextSelection.collapsed(
                  offset: formattedText.length,
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final String rawText = targetController.text
                    .replaceAll('.', '')
                    .trim();
                final int? target = int.tryParse(rawText);
                if (target != null && target > 0) {
                  Navigator.pop(context);
                  updateItemTypeData(item, targetType, target);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text(
                'Set Target',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  void showEditNameDialogView(SubSubjectItem item) {
    final editController = TextEditingController(text: item.subjectName);
    final currentValController = TextEditingController(
      text: item.currentValue.toString(),
    );
    final targetValController = TextEditingController(
      text: item.targetValue.toString(),
    );

    ChecklistGroup? selectedGroupTarget;
    List<DailySubject> filteredCardTargets = [];
    String? localLinkedTarget = item.linkedSubjectName;

    if (localLinkedTarget != null && localLinkedTarget.isNotEmpty) {
      for (var group in widget.allAvailableGroups ?? <ChecklistGroup>[]) {
        for (var section in group.allList) {
          if (section.items.any(
            (sub) => sub.subjectName == localLinkedTarget,
          )) {
            selectedGroupTarget = group;
            for (var sec in group.allList)
              filteredCardTargets.addAll(sec.items);
            break;
          }
        }
        if (selectedGroupTarget != null) break;
      }
    }

    final List<ChecklistGroup> validGroupsList =
        (widget.allAvailableGroups ?? <ChecklistGroup>[])
            .where((g) => !g.id.startsWith("CORRUPTED_"))
            .toList();
    List<SubSubjectItem> allFlattenedItems = [];
    getAllItemsFlattened(widget.subject.subMateri, allFlattenedItems);
    List<SubSubjectItem> progressOptions = allFlattenedItems
        .where(
          (e) =>
              (e.itemType == 'progress' || e.itemType == 'countdown') &&
              e.subjectName != item.subjectName,
        )
        .toList();

    String? localAccumulatorTarget = item.accumulatorItemName;
    DailySubject? selectedExternalCard;
    List<SubSubjectItem> externalCardProgressItems = [];
    String? localExternalCardName = item.linkedExternalCardName;
    String? localExternalItemName = item.linkedExternalItemName;

    if (localExternalCardName != null) {
      selectedExternalCard = widget.allAvailableSubjects.firstWhere(
        (sub) => sub.subjectName == localExternalCardName,
        orElse: () =>
            DailySubject(subjectName: '', progress: 'belum', subMateri: []),
      );
      if (selectedExternalCard.subjectName.isNotEmpty) {
        getAllItemsFlattened(
          selectedExternalCard.subMateri,
          externalCardProgressItems,
        );
        externalCardProgressItems = externalCardProgressItems
            .where(
              (el) => el.itemType == 'progress' || el.itemType == 'countdown',
            )
            .toList();
      } else {
        selectedExternalCard = null;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Ubah Item & Hubungan Lintas Data'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Sub-Materi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (item.itemType == 'progress' ||
                      item.itemType == 'countdown') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: currentValController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: item.itemType == 'countdown'
                                  ? 'Sisa Nilai'
                                  : 'Nilai Sekarang',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '/',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: targetValController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: item.itemType == 'countdown'
                                  ? 'Nilai Awal'
                                  : 'Target Nilai',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '🔗 Kaitan Akumulasi Lintas Card Checklist',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DailySubject>(
                    value: selectedExternalCard,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Card Checklist Target',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card_rounded),
                    ),
                    hint: const Text('Pilih Card Luar (Opsional)'),
                    items: [
                      const DropdownMenuItem<DailySubject>(
                        value: null,
                        child: Text('Tidak Dikaitkan Ke Card Lain'),
                      ),
                      ...widget.allAvailableSubjects
                          .where(
                            (sub) =>
                                sub.subjectName != widget.subject.subjectName,
                          )
                          .map((sub) {
                            String displaySection =
                                (sub.section == 'focus' ||
                                    sub.section.trim().isEmpty)
                                ? 'Seksi Utama'
                                : sub.section;
                            return DropdownMenuItem<DailySubject>(
                              value: sub,
                              child: Text(
                                '${sub.icon} ${sub.subjectName} (${displaySection.toUpperCase()})',
                              ),
                            );
                          }),
                    ],
                    onChanged: (DailySubject? targetCard) {
                      setDialogState(() {
                        selectedExternalCard = targetCard;
                        externalCardProgressItems.clear();
                        localExternalCardName = targetCard?.subjectName;
                        localExternalItemName = null;
                        if (targetCard != null) {
                          getAllItemsFlattened(
                            targetCard.subMateri,
                            externalCardProgressItems,
                          );
                          externalCardProgressItems = externalCardProgressItems
                              .where(
                                (el) =>
                                    el.itemType == 'progress' ||
                                    el.itemType == 'countdown',
                              )
                              .toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: localExternalItemName,
                    disabledHint: const Text(
                      'Pilih Card target terlebih dahulu...',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Pilih Item Angka Target',
                      border: const OutlineInputBorder(),
                      enabled:
                          selectedExternalCard != null &&
                          externalCardProgressItems.isNotEmpty,
                      prefixIcon: const Icon(Icons.bar_chart_rounded),
                    ),
                    hint: Text(
                      selectedExternalCard == null
                          ? 'Pilih Card dulu'
                          : (externalCardProgressItems.isEmpty
                                ? 'Tidak ada item progress/countdown'
                                : 'Pilih Item Target'),
                    ),
                    items: selectedExternalCard == null
                        ? null
                        : externalCardProgressItems
                              .map(
                                (el) => DropdownMenuItem<String>(
                                  value: el.subjectName,
                                  child: Text('Item: ${el.subjectName}'),
                                ),
                              )
                              .toList(),
                    onChanged: selectedExternalCard == null
                        ? null
                        : (String? val) =>
                              setDialogState(() => localExternalItemName = val),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '⚙️ Pengaturan Kaitan Internal & Prasyarat Kunci',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: localAccumulatorTarget,
                    decoration: const InputDecoration(
                      labelText: 'Kaitkan Akumulasi Nilai Ke:',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.auto_graph_rounded),
                    ),
                    hint: const Text('Pilih List Pengumpul (Opsional)'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tidak Dikaitkan (Berdiri Sendiri)'),
                      ),
                      ...progressOptions.map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt.subjectName,
                          child: Text('Kumpul ke: ${opt.subjectName}'),
                        ),
                      ),
                    ],
                    onChanged: (String? val) {
                      setDialogState(() {
                        localAccumulatorTarget = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ChecklistGroup>(
                    value: selectedGroupTarget,
                    decoration: const InputDecoration(
                      labelText: '1. Pilih Kelompok Grup',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group_work_outlined),
                    ),
                    hint: const Text('Pilih Grup Asal Card (Opsional)'),
                    items: [
                      const DropdownMenuItem<ChecklistGroup>(
                        value: null,
                        child: Text('Tidak Dikaitkan (Bebas Klik)'),
                      ),
                      ...validGroupsList.map(
                        (group) => DropdownMenuItem(
                          value: group,
                          child: Text('${group.icon} ${group.groupName}'),
                        ),
                      ),
                    ],
                    onChanged: (ChecklistGroup? targetGroup) {
                      setDialogState(() {
                        selectedGroupTarget = targetGroup;
                        filteredCardTargets.clear();
                        localLinkedTarget = null;
                        if (targetGroup != null) {
                          for (var section in targetGroup.allList)
                            filteredCardTargets.addAll(section.items);
                          filteredCardTargets.removeWhere(
                            (sub) =>
                                sub.subjectName == widget.subject.subjectName,
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: localLinkedTarget,
                    disabledHint: const Text(
                      'Pilih kelompok grup terlebih dahulu...',
                    ),
                    decoration: InputDecoration(
                      labelText: '2. Pilih Card Prasyarat',
                      border: const OutlineInputBorder(),
                      enabled:
                          selectedGroupTarget != null &&
                          filteredCardTargets.isNotEmpty,
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                    ),
                    hint: Text(
                      filteredCardTargets.isEmpty
                          ? 'Tidak ada card tersedia'
                          : 'Pilih Card Prasyarat',
                    ),
                    items: selectedGroupTarget == null
                        ? null
                        : filteredCardTargets
                              .map(
                                (sub) => DropdownMenuItem<String>(
                                  value: sub.subjectName,
                                  child: Text('Card: ${sub.subjectName}'),
                                ),
                              )
                              .toList(),
                    onChanged: selectedGroupTarget == null
                        ? null
                        : (String? val) =>
                              setDialogState(() => localLinkedTarget = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = editController.text.trim();
                  if (newName.isNotEmpty) {
                    final int parsedCurrent =
                        int.tryParse(currentValController.text) ??
                        item.currentValue;
                    final int parsedTarget =
                        int.tryParse(targetValController.text) ??
                        item.targetValue;

                    Navigator.pop(context);
                    updateItemNameAndRelationsData(
                      item: item,
                      newName: newName,
                      linkedSubjectName: selectedGroupTarget == null
                          ? null
                          : localLinkedTarget,
                      accumulatorItemName: localAccumulatorTarget,
                      linkedExternalCardName: selectedExternalCard == null
                          ? null
                          : localExternalCardName,
                      linkedExternalItemName: selectedExternalCard == null
                          ? null
                          : localExternalItemName,
                      parsedCurrent: parsedCurrent,
                      parsedTarget: parsedTarget,
                      selectedExternalCard: selectedExternalCard,
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void showMoveSelectedItemsDialogView(List<SubSubjectItem> allFlattened) {
    List<SubSubjectItem> validTargets = allFlattened.where((item) {
      if (selectedItems.contains(item)) return false;
      return !selectedItems.any((selected) {
        bool isDescendant(SubSubjectItem parent, SubSubjectItem target) {
          if (parent.subMateri.contains(target)) return true;
          for (var child in parent.subMateri) {
            if (isDescendant(child, target)) return true;
          }
          return false;
        }

        return isDescendant(selected, item);
      });
    }).toList();

    bool isInternalMenuExpanded = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Pindahkan Item Terpilih ke...'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          isInternalMenuExpanded = !isInternalMenuExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 4.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pindah Posisi (Internal List Saat Ini)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                                fontSize: 13,
                              ),
                            ),
                            Icon(
                              isInternalMenuExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_right_rounded,
                              color: Colors.indigo,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: isInternalMenuExpanded
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.label_important,
                                    color: Colors.indigo,
                                  ),
                                  title: const Text(
                                    'Daftar Utama (Root List)',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    moveSelectedItemsToTarget(
                                      targetParent: null,
                                    );
                                  },
                                ),
                                ...validTargets.map(
                                  (target) => ListTile(
                                    leading: const Icon(
                                      Icons.subdirectory_arrow_right,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                    title: Text(
                                      target.subjectName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      moveSelectedItemsToTarget(
                                        targetParent: target,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                    const Divider(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Pindahkan ke Kotak List Lain:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ...widget.allAvailableSubjects
                        .where((sub) => sub != widget.subject)
                        .map(
                          (targetSubject) => ListTile(
                            leading: Text(
                              targetSubject.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            title: Text(
                              targetSubject.subjectName,
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              moveSelectedItemsToOtherSubject(targetSubject);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil memindahkan item ke kotak "${targetSubject.subjectName}"',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================

  @override
  Widget build(BuildContext context) {
    List<SubSubjectItem> allFlattened = [];
    getAllItemsFlattened(widget.subject.subMateri, allFlattened);

    bool isAllSelected =
        allFlattened.isNotEmpty &&
        allFlattened.every((i) => selectedItems.contains(i));
    List<SubSubjectItem> finishedItems = allFlattened
        .where((i) => i.progress == 'selesai')
        .toList();
    bool isAllFinishedSelected =
        finishedItems.isNotEmpty &&
        finishedItems.every((i) => selectedItems.contains(i));

    return BasePopupDialog(
      themeColor: Color(widget.subject.backgroundColor),
      titleColor: Color(widget.subject.textColor),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: showEditSubjectNameDialogView,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 2.0,
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${widget.subject.subjectName} ',
                        style: TextStyle(
                          color: Color(widget.subject.textColor),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subject.isDateActive &&
                          widget.subject.date != null)
                        ...DailySubject.buildColoredDateSpans(
                          widget.subject,
                          inHeader: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.subject.type == 'note') ...[
                if (!isNoteViewMode) ...[
                  const Text(
                    'MD',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: isMarkdownEnabled,
                      activeColor: Colors.tealAccent,
                      inactiveThumbColor: Colors.white70,
                      onChanged: (value) {
                        setState(() {
                          isMarkdownEnabled = value;
                          isNoteModified = true;
                        });
                      },
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isNoteViewMode ? Icons.edit : Icons.chrome_reader_mode,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: isNoteViewMode
                      ? 'Edit Catatan'
                      : 'Pratinjau Catatan',
                  onPressed: () =>
                      setState(() => isNoteViewMode = !isNoteViewMode),
                ),
              ],
              if (widget.subject.type == 'note' && isNoteModified)
                IconButton(
                  icon: const Icon(
                    Icons.save_as,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  onPressed: () {
                    saveManualNote();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📝 Catatan disimpan!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => ChangeColorDialog(
                    subject: widget.subject,
                    onColorSaved: () {
                      setState(() {});
                      widget
                          .onDataChanged(); // Menambahkan fungsi penyimpan data
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.subject.type == 'note' ? Icons.checklist : Icons.notes,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    widget.subject.type = widget.subject.type == 'note'
                        ? 'list'
                        : 'note';
                    if (widget.subject.type == 'note') showControlPanel = false;
                  });
                  widget.onDataChanged();
                },
              ),
              if (widget.subject.type != 'note')
                IconButton(
                  icon: Icon(
                    showControlPanel ? Icons.tune : Icons.tune_outlined,
                    color: showControlPanel ? Colors.amberAccent : Colors.white,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => showControlPanel = !showControlPanel),
                ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: showControlPanel
                ? ChecklistControlPanel(
                    subject: widget.subject,
                    singleInputController: singleInputController,
                    onAddRootItem: addRootSubMateri,
                    onPasteFromClipboard: pasteFromClipboardView,
                    onDateActiveChanged: (val) {
                      setState(() {
                        widget.subject.isDateActive = val;
                        if (val && (widget.subject.date ?? '').isEmpty) {
                          final now = DateTime.now();
                          widget.subject.date =
                              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                        }
                      });
                      widget.onDataChanged();
                    },
                    onDateTypeChanged: (val) {
                      if (val != null) {
                        setState(() {
                          widget.subject.dateType = val;
                          if (val == 'range' &&
                              (widget.subject.endDate ?? '').isEmpty) {
                            final besok = DateTime.now().add(
                              const Duration(days: 1),
                            );
                            widget.subject.endDate =
                                "${besok.year}-${besok.month.toString().padLeft(2, '0')}-${besok.day.toString().padLeft(2, '0')}";
                          }
                        });
                        widget.onDataChanged();
                      }
                    },
                    onSelectStartDate: () => selectSubjectDatePicker(false),
                    onSelectEndDate: () => selectSubjectDatePicker(true),
                    isEditMode: isEditMode,
                    isAllSelected: isAllSelected,
                    onSelectAllChanged: (checked) {
                      setState(() {
                        selectedItems.clear();
                        if (checked == true) selectedItems.addAll(allFlattened);
                      });
                    },
                    isAllFinishedSelected: isAllFinishedSelected,
                    onSelectAllFinishedChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          for (var i in finishedItems) {
                            if (!selectedItems.contains(i))
                              selectedItems.add(i);
                          }
                        } else {
                          selectedItems.removeWhere(
                            (i) => i.progress == 'selesai',
                          );
                        }
                      });
                    },
                    onMarkAllDone: markAllSubMateriAsDone,
                    hideFinishedItems: hideFinishedItems,
                    onToggleHideFinished: () =>
                        setState(() => hideFinishedItems = !hideFinishedItems),
                    defaultCardExpanded: widget.subject.defaultExpanded,
                    onDefaultExpandedPrefChanged:
                        toggleCardDefaultExpandedPreference,
                    onTriggerAllExpansion: expandOrCollapseAllMateri,
                    onImportJsonPressed: showImportJsonDialogView,
                  )
                : const SizedBox.shrink(),
          ),
          Flexible(
            child: widget.subject.type == 'note'
                ? ChecklistNoteView(
                    noteController: noteController,
                    isMarkdownEnabled: isMarkdownEnabled,
                    isViewMode: isNoteViewMode,
                    onChanged: (text) {
                      final orig = widget.subject.noteContent ?? '';
                      setState(() => isNoteModified = text != orig);
                    },
                  )
                : (widget.subject.subMateri.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('Tidak ada item sub materi.'),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          children: [
                            ...List.generate(widget.subject.subMateri.length, (
                              index,
                            ) {
                              final item = widget.subject.subMateri[index];
                              if (item.progress == 'selesai')
                                return const SizedBox.shrink();
                              return ChecklistTreeView(
                                item: item,
                                depth: 0,
                                isEditMode: isEditMode,
                                selectedItems: selectedItems,
                                highlightedItem: highlightedItem,
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    widget.subject.subMateri.length - 1,
                                onSelectItem: (target, add) => setState(
                                  () => add
                                      ? selectedItems.add(target)
                                      : selectedItems.remove(target),
                                ),
                                onMoveOrder: moveItemOrder,
                                onEditName: (targetItem) =>
                                    showEditNameDialogView(targetItem),
                                onLongPressToggle: () => setState(() {
                                  isEditMode = !isEditMode;
                                  selectedItems.clear();
                                }),
                                onCheckStatusChanged: handleCheckStatusChanged,
                                onTapToggleStatus: handleTapToggleStatusView,
                                onAddChild: (targetItem) =>
                                    addChildSubMateriDialogView(targetItem),
                                onDeleteItem: (targetItem) =>
                                    deleteSingleSubMateriView(targetItem),
                                onToggleItemType: handleToggleItemTypeView,
                                onUpdateProgressValue:
                                    showUpdateProgressValueDialogView,
                                onToggleDisable: handleToggleDisableItem,
                                onToggleExpansion: toggleItemExpansion,
                              );
                            }),
                            if (!hideFinishedItems &&
                                widget.subject.subMateri.any(
                                  (i) => i.progress == 'selesai',
                                ))
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        thickness: 1.5,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      child: Text(
                                        'List Telah Selesai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        thickness: 1.5,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!hideFinishedItems)
                              ...List.generate(
                                widget.subject.subMateri.length,
                                (index) {
                                  final item = widget.subject.subMateri[index];
                                  if (item.progress != 'selesai')
                                    return const SizedBox.shrink();
                                  return ChecklistTreeView(
                                    item: item,
                                    depth: 0,
                                    isEditMode: isEditMode,
                                    selectedItems: selectedItems,
                                    highlightedItem: highlightedItem,
                                    isFirst: index == 0,
                                    isLast:
                                        index ==
                                        widget.subject.subMateri.length - 1,
                                    onSelectItem: (target, add) => setState(
                                      () => add
                                          ? selectedItems.add(target)
                                          : selectedItems.remove(target),
                                    ),
                                    onMoveOrder: moveItemOrder,
                                    onEditName: (targetItem) =>
                                        showEditNameDialogView(targetItem),
                                    onLongPressToggle: () => setState(() {
                                      isEditMode = !isEditMode;
                                      selectedItems.clear();
                                    }),
                                    onCheckStatusChanged:
                                        handleCheckStatusChanged,
                                    onTapToggleStatus:
                                        handleTapToggleStatusView,
                                    onAddChild: (targetItem) =>
                                        addChildSubMateriDialogView(targetItem),
                                    onDeleteItem: (targetItem) =>
                                        deleteSingleSubMateriView(targetItem),
                                    onToggleItemType: handleToggleItemTypeView,
                                    onUpdateProgressValue:
                                        showUpdateProgressValueDialogView,
                                    onToggleDisable: handleToggleDisableItem,
                                    onToggleExpansion: toggleItemExpansion,
                                  );
                                },
                              ),
                          ],
                        )),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isEditMode) ...[
              Text(
                '${selectedItems.length} Terpilih',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Row(
                children: [
                  ButtonTheme(
                    child: ElevatedButton.icon(
                      onPressed: selectedItems.isEmpty
                          ? null
                          : () => showMoveSelectedItemsDialogView(allFlattened),
                      icon: const Icon(
                        Icons.drive_file_move,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Pindah',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: selectedItems.isEmpty
                        ? null
                        : () async {
                            bool confirm = await showConfirmDialogView(
                              title: 'Hapus Masal',
                              content: 'Hapus seluruh item terpilih?',
                            );
                            if (confirm) {
                              setState(() {
                                for (var i in selectedItems) {
                                  deleteItemFromTree(
                                    widget.subject.subMateri,
                                    i,
                                  );
                                }
                                selectedItems.clear();
                              });
                              updateSubjectOverallProgress();
                              widget.onDataChanged();
                            }
                          },
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      'Hapus Masal',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  if (undoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.blueGrey),
                      onPressed: executeUndo,
                    ),
                  if (redoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.redo, color: Colors.blueGrey),
                      onPressed: executeRedo,
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      bool confirm = await showConfirmDialogView(
                        title: 'Reset Progress',
                        content:
                            'Reset semua progress menjadi Belum Selesai? (List nonaktif akan diabaikan)',
                      );
                      if (confirm) resetProgressData(false);
                    },
                    onLongPress: () async {
                      bool confirm = await showConfirmDialogView(
                        title: 'Reset Total Checklist',
                        content:
                            'Apakah Anda yakin ingin mereset seluruh progress DAN mengaktifkan kembali semua list yang dinonaktifkan (tanda silang)?',
                      );
                      if (confirm) {
                        resetProgressData(true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Seluruh list dan status dinonaktifkan berhasil di-reset total!',
                              ),
                              backgroundColor: Colors.deepOrange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, color: Colors.red, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  if (widget.onCustomClosePressed != null) {
                    widget.onCustomClosePressed!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(widget.subject.backgroundColor),
                ),
                child: Text(
                  'Tutup',
                  style: TextStyle(color: Color(widget.subject.textColor)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
