// lib/features/notes/presentation/screens/note_edit_dialog.dart

import 'dart:convert'; // TAMBAHAN: Diperlukan untuk parsing JSON encoder & decoder
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_popup_dialog.dart';
import 'widgets/note_table_data_view.dart';
import 'widgets/note_column_settings_view.dart';

class NoteEditDialog extends StatefulWidget {
  final NoteDetailController controller;
  final NoteModel? existingNote;

  const NoteEditDialog({
    super.key,
    required this.controller,
    this.existingNote,
  });

  @override
  State<NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<NoteEditDialog>
    with SingleTickerProviderStateMixin {
  NoteModel? _editableNote;
  late String _originalTitle;
  late String _currentType;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _backContentController;
  late List<String> _currentFieldKeys;
  late Map<String, String> _currentFieldTypes;

  final List<Map<String, TextEditingController>> _tableRows = [];
  final Map<String, TextEditingController> _formControllers = {};

  bool _isEditingTitle = false;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isViewMode = false;
  int? _sortColumnIndex;
  bool _isAscending = true;
  bool _isMarkdownEnabled = false;
  bool _isQrSelectMode = false;

  late AnimationController _flipController;
  bool _isFrontSide = true;

  // === STATE BARU MULTI-HALAMAN ===
  List<String> _notePages = [];
  int _currentNotePage = 0;

  @override
  void initState() {
    super.initState();
    _editableNote = widget.existingNote;
    _originalTitle = _editableNote != null
        ? _editableNote!.title
        : 'Catatan Baru';
    _currentType = _editableNote?.type ?? 'text';
    _isViewMode = _editableNote != null;
    _isMarkdownEnabled = _editableNote?.isMarkdownEnabled ?? false;

    // === INISIALISASI DATA MULTI-HALAMAN ===
    if (_editableNote != null &&
        _editableNote!.notePages != null &&
        _editableNote!.notePages!.isNotEmpty) {
      _notePages = List.from(_editableNote!.notePages!);
      _currentNotePage = _editableNote!.currentNotePage ?? 0;
    } else {
      // Fallback integrasi berkas lama (1 halaman)
      _notePages = [_editableNote?.content ?? ''];
      _currentNotePage = 0;
    }

    _titleController = TextEditingController(text: _originalTitle);
    _contentController = TextEditingController(
      text: _notePages[_currentNotePage],
    );
    _backContentController = TextEditingController(
      text: _editableNote?.backContent ?? '',
    );
    _currentFieldKeys = List.from(_editableNote?.fieldKeys ?? []);
    _currentFieldTypes = Map.from(_editableNote?.fieldTypes ?? {});

    _initializeFormControllers();
    _initializeTableRows();

    _isEditingTitle = _editableNote == null;
    _titleController.addListener(_triggerChange);
    _contentController.addListener(_triggerChange);
    _backContentController.addListener(_triggerChange);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _initializeFormControllers() {
    for (var key in _currentFieldKeys) {
      String type = _currentFieldTypes[key] ?? 'String';
      _formControllers[key] = TextEditingController(
        text: type == 'Boolean' ? 'Tidak' : '',
      );
    }
  }

  void _initializeTableRows() {
    if (_editableNote != null && _editableNote!.tableData.isNotEmpty) {
      for (var row in _editableNote!.tableData) {
        Map<String, TextEditingController> rowControllers = {};
        for (var key in _currentFieldKeys) {
          rowControllers[key] = TextEditingController(text: row[key] ?? '');
        }
        _tableRows.add(rowControllers);
      }
    }
  }

  void _triggerChange() {
    if (_isViewMode) return;
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _toggleFlip() {
    if (_isFrontSide) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFrontSide = !_isFrontSide;
    });
  }

  // === FUNGSI BANTUAN MANAJEMEN HALAMAN ===
  void _addNewNotePage() {
    if (_currentType != 'text') return;
    setState(() {
      _notePages[_currentNotePage] =
          _contentController.text; // Simpan teks saat ini
      _notePages.add(''); // Buat halaman baru
      _currentNotePage =
          _notePages.length - 1; // Pindahkan fokus ke halaman baru
      _contentController.text = _notePages[_currentNotePage];
      _isViewMode = false;
      _hasChanges = true;
    });
  }

  void _switchNotePage(int newIndex) {
    if (newIndex < 0 || newIndex >= _notePages.length) return;
    setState(() {
      _notePages[_currentNotePage] =
          _contentController.text; // Simpan teks saat ini
      _currentNotePage = newIndex;
      _contentController.text = _notePages[_currentNotePage];
    });

    // === PENERAPAN AUTO-SAVE SAAT PINDAH HALAMAN ===
    if (_editableNote != null) {
      _editableNote!.notePages = _notePages;
      _editableNote!.currentNotePage = _currentNotePage;
      widget.controller
          .saveCurrentGroup(); // Commit dan tulis persisten ke disk
    }
  }

  void _deleteCurrentNotePage() {
    if (_notePages.length <= 1) {
      // Jika hanya ada 1 halaman, reset isi teks ke bentuk awal kosong
      setState(() {
        _notePages[0] = '';
        _contentController.text = '';
        _hasChanges = true;
      });
      return;
    }
    setState(() {
      _notePages.removeAt(_currentNotePage);
      if (_currentNotePage >= _notePages.length) {
        _currentNotePage = _notePages.length - 1;
      }
      _contentController.text = _notePages[_currentNotePage];
      _hasChanges = true;
    });
  }

  void _showQrCodeDialog(String cellText) {
    if (cellText.isEmpty || cellText == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sel kosong atau berupa strip (-). Silakan pilih sel yang terisi.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: const Text(
          'QR Code Sel Tabel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Konten Sel: "$cellText"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: cellText,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text(
                        'Gagal memuat QR Code.',
                        style: TextStyle(color: Colors.red),
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
  }

  // =========================================================================
  // FITUR UTAMA BARU: Dialog Editor Raw JSON Item Catatan (NoteModel)
  // =========================================================================
  void _showEditRawJsonDialog() {
    if (_editableNote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan simpan catatan ini terlebih dahulu sebelum memodifikasi JSON.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController jsonController = TextEditingController();

    try {
      final map = _editableNote!.toJson();
      jsonController.text = const JsonEncoder.withIndent('  ').convert(map);
    } catch (e) {
      jsonController.text = "{}";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.data_object_rounded, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text(
                'Edit Raw JSON Catatan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Peringatan: Perubahan struktur properti JSON wajib valid. Mengubah format secara sembarangan dapat merusak data.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.copy_all,
                            color: Colors.indigo,
                            size: 20,
                          ),
                          tooltip: 'Salin JSON',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: jsonController.text),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'JSON berhasil disalin ke clipboard!',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(
                            Icons.paste,
                            color: Colors.teal,
                            size: 20,
                          ),
                          tooltip: 'Tempel JSON',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final clipboardData = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );
                            if (clipboardData != null &&
                                clipboardData.text != null) {
                              jsonController.text = clipboardData.text!;
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: jsonController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      height: 1.3,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFFF8F9FA),
                      filled: true,
                      hintText:
                          'Tempel atau ketik modifikasi struktur objek JSON catatan disini...',
                    ),
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
              onPressed: () async {
                try {
                  final String rawInput = jsonController.text.trim();
                  if (rawInput.isEmpty)
                    throw Exception("Konten JSON tidak boleh kosong.");
                  final decodedJson = jsonDecode(rawInput);
                  if (decodedJson is! Map<String, dynamic>) {
                    throw const FormatException(
                      'Format root JSON utama wajib berupa Objek Map kriting {...}',
                    );
                  }

                  final parsedNote = NoteModel.fromJson(decodedJson);

                  // Mengunci ID agar tidak berubah secara tidak sengaja untuk mencegah putusnya relasi data
                  parsedNote.id = _editableNote!.id;

                  setState(() {
                    _editableNote = parsedNote;
                    _titleController.text = parsedNote.title;
                    _originalTitle = parsedNote.title;
                    _currentType = parsedNote.type;
                    _isMarkdownEnabled = parsedNote.isMarkdownEnabled;
                    _backContentController.text = parsedNote.backContent;
                    _currentFieldKeys = List.from(parsedNote.fieldKeys);
                    _currentFieldTypes = Map.from(parsedNote.fieldTypes);

                    if (parsedNote.type == 'text' &&
                        parsedNote.notePages != null &&
                        parsedNote.notePages!.isNotEmpty) {
                      _notePages = List.from(parsedNote.notePages!);
                      _currentNotePage = parsedNote.currentNotePage ?? 0;
                      if (_currentNotePage >= _notePages.length)
                        _currentNotePage = 0;
                      _contentController.text = _notePages[_currentNotePage];
                    } else {
                      _contentController.text = parsedNote.content;
                    }

                    // Re-inisialisasi controller visual untuk formulir dan baris tabel
                    _formControllers.clear();
                    _initializeFormControllers();
                    _tableRows.clear();
                    _initializeTableRows();

                    _hasChanges = false;
                    _isViewMode = true;
                  });

                  // Update referensi objek catatan di level list parent group milik controller
                  final indexInGroup = widget.controller.currentGroup.notes
                      .indexWhere((n) => n.id == _editableNote!.id);
                  if (indexInGroup != -1) {
                    widget.controller.currentGroup.notes[indexInGroup] =
                        _editableNote!;
                  }

                  // Komit dan tulis ulang file grup secara persisten ke disk
                  await widget.controller.saveCurrentGroup();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sempurna! Perubahan via JSON catatan berhasil diterapkan.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (err) {
                  debugPrint("Gagal memproses pengeditan JSON Note: $err");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal menyimpan! Format atau parameter JSON tidak valid.\nDetail: $err',
                        ),
                        backgroundColor: Colors.redAccent,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Simpan JSON',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _backContentController.dispose();
    _flipController.dispose();
    for (var row in _tableRows) {
      row.values.forEach((c) => c.dispose());
    }
    _formControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<bool> _executeSaveAction() async {
    setState(() => _isSaving = true);

    // Sinkronisasi teks dari text field ke array sebelum disimpan
    if (_notePages.isNotEmpty &&
        _currentNotePage >= 0 &&
        _currentNotePage < _notePages.length) {
      _notePages[_currentNotePage] = _contentController.text;
    }

    final NoteModel savedNote = await widget.controller.performSave(
      existingNote: _editableNote,
      originalTitle: _originalTitle,
      currentType: _currentType,
      titleController: _titleController,
      contentController: _contentController, // Fallback param
      backContentController: _backContentController,
      currentFieldKeys: _currentFieldKeys,
      currentFieldTypes: _currentFieldTypes,
      tableRows: _tableRows,
      isMarkdownEnabled: _isMarkdownEnabled,
      notePages: _notePages, // Simpan array halamannya
      currentNotePage: _currentNotePage, // Simpan state posisinya
    );

    _editableNote = savedNote;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${savedNote.title}" berhasil disimpan!'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _isViewMode = true;
      });

      return true;
    }
    return false;
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Perubahan Belum Simpan'),
          ],
        ),
        content: const Text(
          'Apakah Anda ingin menyimpan perubahan sebelum menutup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text(
              'Jangan Simpan',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      return await _executeSaveAction();
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Focus(
        onKeyEvent: (node, event) {
          final isControlPressed =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyS &&
              isControlPressed) {
            if (_hasChanges && !_isSaving) {
              _executeSaveAction();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 24.0,
              ),
              constraints: BoxConstraints(
                minWidth: screenWidth * 0.92,
                maxWidth: 960,
              ),
            ),
          ),
          child: BasePopupDialog(
            title: Row(
              children: [
                Expanded(
                  child: _isEditingTitle
                      ? TextField(
                          controller: _titleController,
                          autofocus: true,
                          cursorColor: Colors.amberAccent,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Judul Catatan...',
                            hintStyle: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                          ),
                        )
                      : Text(
                          _titleController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 8),

                // =========================================================================
                // MODIFIKASI POPUP MENU: MENDUKUNG EDIT RAW JSON UNTUK TEKS MAUPUN TABEL
                // =========================================================================
                if ((_currentType == 'text' && !_isViewMode && _isFrontSide) ||
                    (_currentType == 'table' &&
                        _editableNote != null &&
                        !_isViewMode &&
                        _isFrontSide)) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Opsi Catatan',
                    onSelected: (String value) async {
                      if (value == 'add_page') {
                        _addNewNotePage();
                      } else if (value == 'toggle_md') {
                        setState(
                          () => _isMarkdownEnabled = !_isMarkdownEnabled,
                        );
                        _triggerChange();
                      } else if (value == 'edit_raw_json') {
                        _showEditRawJsonDialog();
                      } else if (value == 'delete_page') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Halaman?'),
                            content: const Text(
                              'Apakah Anda yakin ingin menghapus halaman catatan ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _deleteCurrentNotePage();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (_currentType == 'text') ...[
                        PopupMenuItem<String>(
                          value: 'add_page',
                          child: Row(
                            children: const [
                              Icon(
                                Icons.note_add_outlined,
                                color: Colors.indigo,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Tambah Halaman',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'toggle_md',
                          child: Row(
                            children: [
                              Icon(
                                _isMarkdownEnabled
                                    ? Icons.toggle_on
                                    : Icons.toggle_off_outlined,
                                color: _isMarkdownEnabled
                                    ? Colors.teal
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isMarkdownEnabled
                                    ? 'Markdown: Aktif'
                                    : 'Markdown: Nonaktif',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (_notePages.length > 1) ...[
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'delete_page',
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.delete_forever_outlined,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Hapus Halaman Ini',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (_editableNote != null) ...[
                        if (_currentType == 'text') const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'edit_raw_json',
                          child: Row(
                            children: [
                              Icon(
                                Icons.data_object_rounded,
                                color: Colors.deepOrange,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Edit Raw JSON Catatan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 4),
                ],

                if (_currentType == 'table') ...[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.qr_code_2_rounded,
                      color: _isQrSelectMode
                          ? Colors.amberAccent
                          : Colors.tealAccent,
                      size: 22,
                    ),
                    tooltip: _isQrSelectMode
                        ? 'Matikan Mode QR'
                        : 'Pilih Sel Langsung ke QR Code',
                    onPressed: () {
                      setState(() {
                        _isQrSelectMode = !_isQrSelectMode;
                      });
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isQrSelectMode
                                ? 'Mode QR Active! Ketuk sel data pada tabel di bawah untuk membuat QR Code.'
                                : 'Mode QR dinonaktifkan.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                ],

                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _isFrontSide ? Icons.flip_to_back : Icons.flip_to_front,
                    color: Colors.amberAccent,
                    size: 20,
                  ),
                  tooltip: _isFrontSide
                      ? 'Lihat Sisi Belakang'
                      : 'Lihat Sisi Depan',
                  onPressed: _toggleFlip,
                ),
                const SizedBox(width: 10),

                if (_isViewMode) ...[
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    tooltip: 'Edit Catatan',
                    onPressed: () {
                      setState(() {
                        _isViewMode = false;
                        _hasChanges = false;
                      });
                    },
                  ),
                ] else ...[
                  if (_hasChanges) ...[
                    _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.save,
                              color: Colors.amberAccent,
                              size: 20,
                            ),
                            tooltip: 'Simpan Catatan',
                            onPressed: _executeSaveAction,
                          ),
                    const SizedBox(width: 10),
                  ],

                  if (_isFrontSide) ...[
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _currentType == 'text'
                            ? Icons.list_alt
                            : Icons.table_chart,
                        color: Colors.tealAccent,
                        size: 20,
                      ),
                      tooltip: _currentType == 'text'
                          ? 'Ubah ke Catatan Berfield (Tabel)'
                          : 'Ubah ke Catatan Teks',
                      onPressed: () {
                        setState(() {
                          _currentType = _currentType == 'text'
                              ? 'table'
                              : 'text';
                          _hasChanges = true;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                  ],

                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isEditingTitle ? Icons.check : Icons.edit,
                      color: Colors.white,
                      size: 18,
                    ),
                    tooltip: _isEditingTitle ? 'Selesai' : 'Ubah Judul',
                    onPressed: () {
                      setState(() {
                        if (_isEditingTitle &&
                            _titleController.text.trim().isEmpty) {
                          _titleController.text =
                              _editableNote?.title ?? 'Catatan Baru';
                        }
                        _isEditingTitle = !_isEditingTitle;
                      });
                    },
                  ),
                ],
              ],
            ),
            themeColor: Colors.indigo,
            titleColor: Colors.white,
            content: AnimatedBuilder(
              animation: _flipController,
              builder: (context, child) {
                final double angle = _flipController.value * 3.141592653589793;
                final bool isBackRendering = angle >= 1.5707963267948966;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isBackRendering
                      ? Transform(
                          transform: Matrix4.identity()
                            ..rotateY(3.141592653589793),
                          alignment: Alignment.center,
                          child: _buildBackSideContent(),
                        )
                      : _buildFrontSideContent(),
                );
              },
            ),
            footer: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentType == 'text' &&
                      _isFrontSide &&
                      _notePages.length > 1) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.indigo,
                      ),
                      onPressed: _currentNotePage > 0
                          ? () => _switchNotePage(_currentNotePage - 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        '${_currentNotePage + 1} / ${_notePages.length}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.indigo,
                      ),
                      onPressed: _currentNotePage < _notePages.length - 1
                          ? () => _switchNotePage(_currentNotePage + 1)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                  ],

                  ElevatedButton(
                    onPressed: () async {
                      if (_hasChanges) {
                        final shouldPop = await _showExitConfirmationDialog();
                        if (shouldPop && context.mounted)
                          Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSideContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      color: Colors.grey[100],
      child: _currentType == 'text'
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: _isViewMode
                  ? (_isMarkdownEnabled
                        ? Markdown(
                            data: _contentController.text.isEmpty
                                ? '*Catatan kosong.*'
                                : _contentController.text,
                            selectable: true,
                          )
                        : TextField(
                            controller: _contentController,
                            readOnly: true,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ))
                  : TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        fontFamily: _isMarkdownEnabled ? 'Courier' : null,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
            )
          : _isViewMode
          ? Container(
              color: Colors.white,
              child: NoteTableDataView(
                controller: widget.controller,
                currentFieldKeys: _currentFieldKeys,
                currentFieldTypes: _currentFieldTypes,
                tableRows: _tableRows,
                formControllers: _formControllers,
                sortColumnIndex: _sortColumnIndex,
                isAscending: _isAscending,
                onChanged: _triggerChange,
                isViewMode: true,
                isQrSelectMode: _isQrSelectMode,
                onCellTapForQr: (text) {
                  _showQrCodeDialog(text);
                  setState(() => _isQrSelectMode = false);
                },
                onSortChanged: (index, ascending) {
                  setState(() {
                    _sortColumnIndex = index;
                    _isAscending = ascending;
                  });
                },
              ),
            )
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: const TabBar(
                      labelColor: Colors.indigo,
                      indicatorColor: Colors.indigo,
                      tabs: [
                        Tab(
                          text: 'Data Tabel',
                          icon: Icon(Icons.dataset_outlined, size: 18),
                        ),
                        Tab(
                          text: 'Pengaturan Kolom',
                          icon: Icon(Icons.view_column_outlined, size: 18),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        NoteTableDataView(
                          controller: widget.controller,
                          currentFieldKeys: _currentFieldKeys,
                          currentFieldTypes: _currentFieldTypes,
                          tableRows: _tableRows,
                          formControllers: _formControllers,
                          sortColumnIndex: _sortColumnIndex,
                          isAscending: _isAscending,
                          onChanged: _triggerChange,
                          isViewMode: false,
                          isQrSelectMode: _isQrSelectMode,
                          onCellTapForQr: (text) {
                            _showQrCodeDialog(text);
                            setState(() => _isQrSelectMode = false);
                          },
                          onSortChanged: (index, ascending) {
                            setState(() {
                              _sortColumnIndex = index;
                              _isAscending = ascending;
                            });
                          },
                        ),
                        NoteColumnSettingsView(
                          controller: widget.controller,
                          currentFieldKeys: _currentFieldKeys,
                          currentFieldTypes: _currentFieldTypes,
                          tableRows: _tableRows,
                          formControllers: _formControllers,
                          onChanged: _triggerChange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBackSideContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      color: Colors.blueGrey[50],
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  color: Colors.indigo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Catatan Dibalik Lembar Utama',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SISI BELAKANG',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: TextField(
                controller: _backContentController,
                maxLines: null,
                expands: true,
                readOnly: _isViewMode,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
