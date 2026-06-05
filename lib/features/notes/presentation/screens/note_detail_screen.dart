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
    final originalFields = existingNote?.fields ?? {};

    final titleController = TextEditingController(text: originalTitle);
    final contentController = TextEditingController(text: originalContent);

    // Inisialisasi map controller untuk menampung data field dinamis
    Map<String, TextEditingController> fieldControllers = {};
    if (existingNote != null && existingNote.fields.isNotEmpty) {
      existingNote.fields.forEach((key, value) {
        fieldControllers[key] = TextEditingController(text: value);
      });
    }

    bool isEditingTitle = existingNote == null;
    String currentType = originalType;
    bool hasChanges = false;
    StateSetter? dialogStateSetter;

    // Pengecekan apakah ada perubahan data (untuk memicu tombol simpan)
    void checkChanges() {
      bool fieldsChanged = false;
      if (currentType == 'field') {
        if (fieldControllers.length != originalFields.length) {
          fieldsChanged = true;
        } else {
          fieldControllers.forEach((key, controller) {
            if (originalFields[key] != controller.text) {
              fieldsChanged = true;
            }
          });
        }
      }

      final changed =
          titleController.text != originalTitle ||
          currentType != originalType ||
          (currentType == 'text' &&
              contentController.text != originalContent) ||
          (currentType == 'field' && fieldsChanged);

      if (hasChanges != changed) {
        if (dialogStateSetter != null) {
          dialogStateSetter!(() {
            hasChanges = changed;
          });
        }
      }
    }

    titleController.addListener(checkChanges);
    contentController.addListener(checkChanges);

    // Dialog untuk menambah nama field baru
    void showAddFieldDialog(StateSetter setDialogState) {
      final keyController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tambah Field Baru'),
          content: TextField(
            controller: keyController,
            decoration: const InputDecoration(
              hintText: 'Nama Field (misal: No, Nama, Alamat)',
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
                if (key.isNotEmpty && !fieldControllers.containsKey(key)) {
                  setDialogState(() {
                    fieldControllers[key] = TextEditingController();
                    hasChanges = true;
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      );
    }

    Future<void> performSave(BuildContext dialogCtx) async {
      String finalTitle = titleController.text.trim();
      if (finalTitle.isEmpty) {
        finalTitle = originalTitle;
      }

      // Ekstrak nilai dari textfield dinamis ke bentuk Map<String, String>
      Map<String, String> finalFields = {};
      if (currentType == 'field') {
        fieldControllers.forEach((key, controller) {
          finalFields[key] = controller.text.trim();
        });
      }

      setState(() {
        if (existingNote == null) {
          _currentGroup.notes.add(
            NoteModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: finalTitle,
              content: currentType == 'text'
                  ? contentController.text.trim()
                  : '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              type: currentType,
              fields: finalFields,
            ),
          );
        } else {
          final index = _currentGroup.notes.indexWhere(
            (n) => n.id == existingNote.id,
          );
          if (index != -1) {
            _currentGroup.notes[index] = NoteModel(
              id: existingNote.id,
              title: finalTitle,
              content: currentType == 'text'
                  ? contentController.text.trim()
                  : '',
              createdAt: existingNote.createdAt,
              updatedAt: DateTime.now(),
              type: currentType,
              fields: finalFields,
            );
          }
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
                if (hasChanges) {
                  performSave(dialogContext);
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
                  // Tombol Simpan
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
                  // Tombol Pilih Tipe Catatan (Sebelah tombol ubah judul)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      currentType == 'text' ? Icons.list_alt : Icons.notes,
                      color: Colors.tealAccent,
                      size: 20,
                    ),
                    tooltip: currentType == 'text'
                        ? 'Ubah ke Catatan Berfield'
                        : 'Ubah ke Catatan Teks',
                    onPressed: () {
                      setDialogState(() {
                        currentType = currentType == 'text' ? 'field' : 'text';
                        checkChanges();
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  // Tombol Ubah / Selesai Judul
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
                        if (isEditingTitle) {
                          if (titleController.text.trim().isEmpty) {
                            titleController.text =
                                existingNote?.title ?? 'Catatan Baru';
                          }
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
                height: MediaQuery.of(context).size.height * 0.6,
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: currentType == 'text'
                    ? Column(
                        children: [
                          Expanded(
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
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              children: fieldControllers.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: entry.value,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: UnderlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                          ),
                                          onChanged: (_) => checkChanges(),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            fieldControllers.remove(entry.key);
                                            checkChanges();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => showAddFieldDialog(setDialogState),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Tambah Field',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
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
      fieldControllers.forEach((_, controller) => controller.dispose());
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
        return 'Dibuat: $created\nDiperbarui: $updated';
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
