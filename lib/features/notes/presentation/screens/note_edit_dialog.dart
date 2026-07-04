// lib/features/notes/presentation/screens/note_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:qr_flutter/qr_flutter.dart'; // <--- Impor library QR Flutter
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
  late TextEditingController
  _backContentController; // <--- Controller Sisi Belakang
  late List<String> _currentFieldKeys;
  late Map<String, String> _currentFieldTypes;
  final List<Map<String, TextEditingController>> _tableRows = [];
  final Map<String, TextEditingController> _formControllers = {};
  bool _isEditingTitle = false;
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isViewMode = false; // State untuk mengontrol mode view/edit
  int? _sortColumnIndex;
  bool _isAscending = true;
  bool _isMarkdownEnabled = false;

  // STATE BARU: Mode seleksi QR langsung pada tabel
  bool _isQrSelectMode = false;

  // ANIMASI STATE BARU
  late AnimationController _flipController;
  bool _isFrontSide = true;

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

    _titleController = TextEditingController(text: _originalTitle);
    _contentController = TextEditingController(
      text: _editableNote?.content ?? '',
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

  // =========================================================================
  // FITUR BARU: DIALOG TAMPILAN QR CODE DARI SEL YANG DIKETUK
  // =========================================================================
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
    final NoteModel savedNote = await widget.controller.performSave(
      existingNote: _editableNote,
      originalTitle: _originalTitle,
      currentType: _currentType,
      titleController: _titleController,
      contentController: _contentController,
      backContentController: _backContentController,
      currentFieldKeys: _currentFieldKeys,
      currentFieldTypes: _currentFieldTypes,
      tableRows: _tableRows,
      isMarkdownEnabled: _isMarkdownEnabled,
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
            Text('Perubahan Belum Disimpan'),
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

                // ========================================================
                // MODIFIKASI: TOMBOL QR CODE (MENGAKTIFKAN MODE PILIH LANGSUNG DI TABEL)
                // ========================================================
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
                                ? 'Mode QR Aktif! Ketuk sel data pada tabel di bawah untuk membuat QR Code.'
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

                if (_currentType == 'text' && !_isViewMode && _isFrontSide) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          onChanged: (value) {
                            setState(() => _isMarkdownEnabled = value);
                            _triggerChange();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
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
                isQrSelectMode: _isQrSelectMode, // <--- Oper State Mode QR
                onCellTapForQr: (text) {
                  _showQrCodeDialog(text);
                  setState(
                    () => _isQrSelectMode = false,
                  ); // Nonaktifkan setelah memilih
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
                          isQrSelectMode:
                              _isQrSelectMode, // <--- Oper State Mode QR
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
