// lib/features/daily/presentation/widgets/checklist_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/daily_model.dart';
import 'change_color_dialog.dart';
import 'checklist_control_panel.dart';
import 'checklist_tree_view.dart';
import 'checklist_note_view.dart';
import '../../../../../core/presentation/widgets/base_popup_dialog.dart';

class DailyChecklistDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onDataChanged;
  final List<DailySubject> allAvailableSubjects;
  final VoidCallback? onCustomClosePressed;

  const DailyChecklistDialog({
    super.key,
    required this.subject,
    required this.onDataChanged,
    required this.allAvailableSubjects,
    this.onCustomClosePressed,
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends State<DailyChecklistDialog> {
  final TextEditingController _singleInputController = TextEditingController();
  late TextEditingController _noteController;
  bool _isEditMode = false;
  bool _showControlPanel = false;
  bool _hideFinishedItems = false;
  final List<SubSubjectItem> _selectedItems = [];
  final List<List<SubSubjectItem>> _undoStack = [];
  final List<List<SubSubjectItem>> _redoStack = [];

  SubSubjectItem? _highlightedItem;
  bool _isNoteModified = false;

  bool _isMarkdownEnabled = false;
  bool _isNoteViewMode = true;

  bool get isNoteModifiedExternal => _isNoteModified;
  void saveManualNoteExternal() => _saveManualNote();

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.subject.noteContent ?? '',
    );
    _isMarkdownEnabled = widget.subject.isMarkdownEnabled;
    _isNoteViewMode = _noteController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _singleInputController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveToHistory() {
    final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
        .map((item) => item.clone())
        .toList();
    _undoStack.add(currentSnapshot);
    _redoStack.clear();
  }

  void _executeUndo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
          .map((item) => item.clone())
          .toList();
      _redoStack.add(currentSnapshot);
      widget.subject.subMateri = _undoStack.removeLast();
      _updateSubjectOverallProgress();
    });
    widget.onDataChanged();
  }

  void _executeRedo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
          .map((item) => item.clone())
          .toList();
      _undoStack.add(currentSnapshot);
      widget.subject.subMateri = _redoStack.removeLast();
      _updateSubjectOverallProgress();
    });
    widget.onDataChanged();
  }

  void _markAllSubMateriAsDone() {
    if (widget.subject.subMateri.isEmpty) return;
    _saveToHistory();
    final String formattedDate =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    void markDoneRecursive(List<SubSubjectItem> list) {
      for (var item in list) {
        item.progress = 'selesai';
        item.finishedDate = formattedDate;
        if (item.subMateri.isNotEmpty) markDoneRecursive(item.subMateri);
      }
    }

    setState(() => markDoneRecursive(widget.subject.subMateri));
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void _addRootSubMateri() {
    final text = _singleInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.subject.subMateri.add(
        SubSubjectItem(subjectName: text, progress: 'belum'),
      );
      _singleInputController.clear();
    });
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void _addChildSubMateri(SubSubjectItem parentItem) {
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
                setState(
                  () => parentItem.subMateri.add(
                    SubSubjectItem(subjectName: text, progress: 'belum'),
                  ),
                );
                _updateSubjectOverallProgress();
                widget.onDataChanged();
              }
              Navigator.pop(context);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  bool _deleteItemFromTree(
    List<SubSubjectItem> treeList,
    SubSubjectItem target,
  ) {
    if (treeList.contains(target)) {
      treeList.remove(target);
      return true;
    }
    for (var item in treeList) {
      if (_deleteItemFromTree(item.subMateri, target)) return true;
    }
    return false;
  }

  void _deleteSingleSubMateri(SubSubjectItem item) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Sub-Materi',
      content:
          'Apakah Anda yakin ingin menghapus "${item.subjectName}" beserta seluruh turunannya?',
    );
    if (!confirm) return;
    setState(() {
      _deleteItemFromTree(widget.subject.subMateri, item);
      _selectedItems.remove(item);
    });
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void _showEditNameDialog(SubSubjectItem item) {
    final editController = TextEditingController(text: item.subjectName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Sub-Materi'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
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
                setState(() => item.subjectName = newName);
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

  // Tambahan Fitur Baru: Dialog untuk mengubah Judul Utama Checklist (DailySubject)
  void _showEditSubjectNameDialog() {
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
                setState(() {
                  widget.subject.subjectName = newName;
                });
                widget.onDataChanged(); // Memicu auto-save data utama
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _moveItemOrder(SubSubjectItem item, int direction) {
    bool moveItemInTree(
      List<SubSubjectItem> treeList,
      SubSubjectItem target,
      int dir,
    ) {
      if (treeList.contains(target)) {
        int idx = treeList.indexOf(target);
        int newIdx = idx + dir;
        if (newIdx >= 0 && newIdx < treeList.length) {
          final active = treeList.removeAt(idx);
          treeList.insert(newIdx, active);
          return true;
        }
        return false;
      }
      for (var sub in treeList) {
        if (moveItemInTree(sub.subMateri, target, dir)) return true;
      }
      return false;
    }

    setState(() {
      moveItemInTree(widget.subject.subMateri, item, direction);
      _highlightedItem = item;
    });
    widget.onDataChanged();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _highlightedItem == item)
        setState(() => _highlightedItem = null);
    });
  }

  void _pasteFromClipboard() async {
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

    bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Paste Banyak List'),
        content: Text(
          'Apakah Anda yakin ingin menambahkan ${lines.length} item baru dari clipboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tambahkan'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    setState(() {
      for (var line in lines) {
        widget.subject.subMateri.add(
          SubSubjectItem(subjectName: line.trim(), progress: 'belum'),
        );
      }
    });
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  Future<void> _selectSubjectDate(bool isEndDate) async {
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

  void _saveManualNote() {
    setState(() {
      widget.subject.noteContent = _noteController.text;
      widget.subject.isMarkdownEnabled = _isMarkdownEnabled;
      _isNoteModified = false;
      _isNoteViewMode = true;
    });
    widget.onDataChanged();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Catatan disimpan!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _updateSubjectOverallProgress() {
    double countTotal(List<SubSubjectItem> list) {
      double total = 0;
      for (var i in list) {
        if (i.subMateri.isNotEmpty) {
          total += countTotal(i.subMateri);
        } else {
          total += 1.0;
        }
      }
      return total;
    }

    double countFinished(List<SubSubjectItem> list) {
      double fin = 0;
      for (var i in list) {
        if (i.subMateri.isNotEmpty) {
          fin += countFinished(i.subMateri);
        } else {
          if (i.progress == 'selesai') fin += 1.0;
        }
      }
      return fin;
    }

    double total = countTotal(widget.subject.subMateri);
    double selesai = countFinished(widget.subject.subMateri);

    if (total == 0) {
      widget.subject.progress = 'belum';
    } else if (selesai == total) {
      widget.subject.progress = 'selesai';
    } else if (selesai > 0) {
      widget.subject.progress = 'sementara';
    } else {
      widget.subject.progress = 'belum';
    }
  }

  void _getAllItemsFlattened(
    List<SubSubjectItem> source,
    List<SubSubjectItem> destination,
  ) {
    for (var element in source) {
      destination.add(element);
      if (element.subMateri.isNotEmpty)
        _getAllItemsFlattened(element.subMateri, destination);
    }
  }

  Future<bool> _showConfirmDialog({
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

  // Update pada dialog pemindah item
  void _showMoveSelectedItemsDialog(List<SubSubjectItem> allFlattened) {
    // 1. Filter target internal (SubSubjectItem lain di dalam list saat ini)
    List<SubSubjectItem> validTargets = allFlattened.where((item) {
      if (_selectedItems.contains(item)) return false;
      return !_selectedItems.any((selected) {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindahkan Item Terpilih ke...'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            // Dibungkus ScrollView agar aman jika data banyak
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= SEKSI 1: PINDAH INTERNAL LIST INI =================
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Pindah Posisi (Internal List Saat Ini):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      fontSize: 13,
                    ),
                  ),
                ),
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
                    _moveSelectedItemsToTarget(targetParent: null);
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
                      _moveSelectedItemsToTarget(targetParent: target);
                    },
                  ),
                ),
                const Divider(height: 24),

                // ================= SEKSI 2: PINDAH KE LIST LAIN =================
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
                // Filter agar kotak list saat ini tidak muncul kembali di pilihan luar
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
                          _moveSelectedItemsToOtherSubject(targetSubject);
                        },
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // METHOD BARU: Untuk mengeksekusi perpindahan item keluar dari DailySubject saat ini menuju target baru
  void _moveSelectedItemsToOtherSubject(DailySubject targetSubject) {
    _saveToHistory();
    setState(() {
      // 1. Ambil item-item terpilih dan hapus dari struktur pohon list saat ini
      for (var item in _selectedItems) {
        _deleteItemFromTree(widget.subject.subMateri, item);
      }

      // 2. Masukkan item-item tersebut ke root list dari DailySubject tujuan
      targetSubject.subMateri.addAll(_selectedItems);

      // 3. Bersihkan sisa pilihan di UI & matikan mode edit
      _selectedItems.clear();
      _isEditMode = false;
    });

    // 4. Rekalkulasi progress untuk kedua belah pihak (asal dan tujuan)
    for (var root in widget.subject.subMateri) {
      root.updateStatusFromChildren();
    }
    _updateSubjectOverallProgress();

    // Trigger progress update untuk targetSubject eksternal
    double countTotal(List<SubSubjectItem> list) {
      double total = 0;
      for (var i in list) {
        total += i.subMateri.isNotEmpty ? countTotal(i.subMateri) : 1.0;
      }
      return total;
    }

    double countFinished(List<SubSubjectItem> list) {
      double fin = 0;
      for (var i in list) {
        fin += i.subMateri.isNotEmpty
            ? countFinished(i.subMateri)
            : (i.progress == 'selesai' ? 1.0 : 0.0);
      }
      return fin;
    }

    double t = countTotal(targetSubject.subMateri);
    double s = countFinished(targetSubject.subMateri);
    if (t == 0)
      targetSubject.progress = 'belum';
    else if (s == t)
      targetSubject.progress = 'selesai';
    else if (s > 0)
      targetSubject.progress = 'sementara';
    else
      targetSubject.progress = 'belum';

    // 5. Simpan perubahan secara permanen melalui callback kontroler utama
    widget.onDataChanged();

    // Beri feedback notifikasi sukses kepada pengguna
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Berhasil memindahkan item ke kotak "${targetSubject.subjectName}"',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Update minor parameter opsional named pada fungsi bawaan lama agar fleksibel
  void _moveSelectedItemsToTarget({SubSubjectItem? targetParent}) {
    _saveToHistory();
    setState(() {
      for (var item in _selectedItems) {
        _deleteItemFromTree(widget.subject.subMateri, item);
      }
      if (targetParent == null) {
        widget.subject.subMateri.addAll(_selectedItems);
      } else {
        targetParent.subMateri.addAll(_selectedItems);
      }
      _selectedItems.clear();
      _isEditMode = false;
    });
    for (var root in widget.subject.subMateri) {
      root.updateStatusFromChildren();
    }
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  // =========================================================================
  // FITUR BARU: Penangan Konfigurasi Pengubahan Tipe dan Penambahan Nilai Angka
  // =========================================================================
  void _handleToggleItemType(SubSubjectItem item) {
    if (item.itemType == 'normal') {
      final targetController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Set Target Angka Progres',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                autofocus: true,
                // Menggunakan format input standar digit angka murni
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Target Nilai (Misal: 10, 1.000, 1.000.000)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  // FORMATTER REAL-TIME: Otomatis menambahkan titik setiap 3 digit angka saat diketik
                  if (val.isEmpty) return;

                  // Hapus semua titik lama terlebih dahulu agar kalkulasi string murni bersih
                  String cleanText = val.replaceAll('.', '');

                  // Bentuk ulang string format dengan menambahkan separator titik Indonesia
                  String formattedText = cleanText.replaceAllMapped(
                    RegExp(r'\B(?=(\d{3})+(?!\d))'),
                    (match) => '.',
                  );

                  // Set teks baru dan atur posisi kursor teks agar selalu berada di paling kanan ujung input
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
                    // DEKODER: Hapus karakter tanda titik sebelum melakukan parsing data string ke Integer murni
                    final String rawText = targetController.text
                        .replaceAll('.', '')
                        .trim();
                    final int? target = int.tryParse(rawText);

                    if (target != null && target > 0) {
                      setState(() {
                        item.itemType = 'progress';
                        item.targetValue = target;
                        item.currentValue = 0;
                        item.progress = 'belum';
                      });
                      for (var r in widget.subject.subMateri) {
                        r.updateStatusFromChildren();
                      }
                      _updateSubjectOverallProgress();
                      widget.onDataChanged();
                      Navigator.pop(context);
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
            );
          },
        ),
      );
    } else {
      setState(() {
        item.itemType = 'normal';
        item.targetValue = 0;
        item.currentValue = 0;
        item.progress = 'belum';
      });
      for (var r in widget.subject.subMateri) {
        r.updateStatusFromChildren();
      }
      _updateSubjectOverallProgress();
      widget.onDataChanged();
    }
  }

  void _showUpdateProgressValueDialog(SubSubjectItem item) {
    final valueController = TextEditingController();

    // Helper format angka ribuan (dengan tanda titik) untuk teks informasi dialog
    String formatDialogNum(int num) => num.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Input Angka Progres untuk "${item.subjectName}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres saat ini: ${formatDialogNum(item.currentValue)} / ${formatDialogNum(item.targetValue)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  // Membatasi agar input keyboard hanya menerima angka saja
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Angka Tambahan (Misal: 1.000)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    // FORMATTER REAL-TIME: Otomatis menambahkan tanda titik saat pengguna mengetik harian
                    if (val.isEmpty) return;

                    // Hapus tanda titik lama terlebih dahulu agar kalkulasi teks bersih
                    String cleanText = val.replaceAll('.', '');

                    // Bentuk ulang teks dengan menyisipkan pemisah titik ribuan Indonesia
                    String formattedText = cleanText.replaceAllMapped(
                      RegExp(r'\B(?=(\d{3})+(?!\d))'),
                      (match) => '.',
                    );

                    // Pasang teks hasil format dan kunci kursor agar tetap di ujung paling kanan
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
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // DEKODER: Bersihkan karakter tanda titik pembantu sebelum melakukan parsing ke Integer murni
                  final String rawText = valueController.text
                      .replaceAll('.', '')
                      .trim();
                  final int? addValue = int.tryParse(rawText);

                  if (addValue != null && addValue > 0) {
                    _saveToHistory();
                    setState(() {
                      // Menambahkan nilai angka baru tanpa batasan clamp nilai target
                      item.currentValue = item.currentValue + addValue;

                      if (item.currentValue >= item.targetValue) {
                        item.progress = 'selesai';
                        item.finishedDate =
                            "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                      } else {
                        item.progress = 'belum';
                        item.finishedDate = null;
                      }

                      for (var r in widget.subject.subMateri) {
                        r.updateStatusFromChildren();
                      }
                    });
                    _updateSubjectOverallProgress();
                    widget.onDataChanged();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text(
                  'Tambah',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<SubSubjectItem> allFlattened = [];
    _getAllItemsFlattened(widget.subject.subMateri, allFlattened);

    bool isAllSelected =
        allFlattened.isNotEmpty &&
        allFlattened.every((i) => _selectedItems.contains(i));
    List<SubSubjectItem> finishedItems = allFlattened
        .where((i) => i.progress == 'selesai')
        .toList();
    bool isAllFinishedSelected =
        finishedItems.isNotEmpty &&
        finishedItems.every((i) => _selectedItems.contains(i));

    return BasePopupDialog(
      themeColor: Color(widget.subject.backgroundColor),
      titleColor: Color(widget.subject.textColor),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap:
                  _showEditSubjectNameDialog, // Memicu dialog ubah judul saat diklik
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
                if (!_isNoteViewMode) ...[
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
                      value: _isMarkdownEnabled,
                      activeColor: Colors.tealAccent,
                      inactiveThumbColor: Colors.white70,
                      onChanged: (value) {
                        setState(() {
                          _isMarkdownEnabled = value;
                          _isNoteModified = true;
                        });
                      },
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isNoteViewMode ? Icons.edit : Icons.chrome_reader_mode,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: _isNoteViewMode
                      ? 'Edit Catatan'
                      : 'Pratinjau Catatan',
                  onPressed: () {
                    setState(() {
                      _isNoteViewMode = !_isNoteViewMode;
                    });
                  },
                ),
              ],

              if (widget.subject.type == 'note' && _isNoteModified)
                IconButton(
                  icon: const Icon(
                    Icons.save_as,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  onPressed: _saveManualNote,
                ),
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => ChangeColorDialog(
                    subject: widget.subject,
                    onColorSaved: () => setState(() {}),
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
                    if (widget.subject.type == 'note')
                      _showControlPanel = false;
                  });
                  widget.onDataChanged();
                },
              ),
              if (widget.subject.type != 'note')
                IconButton(
                  icon: Icon(
                    _showControlPanel ? Icons.tune : Icons.tune_outlined,
                    color: _showControlPanel
                        ? Colors.amberAccent
                        : Colors.white,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showControlPanel = !_showControlPanel),
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
            child: _showControlPanel
                ? ChecklistControlPanel(
                    subject: widget.subject,
                    singleInputController: _singleInputController,
                    onAddRootItem: _addRootSubMateri,
                    onPasteFromClipboard: _pasteFromClipboard,
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
                    onSelectStartDate: () => _selectSubjectDate(false),
                    onSelectEndDate: () => _selectSubjectDate(true),
                    isEditMode: _isEditMode,
                    isAllSelected: isAllSelected,
                    onSelectAllChanged: (checked) {
                      setState(() {
                        _selectedItems.clear();
                        if (checked == true)
                          _selectedItems.addAll(allFlattened);
                      });
                    },
                    isAllFinishedSelected: isAllFinishedSelected,
                    onSelectAllFinishedChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          for (var i in finishedItems) {
                            if (!_selectedItems.contains(i))
                              _selectedItems.add(i);
                          }
                        } else {
                          _selectedItems.removeWhere(
                            (i) => i.progress == 'selesai',
                          );
                        }
                      });
                    },
                    onMarkAllDone: _markAllSubMateriAsDone,
                    hideFinishedItems: _hideFinishedItems,
                    onToggleHideFinished: () => setState(
                      () => _hideFinishedItems = !_hideFinishedItems,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Flexible(
            child: widget.subject.type == 'note'
                ? ChecklistNoteView(
                    noteController: _noteController,
                    isMarkdownEnabled: _isMarkdownEnabled,
                    isViewMode: _isNoteViewMode,
                    onChanged: (text) {
                      final orig = widget.subject.noteContent ?? '';
                      setState(() => _isNoteModified = text != orig);
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
                                isEditMode: _isEditMode,
                                selectedItems: _selectedItems,
                                highlightedItem: _highlightedItem,
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    widget.subject.subMateri.length - 1,
                                onSelectItem: (target, add) => setState(
                                  () => add
                                      ? _selectedItems.add(target)
                                      : _selectedItems.remove(target),
                                ),
                                onMoveOrder: _moveItemOrder,
                                onEditName: (targetItem) => _showEditNameDialog(
                                  targetItem,
                                ), // <-- Mengirim referensi child yang tepat
                                onLongPressToggle: () => setState(() {
                                  _isEditMode = !_isEditMode;
                                  _selectedItems.clear();
                                }),
                                onCheckStatusChanged: (target, checked) {
                                  _saveToHistory();
                                  setState(() {
                                    target.progress = checked == true
                                        ? 'selesai'
                                        : 'belum';
                                    for (var r in widget.subject.subMateri) {
                                      r.updateStatusFromChildren();
                                    }
                                  });
                                  _updateSubjectOverallProgress();
                                  widget.onDataChanged();
                                },
                                onTapToggleStatus: (target) {
                                  if (target.itemType == 'progress') {
                                    _showUpdateProgressValueDialog(target);
                                    return;
                                  }
                                  _saveToHistory();
                                  setState(
                                    () => target.progress =
                                        target.progress != 'selesai'
                                        ? 'selesai'
                                        : 'belum',
                                  );
                                  for (var r in widget.subject.subMateri) {
                                    r.updateStatusFromChildren();
                                  }
                                  _updateSubjectOverallProgress();
                                  widget.onDataChanged();
                                },
                                onAddChild: (targetItem) => _addChildSubMateri(
                                  targetItem,
                                ), // <-- Mengirim referensi child yang tepat
                                onDeleteItem: (targetItem) =>
                                    _deleteSingleSubMateri(
                                      targetItem,
                                    ), // <-- Mengirim referensi child yang tepat
                                onToggleItemType:
                                    _handleToggleItemType, // <-- SUNTIKKAN SINKRONISASI TIPE PROGRESS BARU
                                onUpdateProgressValue:
                                    _showUpdateProgressValueDialog, // <-- SUNTIKKAN SINKRONISASI INPUT ANGKA BARU
                              );
                            }),
                            if (!_hideFinishedItems &&
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
                            if (!_hideFinishedItems)
                              ...List.generate(widget.subject.subMateri.length, (
                                index,
                              ) {
                                final item = widget.subject.subMateri[index];
                                if (item.progress != 'selesai')
                                  return const SizedBox.shrink();
                                return ChecklistTreeView(
                                  item: item,
                                  depth: 0,
                                  isEditMode: _isEditMode,
                                  selectedItems: _selectedItems,
                                  highlightedItem: _highlightedItem,
                                  isFirst: index == 0,
                                  isLast:
                                      index ==
                                      widget.subject.subMateri.length - 1,
                                  onSelectItem: (target, add) => setState(
                                    () => add
                                        ? _selectedItems.add(target)
                                        : _selectedItems.remove(target),
                                  ),
                                  onMoveOrder: _moveItemOrder,
                                  onEditName: (targetItem) =>
                                      _showEditNameDialog(
                                        targetItem,
                                      ), // <-- DIPERBARUI
                                  onLongPressToggle: () => setState(() {
                                    _isEditMode = !_isEditMode;
                                    _selectedItems.clear();
                                  }),
                                  onCheckStatusChanged: (target, checked) {
                                    _saveToHistory();
                                    setState(() {
                                      target.progress = checked == true
                                          ? 'selesai'
                                          : 'belum';
                                      for (var r in widget.subject.subMateri) {
                                        r.updateStatusFromChildren();
                                      }
                                    });
                                    _updateSubjectOverallProgress();
                                    widget.onDataChanged();
                                  },
                                  onTapToggleStatus: (target) {
                                    if (target.itemType == 'progress') {
                                      _showUpdateProgressValueDialog(target);
                                      return;
                                    }
                                    _saveToHistory();
                                    setState(
                                      () => target.progress =
                                          target.progress != 'selesai'
                                          ? 'selesai'
                                          : 'belum',
                                    );
                                    for (var r in widget.subject.subMateri) {
                                      r.updateStatusFromChildren();
                                    }
                                    _updateSubjectOverallProgress();
                                    widget.onDataChanged();
                                  },
                                  onAddChild: (targetItem) =>
                                      _addChildSubMateri(
                                        targetItem,
                                      ), // <-- DIPERBARUI
                                  onDeleteItem: (targetItem) =>
                                      _deleteSingleSubMateri(
                                        targetItem,
                                      ), // <-- DIPERBARUI
                                  onToggleItemType:
                                      _handleToggleItemType, // <-- SUNTIKKAN SINKRONISASI TIPE PROGRESS BARU
                                  onUpdateProgressValue:
                                      _showUpdateProgressValueDialog, // <-- SUNTIKKAN SINKRONISASI INPUT ANGKA BARU
                                );
                              }),
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
            if (_isEditMode) ...[
              Text(
                '${_selectedItems.length} Terpilih',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () => _showMoveSelectedItemsDialog(allFlattened),
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
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () async {
                            final confirm = await _showConfirmDialog(
                              title: 'Hapus Masal',
                              content: 'Hapus seluruh item terpilih?',
                            );
                            if (!confirm) return;
                            setState(() {
                              for (var i in _selectedItems) {
                                _deleteItemFromTree(
                                  widget.subject.subMateri,
                                  i,
                                );
                              }
                              _selectedItems.clear();
                            });
                            _updateSubjectOverallProgress();
                            widget.onDataChanged();
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
                  if (_undoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.blueGrey),
                      onPressed: _executeUndo,
                    ),
                  if (_redoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.redo, color: Colors.blueGrey),
                      onPressed: _redoStack.isEmpty ? null : _executeRedo,
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await _showConfirmDialog(
                        title: 'Reset Progress',
                        content: 'Reset semua progress menjadi Belum Selesai?',
                      );
                      if (!confirm) return;
                      _saveToHistory();
                      void resetRecursive(List<SubSubjectItem> list) {
                        for (var item in list) {
                          item.progress = 'belum';
                          item.finishedDate = null;
                          item.currentValue =
                              0; // Reset hitungan progres angka ke 0 harian
                          resetRecursive(item.subMateri);
                        }
                      }

                      setState(() => resetRecursive(widget.subject.subMateri));
                      _updateSubjectOverallProgress();
                      widget.onDataChanged();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.red),
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
