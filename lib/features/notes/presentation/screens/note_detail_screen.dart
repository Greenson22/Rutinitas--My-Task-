// lib/features/notes/presentation/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ditambahkan untuk LogicalKeyboardKey & HardwareKeyboard
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

    final titleController = TextEditingController(text: originalTitle);
    final contentController = TextEditingController(text: originalContent);

    bool isEditingTitle = existingNote == null;
    bool hasChanges = false;
    StateSetter? dialogStateSetter;

    // Fungsi untuk mengecek apakah ada perubahan
    void checkChanges() {
      final changed =
          titleController.text != originalTitle ||
          contentController.text != originalContent;

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

    // Fungsi Eksekusi Simpan
    Future<void> performSave(BuildContext dialogCtx) async {
      String finalTitle = titleController.text.trim();
      if (finalTitle.isEmpty) {
        finalTitle = originalTitle;
      }

      setState(() {
        if (existingNote == null) {
          // Simpan sebagai Catatan Baru
          _currentGroup.notes.add(
            NoteModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: finalTitle,
              content: contentController.text.trim(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          // Simpan Pembaruan Catatan Lama
          final index = _currentGroup.notes.indexWhere(
            (n) => n.id == existingNote.id,
          );
          if (index != -1) {
            _currentGroup.notes[index] = NoteModel(
              id: existingNote.id,
              title: finalTitle,
              content: contentController.text.trim(),
              createdAt: existingNote.createdAt,
              updatedAt: DateTime.now(),
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
            // Menangkap event shortcut keyboard (Ctrl+S atau Cmd+S)
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
              themeColor: Colors.orange[700] ?? Colors.orange,
              titleColor: Colors.white,
              content: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                    // Tombol simpan hanya di-render jika ada perubahan
                    if (hasChanges)
                      ElevatedButton(
                        onPressed: () => performSave(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                        ),
                        child: const Text(
                          'Simpan',
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
      // Bersihkan controller saat dialog tertutup
      titleController.dispose();
      contentController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseDetailListScreen<NoteModel>(
      pageTitle: 'Kategori: ${_currentGroup.groupName}',
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
