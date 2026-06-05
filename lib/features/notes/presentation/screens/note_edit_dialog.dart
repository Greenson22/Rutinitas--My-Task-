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

  void _triggerChange() {
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

  void _executeSaveAction() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Judul Catatan...',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
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
            if (_hasChanges) ...[
              _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  if (_isEditingTitle && _titleController.text.trim().isEmpty) {
                    _titleController.text =
                        _editableNote?.title ?? 'Catatan Baru';
                  }
                  _isEditingTitle = !_isEditingTitle;
                });
              },
            ),
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
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Tulis catatan Anda di sini...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
    );
  }
}
