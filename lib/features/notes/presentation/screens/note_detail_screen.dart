// lib/features/notes/presentation/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/base_popup_dialog.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteGroup noteGroup;

  const NoteDetailScreen({super.key, required this.noteGroup});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final StorageService _storageService = StorageService();
  late NoteGroup _currentGroup;

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.noteGroup;
  }

  Future<void> _saveCurrentGroup() async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final jsonString = _storageService.formatJsonPretty(
        _currentGroup.toJson(),
      );
      await _storageService.saveNoteGroup(
        baseDir,
        _currentGroup.id,
        jsonString,
      );
    } catch (e) {
      debugPrint("Gagal menyimpan pembaruan grup: $e");
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showNoteDialog({NoteModel? existingNote}) {
    final originalTitle = existingNote != null
        ? existingNote.title
        : 'Catatan Baru';
    final originalContent = existingNote?.content ?? '';
    final originalType = existingNote?.type ?? 'text';

    final titleController = TextEditingController(text: originalTitle);
    final contentController = TextEditingController(text: originalContent);

    // Variabel state untuk Mode Tabel / Berfield
    List<String> currentFieldKeys = List.from(existingNote?.fieldKeys ?? []);
    List<Map<String, TextEditingController>> tableRows = [];

    // Inisialisasi controller baris dari data yang sudah ada
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
    StateSetter? dialogStateSetter;

    // Pemantauan Perubahan
    void triggerChange() {
      if (!hasChanges && dialogStateSetter != null) {
        dialogStateSetter!(() => hasChanges = true);
      }
    }

    titleController.addListener(triggerChange);
    contentController.addListener(triggerChange);

    // Fungsi Pengelolaan Struktur Field (Kolom)
    void _addFieldKey(StateSetter setDialogState, String key) {
      if (!currentFieldKeys.contains(key)) {
        setDialogState(() {
          currentFieldKeys.add(key);
          for (var row in tableRows) {
            row[key] =
                TextEditingController(); // Tambahkan kolom kosong di setiap baris
          }
          hasChanges = true;
        });
      }
    }

    void _removeFieldKey(StateSetter setDialogState, String key) {
      setDialogState(() {
        currentFieldKeys.remove(key);
        for (var row in tableRows) {
          row[key]?.dispose();
          row.remove(key);
        }
        hasChanges = true;
      });
    }

    void _showAddFieldDialog(StateSetter setDialogState) {
      final keyController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tambah Struktur Field'),
          content: TextField(
            controller: keyController,
            decoration: const InputDecoration(
              hintText: 'Nama Field (misal: No, Nama, Tanggal)',
            ),
            autofocus: true,
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
                  _addFieldKey(setDialogState, key);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      );
    }

    // Fungsi Pengelolaan Data Baris
    void _addNewRow(StateSetter setDialogState) {
      setDialogState(() {
        Map<String, TextEditingController> newRow = {};
        for (var key in currentFieldKeys) {
          newRow[key] = TextEditingController();
        }
        tableRows.add(newRow);
        hasChanges = true;
      });
    }

    void _removeRow(StateSetter setDialogState, int index) {
      setDialogState(() {
        final removedRow = tableRows.removeAt(index);
        removedRow.values.forEach((controller) => controller.dispose());
        hasChanges = true;
      });
    }

    // Proses Penyimpanan
    Future<void> performSave(BuildContext dialogCtx) async {
      String finalTitle = titleController.text.trim();
      if (finalTitle.isEmpty) finalTitle = originalTitle;

      List<Map<String, String>> finalTableData = [];
      if (currentType == 'table') {
        for (var rowControllers in tableRows) {
          Map<String, String> rowData = {};
          rowControllers.forEach((key, controller) {
            rowData[key] = controller.text.trim();
          });
          finalTableData.add(rowData);
        }
      }

      setState(() {
        final newNote = NoteModel(
          id:
              existingNote?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: finalTitle,
          content: currentType == 'text' ? contentController.text.trim() : '',
          createdAt: existingNote?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          type: currentType,
          fieldKeys: currentType == 'table' ? currentFieldKeys : [],
          tableData: currentType == 'table' ? finalTableData : [],
        );

        if (existingNote == null) {
          _currentGroup.notes.add(newNote);
        } else {
          final index = _currentGroup.notes.indexWhere(
            (n) => n.id == existingNote.id,
          );
          if (index != -1) _currentGroup.notes[index] = newNote;
        }
      });

      await _saveCurrentGroup();
      if (mounted) Navigator.pop(dialogCtx);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
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
                if (hasChanges) performSave(dialogContext);
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
                      onPressed: () => performSave(dialogContext),
                    ),
                    const SizedBox(width: 10),
                  ],
                  // Tombol Tipe Mode
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
                        currentType = currentType == 'text' ? 'table' : 'text';
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
                            titleController.text.trim().isEmpty)
                          titleController.text =
                              existingNote?.title ?? 'Catatan Baru';
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
                                    text: 'Struktur Field',
                                    icon: Icon(
                                      Icons.build_circle_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  Tab(
                                    text: 'Isi Data',
                                    icon: Icon(
                                      Icons.dataset_outlined,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // TAB 1: STRUKTUR FIELD
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Daftar Field / Kolom:',
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
                                                    'Belum ada struktur field dibuat.',
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
                                                        trailing: IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: Colors
                                                                .redAccent,
                                                            size: 20,
                                                          ),
                                                          onPressed: () =>
                                                              _removeFieldKey(
                                                                setDialogState,
                                                                key,
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
                                              'Tambah Field Baru',
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
                                  // TAB 2: ISI DATA
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: currentFieldKeys.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                    'Buat field di tab Struktur terlebih dahulu.',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  itemCount: tableRows.length,
                                                  itemBuilder: (context, index) {
                                                    final row =
                                                        tableRows[index];
                                                    return Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        side: BorderSide(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                        ),
                                                      ),
                                                      elevation: 0,
                                                      color: Colors.white,
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
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Data Baris #${index + 1}',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .indigo,
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    color: Colors
                                                                        .redAccent,
                                                                    size: 20,
                                                                  ),
                                                                  onPressed: () =>
                                                                      _removeRow(
                                                                        setDialogState,
                                                                        index,
                                                                      ),
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                ),
                                                              ],
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
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    SizedBox(
                                                                      width:
                                                                          100,
                                                                      child: Text(
                                                                        key,
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          color:
                                                                              Colors.black87,
                                                                        ),
                                                                        maxLines:
                                                                            2,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Expanded(
                                                                      child: TextField(
                                                                        controller:
                                                                            row[key],
                                                                        decoration: InputDecoration(
                                                                          isDense:
                                                                              true,
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                8,
                                                                            horizontal:
                                                                                10,
                                                                          ),
                                                                          border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                            borderSide: BorderSide(
                                                                              color: Colors.grey.shade300,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                        ),
                                                                        onChanged:
                                                                            (
                                                                              _,
                                                                            ) =>
                                                                                triggerChange(),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ],
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
                                            onPressed: currentFieldKeys.isEmpty
                                                ? null
                                                : () => _addNewRow(
                                                    setDialogState,
                                                  ),
                                            icon: const Icon(
                                              Icons.add_box,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Tambah Baris Data',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
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
    ).then((_) {
      titleController.dispose();
      contentController.dispose();
      for (var row in tableRows) {
        row.values.forEach((controller) => controller.dispose());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseDetailListScreen<NoteModel>(
      pageTitle: _currentGroup.groupName,
      items: _currentGroup.notes,
      enableSearch: true,
      enableMultiSelect: true,
      enableAddButton: true,
      enableFavoriteSort: false,
      itemTitle: (note) => note.title,
      itemSubtitle: (note) {
        String created = _formatDate(note.createdAt);
        String updated = _formatDate(note.updatedAt);
        // Tambahkan indikator apakah ia tipe tabel yang memiliki data
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
      onItemMenuSelected: (value, note) async {
        if (value == 'edit') {
          _showNoteDialog(existingNote: note);
        } else if (value == 'delete') {
          setState(
            () => _currentGroup.notes.removeWhere((n) => n.id == note.id),
          );
          await _saveCurrentGroup();
        }
      },
      onDeleteMassive: (selectedItems) async {
        setState(() {
          _currentGroup.notes.removeWhere(
            (note) => selectedItems.contains(note),
          );
        });
        await _saveCurrentGroup();
      },
      onMoveMassive: (selectedItems) {},
    );
  }
}
