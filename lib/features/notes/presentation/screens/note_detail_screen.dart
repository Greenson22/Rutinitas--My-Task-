// lib/features/notes/presentation/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
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
    // Controller judul diinisialisasi dengan nilai lama, atau 'Catatan Baru' jika bernilai kosong
    final titleController = TextEditingController(
      text: existingNote != null ? existingNote.title : 'Catatan Baru',
    );
    final contentController = TextEditingController(
      text: existingNote?.content ?? '',
    );

    // Menyimpan status apakah judul sedang dalam mode edit atau tidak
    // Default: jika catatan baru langsung masuk mode edit judul, jika catatan lama dalam mode baca
    bool isEditingTitle = existingNote == null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BasePopupDialog(
            // --- HEADER BERUPA WIDGET DINAMIS ---
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
                        // Jika selesai mengedit dan ternyata kosong, kembalikan ke teks default
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
                  // Sesuai permintaan sebelumnya, kolom input judul lama di body sudah dihilangkan sepenuhnya
                  // Hanya menyisakan area input konten yang responsif
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: () async {
                      // Pastikan nilai judul tidak kosong saat disimpan
                      String finalTitle = titleController.text.trim();
                      if (finalTitle.isEmpty) {
                        finalTitle = existingNote?.title ?? 'Catatan Baru';
                      }

                      setState(() {
                        if (existingNote == null) {
                          // Simpan sebagai Catatan Baru
                          _currentGroup.notes.add(
                            NoteModel(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              title: finalTitle,
                              content: contentController.text.trim(),
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ),
                          );
                        } else {
                          // Simpan Pembaruan Catatan Lama dengan Judul baru/lama hasil edit di header
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
                      if (mounted) Navigator.pop(context);
                    },
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
          );
        },
      ),
    );
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
        return '${note.content}\n\nDibuat: $created\nDiperbarui: $updated';
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
