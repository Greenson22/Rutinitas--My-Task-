// lib/features/notes/presentation/screens/note_edit_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_popup_dialog.dart';

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
  bool _isFormVisible = false;
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

  void _showAddFieldDialog() {
    final keyController = TextEditingController();
    String selectedType = 'String';
    final List<String> availableTypes = [
      'String',
      'Numerik',
      'Date',
      'Time',
      'Boolean',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctxModal, setModalState) => AlertDialog(
          title: const Text('Tambah Kolom Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  hintText: 'Nama Kolom (misal: No, Nama, Tanggal)',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipe Data Kolom',
                  border: OutlineInputBorder(),
                ),
                items: availableTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedType = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final key = keyController.text.trim();
                if (key.isNotEmpty) {
                  widget.controller.addFieldKey(
                    setDialogState: setState,
                    currentFieldKeys: _currentFieldKeys,
                    currentFieldTypes: _currentFieldTypes,
                    formControllers: _formControllers,
                    tableRows: _tableRows,
                    triggerChange: () => setState(() => _hasChanges = true),
                    key: key,
                    type: selectedType,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFormRow() {
    setState(() {
      Map<String, TextEditingController> newRow = {};
      for (var key in _currentFieldKeys) {
        newRow[key] = TextEditingController(
          text: _formControllers[key]?.text.trim() ?? '',
        );
        _formControllers[key]?.text = _currentFieldTypes[key] == 'Boolean'
            ? 'Tidak'
            : '';
      }
      _tableRows.add(newRow);
      _isFormVisible = false;
      _hasChanges = true;
    });
  }

  Widget _buildInputField(String key, TextEditingController controller) {
    String type = _currentFieldTypes[key] ?? 'String';

    InputDecoration inputDecoration = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      suffixIcon: type == 'Date'
          ? const Icon(Icons.calendar_today, size: 16, color: Colors.indigo)
          : type == 'Time'
          ? const Icon(Icons.access_time, size: 16, color: Colors.indigo)
          : null,
    );

    if (type == 'Boolean') {
      if (controller.text != 'Ya' && controller.text != 'Tidak') {
        controller.text = 'Tidak';
      }
      return DropdownButtonFormField<String>(
        value: controller.text,
        decoration: inputDecoration,
        style: const TextStyle(fontSize: 13, color: Colors.black),
        items: const [
          DropdownMenuItem(value: 'Ya', child: Text('Ya')),
          DropdownMenuItem(value: 'Tidak', child: Text('Tidak')),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() {
              controller.text = val;
              _triggerChange();
            });
          }
        },
      );
    }

    return TextField(
      controller: controller,
      keyboardType: type == 'Numerik'
          ? TextInputType.number
          : TextInputType.text,
      readOnly: type == 'Date' || type == 'Time',
      decoration: inputDecoration,
      style: const TextStyle(fontSize: 13),
      onTap: () async {
        if (type == 'Date') {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
              controller.text =
                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              _triggerChange();
            });
          }
        } else if (type == 'Time') {
          TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) {
            setState(() {
              controller.text =
                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
              _triggerChange();
            });
          }
        }
      },
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onChanged: (_) => _triggerChange(),
    );
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
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_currentFieldKeys.isEmpty)
                                    const Expanded(
                                      child: Center(
                                        child: Text(
                                          'Buat kolom di tab Pengaturan Kolom terlebih dahulu.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    InkWell(
                                      onTap: () => setState(
                                        () => _isFormVisible = !_isFormVisible,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isFormVisible
                                              ? Colors.indigo.withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.indigo.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _isFormVisible
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.add_circle_outline,
                                              color: Colors.indigo,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _isFormVisible
                                                  ? 'Sembunyikan Form'
                                                  : 'Tambah Data Baru',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      child: !_isFormVisible
                                          ? const SizedBox.shrink()
                                          : Card(
                                              margin: const EdgeInsets.only(
                                                top: 12,
                                                bottom: 8,
                                              ),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Input Data Baru',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.teal,
                                                      ),
                                                    ),
                                                    const Divider(),
                                                    ..._currentFieldKeys.map((
                                                      key,
                                                    ) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 8.0,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 100,
                                                              child: Text(
                                                                "$key (${_currentFieldTypes[key] ?? 'String'})",
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: _buildInputField(
                                                                key,
                                                                _formControllers[key]!,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                    const SizedBox(height: 8),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        onPressed:
                                                            _submitFormRow,
                                                        icon: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        label: const Text(
                                                          'Simpan ke Tabel',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.teal,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Daftar Data Tersimpan:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: _tableRows.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'Tabel masih kosong.',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.vertical,
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: DataTable(
                                                    sortColumnIndex:
                                                        _sortColumnIndex,
                                                    sortAscending: _isAscending,
                                                    headingRowColor:
                                                        MaterialStateProperty.resolveWith(
                                                          (states) => Colors
                                                              .indigo
                                                              .shade50,
                                                        ),
                                                    dataRowMinHeight: 50,
                                                    dataRowMaxHeight: 60,
                                                    columns: [
                                                      ..._currentFieldKeys.asMap().entries.map((
                                                        entry,
                                                      ) {
                                                        int idx = entry.key;
                                                        String key =
                                                            entry.value;
                                                        return DataColumn(
                                                          label: Text(
                                                            "$key (${_currentFieldTypes[key] ?? 'String'})",
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .indigo,
                                                                ),
                                                          ),
                                                          onSort:
                                                              (
                                                                columnIndex,
                                                                ascending,
                                                              ) => widget.controller.sortTable(
                                                                setDialogState:
                                                                    setState,
                                                                tableRows:
                                                                    _tableRows,
                                                                currentFieldTypes:
                                                                    _currentFieldTypes,
                                                                triggerChange:
                                                                    () => setState(
                                                                      () => _hasChanges =
                                                                          true,
                                                                    ),
                                                                key: key,
                                                                columnIndex:
                                                                    columnIndex,
                                                                currentSortColumnIndex:
                                                                    _sortColumnIndex,
                                                                currentIsAscending:
                                                                    _isAscending,
                                                                onSortUpdated:
                                                                    (
                                                                      colIdx,
                                                                      asc,
                                                                    ) {
                                                                      _sortColumnIndex =
                                                                          colIdx;
                                                                      _isAscending =
                                                                          asc;
                                                                    },
                                                              ),
                                                        );
                                                      }).toList(),
                                                      const DataColumn(
                                                        label: Text(
                                                          'Aksi',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.indigo,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    rows: _tableRows.asMap().entries.map((
                                                      entry,
                                                    ) {
                                                      int index = entry.key;
                                                      var row = entry.value;
                                                      return DataRow(
                                                        cells: [
                                                          ..._currentFieldKeys.map((
                                                            key,
                                                          ) {
                                                            return DataCell(
                                                              Container(
                                                                width: 160,
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                child:
                                                                    _buildInputField(
                                                                      key,
                                                                      row[key]!,
                                                                    ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                          DataCell(
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                color: Colors
                                                                    .redAccent,
                                                                size: 20,
                                                              ),
                                                              onPressed: () => widget
                                                                  .controller
                                                                  .removeRow(
                                                                    setDialogState:
                                                                        setState,
                                                                    tableRows:
                                                                        _tableRows,
                                                                    triggerChange: () =>
                                                                        setState(
                                                                          () => _hasChanges =
                                                                              true,
                                                                        ),
                                                                    index:
                                                                        index,
                                                                  ),
                                                              tooltip:
                                                                  'Hapus Baris',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Definisikan Struktur Kolom Tabel:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _currentFieldKeys.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Belum ada kolom dibuat.',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: _currentFieldKeys.length,
                                            itemBuilder: (ctx, idx) {
                                              final key =
                                                  _currentFieldKeys[idx];
                                              final type =
                                                  _currentFieldTypes[key] ??
                                                  'String';
                                              return Card(
                                                margin: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: ListTile(
                                                  dense: true,
                                                  title: Text(
                                                    key,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    "Tipe Data: $type",
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  trailing: IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => widget
                                                        .controller
                                                        .removeFieldKey(
                                                          setDialogState:
                                                              setState,
                                                          currentFieldKeys:
                                                              _currentFieldKeys,
                                                          currentFieldTypes:
                                                              _currentFieldTypes,
                                                          formControllers:
                                                              _formControllers,
                                                          tableRows: _tableRows,
                                                          triggerChange: () =>
                                                              setState(
                                                                () =>
                                                                    _hasChanges =
                                                                        true,
                                                              ),
                                                          key: key,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _showAddFieldDialog,
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Tambah Kolom Baru',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
