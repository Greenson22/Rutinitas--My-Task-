// lib/features/notes/presentation/screens/note_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _NoteEditDialogState extends State<NoteEditDialog> {
  NoteModel? _editableNote;
  late String _originalTitle;
  late String _currentType;

  late TextEditingController _titleController;
  late TextEditingController _contentController;

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

  @override
  void initState() {
    super.initState();
    _editableNote = widget.existingNote;
    _originalTitle = _editableNote != null
        ? _editableNote!.title
        : 'Catatan Baru';
    _currentType = _editableNote?.type ?? 'text';

    // Aktifkan view mode jika membuka catatan yang sudah ada
    _isViewMode = _editableNote != null;

    _titleController = TextEditingController(text: _originalTitle);
    _contentController = TextEditingController(
      text: _editableNote?.content ?? '',
    );

    _currentFieldKeys = List.from(_editableNote?.fieldKeys ?? []);
    _currentFieldTypes = Map.from(_editableNote?.fieldTypes ?? {});

    _initializeFormControllers();
    _initializeTableRows();

    _isEditingTitle = _editableNote == null;
    _titleController.addListener(_triggerChange);
    _contentController.addListener(_triggerChange);
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

  // Perbaikan: Cegah perubahan state jika widget hanya di-render untuk View Mode
  void _triggerChange() {
    if (_isViewMode) return;

    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (var row in _tableRows) {
      row.values.forEach((c) => c.dispose());
    }
    _formControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // Mengubah return type menjadi Future<bool> untuk mengetahui apakah proses simpan berhasil
  Future<bool> _executeSaveAction() async {
    setState(() => _isSaving = true);

    final NoteModel savedNote = await widget.controller.performSave(
      existingNote: _editableNote,
      originalTitle: _originalTitle,
      currentType: _currentType,
      titleController: _titleController,
      contentController: _contentController,
      currentFieldKeys: _currentFieldKeys,
      currentFieldTypes: _currentFieldTypes,
      tableRows: _tableRows,
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
      });
      return true;
    }
    return false;
  }

  // Fungsi untuk menampilkan Pop-up Konfirmasi Simpan/Buang Perubahan
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
          'Apakah Anda ingin menyimpan perubahan pada catatan ini sebelum menutup?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, 'cancel'), // Tetap di dialog edit
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, 'discard'), // Keluar tanpa simpan
            child: const Text(
              'Jangan Simpan',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'save'), // Simpan lalu keluar
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      return await _executeSaveAction(); // Keluar jika simpan berhasil
    } else if (result == 'discard') {
      return true; // Keluar tanpa menyimpan
    }
    return false; // Batalkan proses keluar
  }

  @override
  Widget build(BuildContext context) {
    // Membungkus seluruh hirarki dengan PopScope untuk memantau gesture close/back system
    return PopScope(
      canPop:
          !_hasChanges ||
          _isSaving, // Langsung pop jika tidak ada perubahan atau sedang loading save
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop)
          return; // Jika sudah di-pop oleh sistem, tidak perlu intervensi

        // Tampilkan konfirmasi, jika user memilih simpan/buang (return true), tutup dialog secara manual
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
        child: BasePopupDialog(
          title: Row(
            children: [
              Expanded(
                child: _isEditingTitle
                    ? TextField(
                        controller: _titleController,
                        autofocus: true,
                        cursorColor: Colors.amberAccent,
                        cursorWidth: 2.0,
                        cursorRadius: const Radius.circular(2),
                        textAlignVertical: TextAlignVertical.center,
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
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white24,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.tealAccent,
                              width: 1.5,
                            ),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 6.0),
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

              // Logika Tampilan Tombol berdasarkan View Mode
              if (_isViewMode) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  tooltip: 'Edit Catatan',
                  onPressed: () {
                    setState(() {
                      _isViewMode = false;
                      _hasChanges =
                          false; // Reset paksa flag agar perubahan valid dihitung sejak tombol edit ditekan
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
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _currentType == 'text' ? Icons.list_alt : Icons.table_chart,
                    color: Colors.tealAccent,
                    size: 20,
                  ),
                  tooltip: _currentType == 'text'
                      ? 'Ubah ke Catatan Berfield (Tabel)'
                      : 'Ubah ke Catatan Teks',
                  onPressed: () {
                    setState(() {
                      _currentType = _currentType == 'text' ? 'table' : 'text';
                      _hasChanges = true;
                    });
                  },
                ),
                const SizedBox(width: 10),
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
          content: Container(
            height: MediaQuery.of(context).size.height * 0.65,
            color: Colors.grey[100],
            child: _currentType == 'text'
                ? Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _contentController,
                      readOnly: _isViewMode, // Mencegah ketik jika mode view
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: _isViewMode
                            ? 'Catatan kosong.'
                            : 'Tulis catatan Anda di sini...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  )
                // Menangani tampilan tabel berdasarkan view mode
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
                      isViewMode: true, // Kirim status view mode ke tabel
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
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.indigo,
                            // PERBAIKAN: Parameter 'tabs' yang sebelumnya hilang dimasukkan kembali di sini
                            tabs: [
                              Tab(
                                text: 'Data Tabel',
                                icon: Icon(Icons.dataset_outlined, size: 18),
                              ),
                              Tab(
                                text: 'Pengaturan Kolom',
                                icon: Icon(
                                  Icons.view_column_outlined,
                                  size: 18,
                                ),
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
                      if (shouldPop && context.mounted) {
                        Navigator.pop(context);
                      }
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
    );
  }
}
