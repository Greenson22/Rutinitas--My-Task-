// lib/features/daily/presentation/widgets/daily_checklist_dialog.dart

import 'package:flutter/material.dart';
import '../../data/models/daily_model.dart';

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
  bool _isEditMode = false;
  bool _showControlPanel = false; // Default: tersembunyi (collapsed)
  final List<SubMateriItem> _selectedItems = [];

  @override
  void dispose() {
    _singleInputController.dispose();
    super.dispose();
  }

  void _showEditSubjectNameDialog() {
    final editController = TextEditingController(
      text: widget.subject.namaMateri,
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
                  widget.subject.namaMateri = newName;
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

    final confirm = await _showConfirmDialog(
      title: 'Tambah Sub-Materi Utama',
      content: 'Apakah Anda yakin ingin menambahkan sub-materi "$text"?',
    );

    if (!confirm) return;

    setState(() {
      widget.subject.subMateri.add(
        SubMateriItem(namaMateri: text, progress: 'belum'),
      );
      _singleInputController.clear();
    });
    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void _addChildSubMateri(SubMateriItem parentItem) {
    final childController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Anak di bawah "${parentItem.namaMateri}"'),
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
                    SubMateriItem(namaMateri: text, progress: 'belum'),
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

  bool _deleteItemFromTree(List<SubMateriItem> treeList, SubMateriItem target) {
    if (treeList.contains(target)) {
      treeList.remove(target);
      return true;
    }
    for (var item in treeList) {
      if (_deleteItemFromTree(item.subMateri, target)) return true;
    }
    return false;
  }

  void _deleteSingleSubMateri(SubMateriItem item) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Sub-Materi',
      content:
          'Apakah Anda yakin ingin menghapus "${item.namaMateri}" beserta seluruh turunannya?',
    );

    if (!confirm) return;

    setState(() {
      _deleteItemFromTree(widget.subject.subMateri, item);
      _selectedItems.remove(item);
    });

    _updateSubjectOverallProgress();
    widget.onDataChanged();
  }

  void _showEditNameDialog(SubMateriItem item) {
    final editController = TextEditingController(text: item.namaMateri);
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
                  item.namaMateri = newName;
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
    List<SubMateriItem> source,
    List<SubMateriItem> destination,
  ) {
    for (var element in source) {
      destination.add(element);
      if (element.subMateri.isNotEmpty) {
        _getAllItemsFlattened(element.subMateri, destination);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<SubMateriItem> allFlattened = [];
    _getAllItemsFlattened(widget.subject.subMateri, allFlattened);

    bool isAllSelected =
        allFlattened.isNotEmpty &&
        allFlattened.every((item) => _selectedItems.contains(item));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER DIALOG
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(widget.subject.backgroundColor),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Ubah Judul Materi',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: _showEditSubjectNameDialog,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${widget.subject.namaMateri} ',
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol toggle untuk Sembunyikan/Tampilkan Panel Kontrol
                IconButton(
                  icon: Icon(
                    _showControlPanel ? Icons.tune : Icons.tune_outlined,
                    color: _showControlPanel
                        ? Colors.amberAccent
                        : Colors.white,
                  ),
                  tooltip: _showControlPanel
                      ? 'Sembunyikan Pengaturan'
                      : 'Tampilkan Pengaturan',
                  onPressed: () {
                    setState(() {
                      _showControlPanel = !_showControlPanel;
                    });
                  },
                ),
              ],
            ),
          ),

          // PANEL KONTROL YANG BISA DI-COLLAPSE (Tersembunyi secara default)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showControlPanel
                ? Container(
                    color: Colors.grey.shade50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. PANEL INPUT UTAMA
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
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_box,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Tambah Utama',
                                onPressed: _addRootSubMateri,
                              ),
                            ],
                          ),
                        ),

                        // 2. PANEL KONTROL TANGGAL & MODE EDIT MASAL
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
                                  // Menggeser tombol edit massal ke panel atas yang bisa dicollapse
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                    ),
                                    icon: Icon(
                                      _isEditMode
                                          ? Icons.check_circle
                                          : Icons.edit,
                                      size: 16,
                                      color: Colors.teal,
                                    ),
                                    label: Text(
                                      _isEditMode ? 'Selesai' : 'Mode Edit',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isEditMode = !_isEditMode;
                                        _selectedItems.clear();
                                      });
                                    },
                                  ),
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
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // KONTEN TREE LIST
          Flexible(
            child: widget.subject.subMateri.isEmpty
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
                      // 1. Tampilkan sub-materi yang BELUM SELESAI
                      ...widget.subject.subMateri
                          .where((item) => item.progress != 'selesai')
                          .map(
                            (item) => _buildTreeRow(
                              item,
                              0,
                              widget.subject.subMateri.indexOf(item),
                            ),
                          )
                          .toList(),

                      // 2. Berikan Garis Pembatas dan Keterangan jika ada item yang selesai
                      if (widget.subject.subMateri.any(
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

                      // 3. Tampilkan sub-materi yang SUDAH SELESAI di paling bawah
                      ...widget.subject.subMateri
                          .where((item) => item.progress == 'selesai')
                          .map(
                            (item) => _buildTreeRow(
                              item,
                              0,
                              widget.subject.subMateri.indexOf(item),
                            ),
                          )
                          .toList(),
                    ],
                  ),
          ),
          const Divider(height: 1),

          // FOOTER PANEL ACTION
          Padding(
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
                                _deleteItemFromTree(
                                  widget.subject.subMateri,
                                  item,
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
                      size: 18,
                    ),
                    label: const Text(
                      'Hapus Masal',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await _showConfirmDialog(
                        title: 'Reset Progress',
                        content: 'Reset semua progress menjadi Belum Selesai?',
                      );
                      if (!confirm) return;
                      void resetRecursive(List<SubMateriItem> list) {
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
        ],
      ),
    );
  }

  // WIDGET REKURSIF UNTUK RENDERING NESTED ITEMS (DIPERBARUI)
  Widget _buildTreeRow(SubMateriItem item, int depth, int originalIndex) {
    bool isChecked = item.progress == 'selesai';
    bool isCurrentlySelected = _selectedItems.contains(item);

    // Membatasi tingkat indentasi agar teks yang sangat bersarang tidak meluber ke luar screen
    double paddingLeft = (depth * 14.0).clamp(0.0, 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(paddingLeft, 2, 4, 2),
          child: Row(
            children: [
              if (_isEditMode)
                Checkbox(
                  value: isCurrentlySelected,
                  activeColor: Colors.indigo,
                  onChanged: (bool? checked) {
                    setState(() {
                      void selectChildrenRecursive(
                        SubMateriItem target,
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

              // Konten Utama Baris
              Expanded(
                child: _isEditMode
                    ? InkWell(
                        onTap: () => _showEditNameDialog(item),
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
                                  item.namaMateri,
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
                              setState(() {
                                void changeStatusRecursive(
                                  SubMateriItem target,
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
                              child: Text(
                                item.namaMateri,
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
                        ],
                      ),
              ),

              if (_isEditMode)
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
              if (_isEditMode)
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
          ),
        ),

        // Render anak-anak dari item ini secara rekursif
        if (item.subMateri.isNotEmpty)
          Column(
            children: item.subMateri
                .map(
                  (child) => _buildTreeRow(
                    child,
                    depth + 1,
                    item.subMateri.indexOf(child),
                  ),
                )
                .toList(),
          ),
      ],
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
}
