// lib/features/daily/presentation/widgets/daily_checklist_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- Tambahkan ini di baris paling atas
import '../../data/models/daily_model.dart';
import 'change_color_dialog.dart';

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
  final List<SubSubjectItem> _selectedItems = [];

  SubSubjectItem? _highlightedItem;

  @override
  void dispose() {
    _singleInputController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    List<SubSubjectItem> allFlattened = [];
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
          // HEADER DIALOG
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(
                widget.subject.backgroundColor,
              ), // Mengikuti warna real-time
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
                      // TAMBAHAN TOMBOL PENGUBAH WARNA DI SINI
                      IconButton(
                        icon: const Icon(
                          Icons.palette,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Ubah Warna Materi',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ChangeColorDialog(
                              subject: widget.subject,
                              onColorSaved: () {
                                setState(() {}); // Refresh visual header dialog
                                widget
                                    .onDataChanged(); // Trigger auto-save JSON ke lokal storage
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Flexible(
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
                        // 1. PANEL INPUT UTAMA (DENGAN FITUR PASTE CLIPBOARD)
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
                              // Tombol Tambah Manual (Bawaan)
                              IconButton(
                                icon: const Icon(
                                  Icons.add_box,
                                  color: Colors.teal,
                                ),
                                tooltip: 'Tambah Utama',
                                onPressed: _addRootSubMateri,
                              ),
                              // === TOMBOL BARU: PASTE BANYAK BARIS DARI CLIPBOARD ===
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

                                    // === TAHAP 2: DIALOG KONFIRMASI SEBELUM PASTE ===
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

                                    if (konfirmasi != true)
                                      return; // Batalkan jika memilih tidak/batal

                                    // Proses memasukkan data setelah dikonfirmasi
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
                                      _updateSubjectOverallProgress(); // Memperbarui persentase progress subjek
                                      widget
                                          .onDataChanged(); // Trigger auto-save ke JSON lokal

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
                          isLast: index == widget.subject.subMateri.length - 1,
                        );
                      }),

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
                      ...List.generate(widget.subject.subMateri.length, (
                        index,
                      ) {
                        final item = widget.subject.subMateri[index];
                        if (item.progress != 'selesai')
                          return const SizedBox.shrink();

                        return _buildTreeRow(
                          item,
                          0,
                          index,
                          isFirst: index == 0,
                          isLast: index == widget.subject.subMateri.length - 1,
                        );
                      }),
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

  // WIDGET REKURSIF UNTUK RENDERING NESTED ITEMS (DENGAN HIGHLIGHT)
  Widget _buildTreeRow(
    SubSubjectItem item,
    int depth,
    int originalIndex, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    bool isChecked = item.progress == 'selesai';
    bool isCurrentlySelected = _selectedItems.contains(item);

    // Cek apakah item ini yang sedang mendapatkan efek highlight pemindahan
    bool isHighlighted = _highlightedItem == item;

    // Membatasi tingkat indentasi agar teks yang sangat bersarang tidak meluber ke luar screen
    double paddingLeft = (depth * 14.0).clamp(0.0, 48.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // MENGGANTI PADDING MENJADI ANIMATEDCONTAINER UNTUK EFEK HIGHLIGHT
        AnimatedContainer(
          duration: const Duration(
            milliseconds: 400,
          ), // Durasi transisi warna halus
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            // Jika sedang dihighlight, beri warna latar belakang (misal: kuning/amber transparan)
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
                // TOMBOL URUTAN KE ATAS
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: isFirst ? Colors.grey[300] : Colors.indigo,
                  onPressed: isFirst ? null : () => _moveItemOrder(item, -1),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                  tooltip: 'Naikkan Posisi',
                ),
                // TOMBOL URUTAN KE BAWAH
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

        // Render anak-anak dari item ini secara rekursif
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
