// lib/features/notes/presentation/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/base_popup_dialog.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteGroup noteGroup;

  const NoteDetailScreen({super.key, required this.noteGroup});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NoteDetailController(
      noteGroup: widget.noteGroup,
      context: context,
      onStateChanged: () => setState(() {}),
    );
  }

  void _showNoteDialog({NoteModel? existingNote}) {
    final originalTitle = existingNote != null
        ? existingNote.title
        : 'Catatan Baru';
    final originalContent = existingNote?.content ?? '';
    final originalType = existingNote?.type ?? 'text';

    final titleController = TextEditingController(text: originalTitle);
    final contentController = TextEditingController(text: originalContent);

    List<String> currentFieldKeys = List.from(existingNote?.fieldKeys ?? []);
    Map<String, String> currentFieldTypes = Map.from(
      existingNote?.fieldTypes ?? {},
    );
    List<Map<String, TextEditingController>> tableRows = [];
    Map<String, TextEditingController> formControllers = {};

    for (var key in currentFieldKeys) {
      String type = currentFieldTypes[key] ?? 'String';
      formControllers[key] = TextEditingController(
        text: type == 'Boolean' ? 'Tidak' : '',
      );
    }

    if (existingNote != null && existingNote.tableData.isNotEmpty) {
      for (var row in existingNote.tableData) {
        Map<String, TextEditingController> rowControllers = {};
        for (var key in currentFieldKeys) {
          rowControllers[key] = TextEditingController(text: row[key] ?? '');
        }
        tableRows.add(rowControllers);
      }
    }

    bool isEditingTitle = existingNote == null;
    String currentType = originalType;
    bool hasChanges = false;
    bool isFormVisible = false;
    bool isSaving = false; // Flag untuk mencegah double save / spam Ctrl+S

    int? sortColumnIndex;
    bool isAscending = true;

    StateSetter? dialogStateSetter;

    void triggerChange() {
      if (!hasChanges && dialogStateSetter != null) {
        dialogStateSetter!(() => hasChanges = true);
      }
    }

    titleController.addListener(triggerChange);
    contentController.addListener(triggerChange);

    Widget _buildInputField(
      String key,
      TextEditingController controller,
      BuildContext ctx,
      StateSetter setDialogState,
    ) {
      String type = currentFieldTypes[key] ?? 'String';

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
              setDialogState(() {
                controller.text = val;
                triggerChange();
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
              context: ctx,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() {
                controller.text =
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                triggerChange();
              });
            }
          } else if (type == 'Time') {
            TimeOfDay? picked = await showTimePicker(
              context: ctx,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setDialogState(() {
                controller.text =
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                triggerChange();
              });
            }
          }
        },
        onChanged: (_) => triggerChange(),
      );
    }

    void _showAddFieldDialog(StateSetter setDialogState) {
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
                    _controller.addFieldKey(
                      setDialogState: setDialogState,
                      currentFieldKeys: currentFieldKeys,
                      currentFieldTypes: currentFieldTypes,
                      formControllers: formControllers,
                      tableRows: tableRows,
                      triggerChange: () =>
                          setDialogState(() => hasChanges = true),
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

    void _submitFormRow(StateSetter setDialogState) {
      setDialogState(() {
        Map<String, TextEditingController> newRow = {};
        for (var key in currentFieldKeys) {
          newRow[key] = TextEditingController(
            text: formControllers[key]?.text.trim() ?? '',
          );
          formControllers[key]?.text = currentFieldTypes[key] == 'Boolean'
              ? 'Tidak'
              : '';
        }
        tableRows.add(newRow);
        isFormVisible = false;
        hasChanges = true;
      });
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _DialogLifecycleWrapper(
        onDispose: () {
          // Dispose dipanggil dengan aman setelah dialog selesai melakukan animasi pop keluar screen
          titleController.dispose();
          contentController.dispose();
          for (var row in tableRows) {
            row.values.forEach((controller) => controller.dispose());
          }
          formControllers.values.forEach((controller) => controller.dispose());
        },
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            dialogStateSetter = setDialogState;

            return Focus(
              onKeyEvent: (node, event) {
                final isControlPressed =
                    HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed;
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.keyS &&
                    isControlPressed) {
                  if (hasChanges && !isSaving) {
                    isSaving =
                        true; // Kunci proses agar tidak tereksekusi ganda
                    _controller.performSave(
                      dialogCtx: dialogContext,
                      existingNote: existingNote,
                      originalTitle: originalTitle,
                      currentType: currentType,
                      titleController: titleController,
                      contentController: contentController,
                      currentFieldKeys: currentFieldKeys,
                      currentFieldTypes: currentFieldTypes,
                      tableRows: tableRows,
                    );
                  }
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: BasePopupDialog(
                title: Row(
                  children: [
                    Expanded(
                      child: isEditingTitle
                          ? TextField(
                              controller: titleController,
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
                              titleController.text,
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
                    if (hasChanges) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.save,
                          color: Colors.amberAccent,
                          size: 20,
                        ),
                        tooltip: 'Simpan Catatan',
                        onPressed: () {
                          if (!isSaving) {
                            isSaving = true;
                            _controller.performSave(
                              dialogCtx: dialogContext,
                              existingNote: existingNote,
                              originalTitle: originalTitle,
                              currentType: currentType,
                              titleController: titleController,
                              contentController: contentController,
                              currentFieldKeys: currentFieldKeys,
                              currentFieldTypes: currentFieldTypes,
                              tableRows: tableRows,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        currentType == 'text'
                            ? Icons.list_alt
                            : Icons.table_chart,
                        color: Colors.tealAccent,
                        size: 20,
                      ),
                      tooltip: currentType == 'text'
                          ? 'Ubah ke Catatan Berfield (Tabel)'
                          : 'Ubah ke Catatan Teks',
                      onPressed: () {
                        setDialogState(() {
                          currentType = currentType == 'text'
                              ? 'table'
                              : 'text';
                          hasChanges = true;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isEditingTitle ? Icons.check : Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                      tooltip: isEditingTitle ? 'Selesai' : 'Ubah Judul',
                      onPressed: () {
                        setDialogState(() {
                          if (isEditingTitle &&
                              titleController.text.trim().isEmpty) {
                            titleController.text =
                                existingNote?.title ?? 'Catatan Baru';
                          }
                          isEditingTitle = !isEditingTitle;
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
                  child: currentType == 'text'
                      ? Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: contentController,
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
                                      icon: Icon(
                                        Icons.dataset_outlined,
                                        size: 18,
                                      ),
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
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (currentFieldKeys.isEmpty)
                                            const Expanded(
                                              child: Center(
                                                child: Text(
                                                  'Buat kolom di tab Pengaturan Kolom terlebih dahulu.',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else ...[
                                            InkWell(
                                              onTap: () => setDialogState(
                                                () => isFormVisible =
                                                    !isFormVisible,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isFormVisible
                                                      ? Colors.indigo
                                                            .withOpacity(0.1)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        Colors.indigo.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      isFormVisible
                                                          ? Icons
                                                                .keyboard_arrow_up
                                                          : Icons
                                                                .add_circle_outline,
                                                      color: Colors.indigo,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      isFormVisible
                                                          ? 'Sembunyikan Form'
                                                          : 'Tambah Data Baru',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                              child: !isFormVisible
                                                  ? const SizedBox.shrink()
                                                  : Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 12,
                                                            bottom: 8,
                                                          ),
                                                      elevation: 2,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12.0,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                              'Input Data Baru',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors.teal,
                                                              ),
                                                            ),
                                                            const Divider(),
                                                            ...currentFieldKeys.map((
                                                              key,
                                                            ) {
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets.only(
                                                                      bottom:
                                                                          8.0,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width:
                                                                          100,
                                                                      child: Text(
                                                                        "$key (${currentFieldTypes[key] ?? 'String'})",
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    Expanded(
                                                                      child: _buildInputField(
                                                                        key,
                                                                        formControllers[key]!,
                                                                        context,
                                                                        setDialogState,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              child: ElevatedButton.icon(
                                                                onPressed: () =>
                                                                    _submitFormRow(
                                                                      setDialogState,
                                                                    ),
                                                                icon: const Icon(
                                                                  Icons.check,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 18,
                                                                ),
                                                                label: const Text(
                                                                  'Simpan ke Tabel',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .teal,
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
                                              child: tableRows.isEmpty
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
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: SingleChildScrollView(
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        child: SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          child: DataTable(
                                                            sortColumnIndex:
                                                                sortColumnIndex,
                                                            sortAscending:
                                                                isAscending,
                                                            headingRowColor:
                                                                MaterialStateProperty.resolveWith(
                                                                  (
                                                                    states,
                                                                  ) => Colors
                                                                      .indigo
                                                                      .shade50,
                                                                ),
                                                            dataRowMinHeight:
                                                                50,
                                                            dataRowMaxHeight:
                                                                60,
                                                            columns: [
                                                              ...currentFieldKeys.asMap().entries.map((
                                                                entry,
                                                              ) {
                                                                int idx =
                                                                    entry.key;
                                                                String key =
                                                                    entry.value;
                                                                return DataColumn(
                                                                  label: Text(
                                                                    "$key (${currentFieldTypes[key] ?? 'String'})",
                                                                    style: const TextStyle(
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
                                                                      ) => _controller.sortTable(
                                                                        setDialogState:
                                                                            setDialogState,
                                                                        tableRows:
                                                                            tableRows,
                                                                        currentFieldTypes:
                                                                            currentFieldTypes,
                                                                        triggerChange: () => setDialogState(
                                                                          () => hasChanges =
                                                                              true,
                                                                        ),
                                                                        key:
                                                                            key,
                                                                        columnIndex:
                                                                            columnIndex,
                                                                        currentSortColumnIndex:
                                                                            sortColumnIndex,
                                                                        currentIsAscending:
                                                                            isAscending,
                                                                        onSortUpdated:
                                                                            (
                                                                              colIdx,
                                                                              asc,
                                                                            ) {
                                                                              sortColumnIndex = colIdx;
                                                                              isAscending = asc;
                                                                            },
                                                                      ),
                                                                );
                                                              }).toList(),
                                                              const DataColumn(
                                                                label: Text(
                                                                  'Aksi',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .indigo,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                            rows: tableRows.asMap().entries.map((
                                                              entry,
                                                            ) {
                                                              int index =
                                                                  entry.key;
                                                              var row =
                                                                  entry.value;
                                                              return DataRow(
                                                                cells: [
                                                                  ...currentFieldKeys.map((
                                                                    key,
                                                                  ) {
                                                                    return DataCell(
                                                                      Container(
                                                                        width:
                                                                            160,
                                                                        padding: const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              4,
                                                                        ),
                                                                        child: _buildInputField(
                                                                          key,
                                                                          row[key]!,
                                                                          dialogContext,
                                                                          setDialogState,
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
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      onPressed: () => _controller.removeRow(
                                                                        setDialogState:
                                                                            setDialogState,
                                                                        tableRows:
                                                                            tableRows,
                                                                        triggerChange: () => setDialogState(
                                                                          () => hasChanges =
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            child: currentFieldKeys.isEmpty
                                                ? const Center(
                                                    child: Text(
                                                      'Belum ada kolom dibuat.',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    itemCount:
                                                        currentFieldKeys.length,
                                                    itemBuilder: (ctx, idx) {
                                                      final key =
                                                          currentFieldKeys[idx];
                                                      final type =
                                                          currentFieldTypes[key] ??
                                                          'String';
                                                      return Card(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              bottom: 8,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: ListTile(
                                                          dense: true,
                                                          title: Text(
                                                            key,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          subtitle: Text(
                                                            "Tipe Data: $type",
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          trailing: IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              color: Colors
                                                                  .redAccent,
                                                              size: 20,
                                                            ),
                                                            onPressed: () => _controller.removeFieldKey(
                                                              setDialogState:
                                                                  setDialogState,
                                                              currentFieldKeys:
                                                                  currentFieldKeys,
                                                              currentFieldTypes:
                                                                  currentFieldTypes,
                                                              formControllers:
                                                                  formControllers,
                                                              tableRows:
                                                                  tableRows,
                                                              triggerChange: () =>
                                                                  setDialogState(
                                                                    () =>
                                                                        hasChanges =
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
                                              onPressed: () =>
                                                  _showAddFieldDialog(
                                                    setDialogState,
                                                  ),
                                              icon: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Tambah Kolom Baru',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
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
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseDetailListScreen<NoteModel>(
      pageTitle: _controller.currentGroup.groupName,
      items: _controller.currentGroup.notes,
      enableSearch: true,
      enableMultiSelect: true,
      enableAddButton: true,
      enableFavoriteSort: false,
      itemTitle: (note) => note.title,
      itemSubtitle: (note) {
        String created = _controller.formatDate(note.createdAt);
        String updated = _controller.formatDate(note.updatedAt);
        String typeInfo = note.type == 'table'
            ? '\nTipe: Tabel (${note.tableData.length} Baris)'
            : '';
        return 'Dibuat: $created\nDiperbarui: $updated$typeInfo';
      },
      itemIsFavorite: (note) => false,
      onAddPressed: () => _showNoteDialog(),
      onItemTap: (note) => _showNoteDialog(existingNote: note),
      itemMenuBuilder: (note) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
      onItemMenuSelected: (value, note) {
        if (value == 'edit') {
          _showNoteDialog(existingNote: note);
        } else if (value == 'delete') {
          _controller.deleteNote(note);
        }
      },
      onDeleteMassive: (selectedItems) {
        _controller.deleteMassiveNotes(selectedItems);
      },
      onMoveMassive: (selectedItems) {},
    );
  }
}

/// Widget helper khusus untuk membungkus State Dialog.
/// Menjamin pelepasan memori (dispose) controller baru terjadi ketika widget dialog benar-benar
/// dihancurkan dan lepas dari visual screen (setelah efek animasi pop transisi fade-out selesai).
class _DialogLifecycleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onDispose;

  const _DialogLifecycleWrapper({required this.child, required this.onDispose});

  @override
  State<_DialogLifecycleWrapper> createState() =>
      _DialogLifecycleWrapperState();
}

class _DialogLifecycleWrapperState extends State<_DialogLifecycleWrapper> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
