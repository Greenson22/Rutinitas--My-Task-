// lib/features/daily/presentation/widgets/daily_checklist_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/daily_model.dart';
import 'change_color_dialog.dart';
import '../../../../core/presentation/widgets/base_popup_dialog.dart';

class DailyChecklistDialog extends StatefulWidget {
  final DailySubject subject;
  final VoidCallback onDataChanged;

  const DailyChecklistDialog({
    super.key,
    required this.subject,
    required this.onDataChanged,
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends State<DailyChecklistDialog> {
  final TextEditingController _singleInputController = TextEditingController();
  late TextEditingController _noteController;
  bool _isEditMode = false;
  bool _showControlPanel = false; // Default: tersembunyi (collapsed)
  bool _hideFinishedItems = false; // Filter untuk menyembunyikan item selesai
  final List<SubSubjectItem> _selectedItems = [];
  final List<List<SubSubjectItem>> _undoStack = [];
  final List<List<SubSubjectItem>> _redoStack = [];

  SubSubjectItem? _highlightedItem;
  bool _isNoteModified = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi text controller dengan isi catatan yang sudah ada (jika ada)
    _noteController = TextEditingController(
      text: widget.subject.noteContent ?? '',
    );
  }

  @override
  void dispose() {
    _singleInputController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveToHistory() {
    // Melakukan deep copy seluruh struktur subMateri saat ini sebelum diubah
    final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
        .map((item) => item.clone())
        .toList();

    _undoStack.add(currentSnapshot);
    _redoStack.clear(); // Aksi baru menghapus riwayat Redo ke depan
  }

  void _executeUndo() {
    if (_undoStack.isEmpty) return;

    setState(() {
      // Simpan kondisi saat ini ke Redo Stack sebelum kembali ke masa lalu
      final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
          .map((item) => item.clone())
          .toList();
      _redoStack.add(currentSnapshot);

      // Ambil status terakhir dari Undo Stack
      final previousSnapshot = _undoStack.removeLast();
      widget.subject.subMateri = previousSnapshot;

      _updateSubjectOverallProgress();
    });
    widget.onDataChanged();
  }

  void _executeRedo() {
    if (_redoStack.isEmpty) return;

    setState(() {
      // Simpan kondisi saat ini ke Undo Stack sebelum maju ke depan
      final List<SubSubjectItem> currentSnapshot = widget.subject.subMateri
          .map((item) => item.clone())
          .toList();
      _undoStack.add(currentSnapshot);

      // Ambil status terdepan dari Redo Stack
      final nextSnapshot = _redoStack.removeLast();
      widget.subject.subMateri = nextSnapshot;

      _updateSubjectOverallProgress();
    });
    widget.onDataChanged();
  }

  // Mengubah seluruh status item sub-materi menjadi selesai secara rekursif
  void _markAllSubMateriAsDone() {
    if (widget.subject.subMateri.isEmpty) return;

    _saveToHistory();

    final now = DateTime.now();
    final String formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    void markDoneRecursive(List<SubSubjectItem> list) {
      for (var item in list) {
        item.progress = 'selesai';
        item.finishedDate = formattedDate;
        if (item.subMateri.isNotEmpty) {
          markDoneRecursive(item.subMateri);
        }
      }
    }

    setState(() {
      markDoneRecursive(widget.subject.subMateri);
    });

    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void _showEditSubjectNameDialog() {
    final editController = TextEditingController(
      text: widget.subject.subjectName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Judul Materi'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Nama Materi Baru',
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
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  widget.subject.subjectName = newName;
                });
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

  // Fungsi untuk menukar posisi sub-materi di dalam list-nya secara rekursif
  bool _moveItemInTree(
    List<SubSubjectItem> treeList,
    SubSubjectItem target,
    int direction,
  ) {
    if (treeList.contains(target)) {
      int currentIndex = treeList.indexOf(target);
      int newIndex = currentIndex + direction;

      // Pastikan index baru masih dalam batas aman list
      if (newIndex >= 0 && newIndex < treeList.length) {
        final item = treeList.removeAt(currentIndex);
        treeList.insert(newIndex, item);
        return true;
      }
      return false;
    }

    // Jika tidak ketemu di level ini, cari ke anak-anaknya secara rekursif
    for (var item in treeList) {
      if (_moveItemInTree(item.subMateri, target, direction)) return true;
    }
    return false;
  }

  void _moveItemOrder(SubSubjectItem item, int direction) {
    setState(() {
      _moveItemInTree(widget.subject.subMateri, item, direction);
      _highlightedItem = item; // Tandai item yang dipindahkan
    });
    widget.onDataChanged();

    // Hapus efek highlight setelah 2 detik (2000 milidetik)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          if (_highlightedItem == item) {
            _highlightedItem = null;
          }
        });
      }
    });
  }

  Future<void> _selectSubjectDate(BuildContext context, bool isEndDate) async {
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

  void _addRootSubMateri() async {
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
                setState(() {
                  parentItem.subMateri.add(
                    SubSubjectItem(subjectName: text, progress: 'belum'),
                  );
                });
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
                setState(() {
                  item.subjectName = newName;
                });
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

  void _getAllItemsFlattened(
    List<SubSubjectItem> source,
    List<SubSubjectItem> destination,
  ) {
    for (var element in source) {
      destination.add(element);
      if (element.subMateri.isNotEmpty) {
        _getAllItemsFlattened(element.subMateri, destination);
      }
    }
  }

  void _saveManualNote() {
    setState(() {
      widget.subject.noteContent = _noteController.text;
      _isNoteModified = false;
    });
    widget.onDataChanged();

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Catatan berhasil disimpan!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _updateSubjectOverallProgress() {
    int total = widget.subject.subMateri.length;
    int selesai = widget.subject.subMateri
        .where((sm) => sm.progress == 'selesai')
        .length;

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

  Widget _buildTreeRow(
    SubSubjectItem item,
    int depth,
    int originalIndex, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    bool isChecked = item.progress == 'selesai';
    bool isCurrentlySelected = _selectedItems.contains(item);
    bool isHighlighted = _highlightedItem == item;
    double paddingLeft = (depth * 14.0).clamp(0.0, 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.amber.withOpacity(0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.fromLTRB(paddingLeft, 2, 4, 2),
          child: Row(
            children: [
              if (_isEditMode) ...[
                Checkbox(
                  value: isCurrentlySelected,
                  activeColor: Colors.indigo,
                  onChanged: (bool? checked) {
                    setState(() {
                      void selectChildrenRecursive(
                        SubSubjectItem target,
                        bool add,
                      ) {
                        if (add) {
                          if (!_selectedItems.contains(target))
                            _selectedItems.add(target);
                        } else {
                          _selectedItems.remove(target);
                        }
                        for (var child in target.subMateri) {
                          selectChildrenRecursive(child, add);
                        }
                      }

                      selectChildrenRecursive(item, checked == true);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: isFirst ? Colors.grey[300] : Colors.indigo,
                  onPressed: isFirst ? null : () => _moveItemOrder(item, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                  tooltip: 'Naikkan Posisi',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  color: isLast ? Colors.grey[300] : Colors.indigo,
                  onPressed: isLast ? null : () => _moveItemOrder(item, 1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                  tooltip: 'Turunkan Posisi',
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: _isEditMode
                    ? InkWell(
                        onTap: () => _showEditNameDialog(item),
                        onLongPress: () {
                          setState(() {
                            _isEditMode = false;
                            _selectedItems.clear();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          child: Row(
                            children: [
                              if (item.subMateri.isNotEmpty)
                                const Icon(
                                  Icons.account_tree_outlined,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.subjectName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              const Icon(
                                Icons.edit_note,
                                color: Colors.blueGrey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            activeColor: Colors.teal,
                            onChanged: (bool? checked) {
                              _saveToHistory();

                              setState(() {
                                void changeStatusRecursive(
                                  SubSubjectItem target,
                                  String status,
                                ) {
                                  target.progress = status;
                                  if (status == 'selesai') {
                                    final now = DateTime.now();
                                    target.finishedDate =
                                        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                                  } else {
                                    target.finishedDate = null;
                                  }
                                  for (var child in target.subMateri) {
                                    changeStatusRecursive(child, status);
                                  }
                                }

                                changeStatusRecursive(
                                  item,
                                  checked == true ? 'selesai' : 'belum',
                                );

                                for (var root in widget.subject.subMateri) {
                                  root.updateStatusFromChildren();
                                }
                              });
                              _updateSubjectOverallProgress();
                              widget.onDataChanged();
                            },
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _saveToHistory();

                                if (item.progress != 'selesai') {
                                  setState(() => item.progress = 'selesai');
                                } else {
                                  setState(() => item.progress = 'belum');
                                }
                                for (var root in widget.subject.subMateri) {
                                  root.updateStatusFromChildren();
                                }
                                _updateSubjectOverallProgress();
                                widget.onDataChanged();
                              },
                              onLongPress: () {
                                setState(() {
                                  _isEditMode = true;
                                  _selectedItems.clear();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  item.subjectName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isChecked
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_isEditMode) ...[
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.teal,
                    size: 18,
                  ),
                  tooltip: 'Tambah sub-materi bersarang',
                  onPressed: () => _addChildSubMateri(item),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onPressed: () => _deleteSingleSubMateri(item),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
        ),
        if (item.subMateri.isNotEmpty)
          Column(
            children: List.generate(item.subMateri.length, (index) {
              final child = item.subMateri[index];
              return _buildTreeRow(
                child,
                depth + 1,
                index,
                isFirst: index == 0,
                isLast: index == item.subMateri.length - 1,
              );
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<SubSubjectItem> allFlattened = [];
    _getAllItemsFlattened(widget.subject.subMateri, allFlattened);

    bool isAllSelected =
        allFlattened.isNotEmpty &&
        allFlattened.every((item) => _selectedItems.contains(item));

    return BasePopupDialog(
      themeColor: Color(widget.subject.backgroundColor),
      titleColor: Color(widget.subject.textColor),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
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
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.subject.type == 'note' && _isNoteModified) ...[
                IconButton(
                  icon: const Icon(
                    Icons.save_as,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  tooltip: 'Simpan Perubahan Catatan',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: _saveManualNote,
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                icon: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Ubah Judul Materi',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: _showEditSubjectNameDialog,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 20),
                tooltip: 'Ubah Warna Materi',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ChangeColorDialog(
                      subject: widget.subject,
                      onColorSaved: () {
                        setState(() {});
                        widget.onDataChanged();
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  widget.subject.type == 'note' ? Icons.checklist : Icons.notes,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: widget.subject.type == 'note'
                    ? 'Ubah ke Mode Checklist'
                    : 'Ubah ke Mode Catatan',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
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
              if (widget.subject.type != 'note') ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _showControlPanel ? Icons.tune : Icons.tune_outlined,
                    color: _showControlPanel
                        ? Colors.amberAccent
                        : Colors.white,
                    size: 20,
                  ),
                  tooltip: _showControlPanel
                      ? 'Sembunyikan Pengaturan'
                      : 'Tampilkan Pengaturan',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  onPressed: () =>
                      setState(() => _showControlPanel = !_showControlPanel),
                ),
              ],
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
                ? Container(
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
                                  controller: _singleInputController,
                                  decoration: const InputDecoration(
                                    hintText: 'Tambah sub-materi utama baru...',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _addRootSubMateri(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_box,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Tambah Utama',
                                onPressed: _addRootSubMateri,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.assignment_returned_outlined,
                                  color: Colors.indigo,
                                ),
                                tooltip: 'Paste Banyak Baris dari Clipboard',
                                onPressed: () async {
                                  ClipboardData? data = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (data != null &&
                                      data.text != null &&
                                      data.text!.trim().isNotEmpty) {
                                    List<String> lines = data.text!
                                        .split('\n')
                                        .where((line) => line.trim().isNotEmpty)
                                        .toList();
                                    if (lines.isEmpty) return;
                                    bool? konfirmasi = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Konfirmasi Paste Banyak List',
                                        ),
                                        content: Text(
                                          'Apakah Anda yakin ingin menambahkan ${lines.length} item baru dari clipboard langsung ke materi ini?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                            ),
                                            child: const Text('Ya, Tambahkan'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (konfirmasi != true) return;
                                    int countAdded = 0;
                                    setState(() {
                                      for (var line in lines) {
                                        widget.subject.subMateri.add(
                                          SubSubjectItem(
                                            subjectName: line.trim(),
                                            progress: 'belum',
                                          ),
                                        );
                                        countAdded++;
                                      }
                                    });
                                    if (countAdded > 0) {
                                      _updateSubjectOverallProgress();
                                      widget.onDataChanged();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '⏱ Berhasil menambahkan $countAdded item dari clipboard!',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: Colors.teal[800],
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Clipboard kosong atau tidak berisi teks.',
                                        ),
                                      ),
                                    );
                                  }
                                },
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
                                      value: widget.subject.isDateActive,
                                      activeColor: Colors.teal,
                                      onChanged: (val) {
                                        setState(() {
                                          widget.subject.isDateActive = val;
                                          if (val &&
                                              (widget.subject.date == null ||
                                                  widget
                                                      .subject
                                                      .date!
                                                      .isEmpty)) {
                                            final now = DateTime.now();
                                            widget.subject.date =
                                                "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                                          }
                                        });
                                        widget.onDataChanged();
                                      },
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
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            widget.subject.dateType = val;
                                            if (val == 'range' &&
                                                (widget.subject.endDate ==
                                                        null ||
                                                    widget
                                                        .subject
                                                        .endDate!
                                                        .isEmpty)) {
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
                                    ),
                                  ],
                                  const Spacer(),
                                ],
                              ),
                              if (widget.subject.isDateActive)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            _selectSubjectDate(context, false),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          widget.subject.dateType == 'range'
                                              ? 'Dari: ${widget.subject.date}'
                                              : widget.subject.date ??
                                                    'Pilih Tanggal',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                      if (widget.subject.dateType ==
                                          'range') ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                          ),
                                          child: Text(
                                            '—',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              _selectSubjectDate(context, true),
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
                              if (_isEditMode && allFlattened.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        activeColor: Colors.teal,
                                        value: isAllSelected,
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedItems.clear();
                                              _selectedItems.addAll(
                                                allFlattened,
                                              );
                                            } else {
                                              _selectedItems.clear();
                                            }
                                          });
                                        },
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
                                ),
                              // === KONTROL FITUR BARU: BATCH FINISH & VISIBILITY TOGGLE ===
                              const Divider(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4.0,
                                  bottom: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed:
                                          widget.subject.subMateri.isEmpty
                                          ? null
                                          : _markAllSubMateriAsDone,
                                      icon: const Icon(
                                        Icons.done_all,
                                        size: 16,
                                      ),
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
                                      onPressed: () {
                                        setState(() {
                                          _hideFinishedItems =
                                              !_hideFinishedItems;
                                        });
                                      },
                                      icon: Icon(
                                        _hideFinishedItems
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _hideFinishedItems
                                            ? 'Tampilkan Selesai'
                                            : 'Sembunyikan Selesai',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blueGrey[700],
                                        side: BorderSide(
                                          color: Colors.blueGrey.shade200,
                                        ),
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
                  )
                : const SizedBox.shrink(),
          ),
          Flexible(
            child: widget.subject.type == 'note'
                ? Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _noteController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Tulis catatan Anda di sini...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      onChanged: (text) {
                        final originalText = widget.subject.noteContent ?? '';
                        if (text != originalText && !_isNoteModified) {
                          setState(() => _isNoteModified = true);
                        } else if (text == originalText && _isNoteModified) {
                          setState(() => _isNoteModified = false);
                        }
                      },
                    ),
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
                              return _buildTreeRow(
                                item,
                                0,
                                index,
                                isFirst: index == 0,
                                isLast:
                                    index ==
                                    widget.subject.subMateri.length - 1,
                              );
                            }),
                            // Render seksi pembatas jika filter "Sembunyikan Selesai" tidak aktif
                            if (!_hideFinishedItems &&
                                widget.subject.subMateri.any(
                                  (item) => item.progress == 'selesai',
                                )) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        thickness: 1.5,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0,
                                      ),
                                      child: Text(
                                        'List Telah Selesai',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        thickness: 1.5,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            // Render item selesai hanya jika filter "Sembunyikan Selesai" tidak aktif
                            if (!_hideFinishedItems)
                              ...List.generate(
                                widget.subject.subMateri.length,
                                (index) {
                                  final item = widget.subject.subMateri[index];
                                  if (item.progress != 'selesai')
                                    return const SizedBox.shrink();
                                  return _buildTreeRow(
                                    item,
                                    0,
                                    index,
                                    isFirst: index == 0,
                                    isLast:
                                        index ==
                                        widget.subject.subMateri.length - 1,
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
            if (_isEditMode) ...[
              Text(
                '${_selectedItems.length} Terpilih',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
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
                          for (var item in _selectedItems) {
                            _deleteItemFromTree(widget.subject.subMateri, item);
                          }
                          _selectedItems.clear();
                        });
                        _updateSubjectOverallProgress();
                        widget.onDataChanged();
                      },
                icon: const Icon(
                  Icons.delete_sweep,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Hapus Masal',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ] else ...[
              Row(
                children: [
                  if (_undoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.blueGrey),
                      tooltip: 'Undo Checklist',
                      onPressed: _executeUndo,
                    ),
                  if (_redoStack.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.redo, color: Colors.blueGrey),
                      tooltip: 'Redo Checklist',
                      onPressed: _executeRedo,
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
                          resetRecursive(item.subMateri);
                        }
                      }

                      setState(() {
                        resetRecursive(widget.subject.subMateri);
                      });
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
                onPressed: () => Navigator.pop(context),
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
