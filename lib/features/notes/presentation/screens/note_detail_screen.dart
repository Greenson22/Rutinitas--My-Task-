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

    // Controller khusus untuk form input penambah data baru (Satu Kotak)
    Map<String, TextEditingController> formControllers = {};

    // Inisialisasi controller form input penambah data
    for (var key in currentFieldKeys) {
      formControllers[key] = TextEditingController();
    }

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
    bool isFormVisible = false; // State untuk Toggle Form Input

    // State Pengurutan (Sorting)
    int? sortColumnIndex;
    bool isAscending = true;

    StateSetter? dialogStateSetter;

    // Pemantauan Perubahan
    void triggerChange() {
      if (!hasChanges && dialogStateSetter != null) {
        dialogStateSetter!(() => hasChanges = true);
      }
    }

    titleController.addListener(triggerChange);
    contentController.addListener(triggerChange);

    // Fungsi Pembantu Dialog Konfirmasi Umum
    Future<bool> _showConfirmDialog({
      required String title,
      required String content,
    }) async {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Konfirmasi Hapus'),
                ],
              ),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    // Fungsi Pengelolaan Struktur Field (Kolom)
    void _addFieldKey(StateSetter setDialogState, String key) {
      if (!currentFieldKeys.contains(key)) {
        setDialogState(() {
          currentFieldKeys.add(key);
          formControllers[key] =
              TextEditingController(); // Tambah ke form input
          for (var row in tableRows) {
            row[key] =
                TextEditingController(); // Tambahkan kolom kosong di setiap baris yang sudah ada
          }
          hasChanges = true;
        });
      }
    }

    void _removeFieldKey(StateSetter setDialogState, String key) async {
      final bool confirm = await _showConfirmDialog(
        title: 'Hapus Kolom Baru',
        content:
            'Apakah Anda yakin ingin menghapus kolom "$key"? Seluruh data pada kolom ini di semua baris akan ikut terhapus permanen.',
      );
      if (!confirm) return;

      setDialogState(() {
        currentFieldKeys.remove(key);
        formControllers[key]?.dispose();
        formControllers.remove(key);
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
          title: const Text('Tambah Kolom Baru'),
          content: TextField(
            controller: keyController,
            decoration: const InputDecoration(
              hintText: 'Nama Kolom (misal: No, Nama, Tanggal)',
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
    void _submitFormRow(StateSetter setDialogState) {
      setDialogState(() {
        Map<String, TextEditingController> newRow = {};
        for (var key in currentFieldKeys) {
          // Pindahkan teks dari form input ke baris baru
          newRow[key] = TextEditingController(
            text: formControllers[key]?.text.trim() ?? '',
          );
          // Bersihkan form input setelah disubmit
          formControllers[key]?.clear();
        }
        // Masukkan data baru di posisi paling bawah
        tableRows.add(newRow);
        isFormVisible = false; // Sembunyikan form kembali
        hasChanges = true;
      });
    }

    void _removeRow(StateSetter setDialogState, int index) async {
      final bool confirm = await _showConfirmDialog(
        title: 'Hapus Baris Data',
        content:
            'Apakah Anda yakin ingin menghapus baris data ke-${index + 1} ini secara permanen?',
      );
      if (!confirm) return;

      setDialogState(() {
        final removedRow = tableRows.removeAt(index);
        removedRow.values.forEach((controller) => controller.dispose());
        hasChanges = true;
      });
    }

    // Fungsi Pengurutan Data (Sorting)
    void _sort(StateSetter setDialogState, String key, int columnIndex) {
      setDialogState(() {
        if (sortColumnIndex == columnIndex) {
          isAscending =
              !isAscending; // Balikkan arah urutan jika kolom yang sama ditekan
        } else {
          sortColumnIndex = columnIndex;
          isAscending = true; // Set ascending default untuk kolom baru
        }

        tableRows.sort((a, b) {
          final valA = a[key]?.text.trim().toLowerCase() ?? '';
          final valB = b[key]?.text.trim().toLowerCase() ?? '';
          return isAscending ? valA.compareTo(valB) : valB.compareTo(valA);
        });
        hasChanges =
            true; // Tandai perubahan jika disortir (agar bisa disimpan dalam urutan baru)
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
                                  // Tab Data diputar menjadi yang pertama
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
                                  // TAB 1: DATA TABEL (Daftar Data & Form Input)
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
                                          // Toggle Button untuk menampilkan/menyembunyikan Form
                                          InkWell(
                                            onTap: () => setDialogState(
                                              () => isFormVisible =
                                                  !isFormVisible,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isFormVisible
                                                    ? Colors.indigo.withOpacity(
                                                        0.1,
                                                      )
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.indigo.shade200,
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

                                          // Area Form Input (Animasi Expand/Collapse)
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
                                                                    bottom: 8.0,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  SizedBox(
                                                                    width: 90,
                                                                    child: Text(
                                                                      key,
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child: TextField(
                                                                      controller:
                                                                          formControllers[key],
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
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                6,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                      ),
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
                                                            width:
                                                                double.infinity,
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

                                          // Daftar Baris Data yang Ada (Diubah Menjadi DataTable)
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
                                                    // Widget Tabel dengan Scroll Horizontal dan Vertikal
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
                                                          dataRowMinHeight: 50,
                                                          dataRowMaxHeight: 60,
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
                                                                  key,
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
                                                                    ) => _sort(
                                                                      setDialogState,
                                                                      key,
                                                                      columnIndex,
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
                                                                          150, // Lebar fixed agar textfield tidak error layout
                                                                      padding: const EdgeInsets.symmetric(
                                                                        vertical:
                                                                            4,
                                                                      ),
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
                                                                          enabledBorder: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                            borderSide: BorderSide(
                                                                              color: Colors.grey.shade300,
                                                                            ),
                                                                          ),
                                                                          focusedBorder: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                            borderSide: const BorderSide(
                                                                              color: Colors.indigo,
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
                                                                    onPressed: () =>
                                                                        _removeRow(
                                                                          setDialogState,
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

                                  // TAB 2: PENGATURAN KOLOM
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
    ).then((_) {
      titleController.dispose();
      contentController.dispose();
      for (var row in tableRows) {
        row.values.forEach((controller) => controller.dispose());
      }
      formControllers.values.forEach((controller) => controller.dispose());
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
