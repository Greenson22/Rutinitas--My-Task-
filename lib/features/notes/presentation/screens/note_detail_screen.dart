// lib/features/notes/presentation/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/base_popup_dialog.dart'; // Tambahkan import ini

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
    final titleController = TextEditingController(
      text: existingNote?.title ?? '',
    );
    final contentController = TextEditingController(
      text: existingNote?.content ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => BasePopupDialog(
        title: Text(
          existingNote == null ? 'Catatan Baru' : 'Edit Catatan',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        themeColor: Colors.orange[700] ?? Colors.orange,
        titleColor: Colors.white,

        // --- PERUBAHAN UTAMA DI BAGIAN CONTENT ---
        // Memberikan batasan tinggi (60% dari layar) agar fitur expands: true dapat bekerja
        // dengan baik tanpa menyebabkan error unbound height.
        content: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. Input Judul Borderless
              TextField(
                controller: titleController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Judul Catatan...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(height: 24),
              // 2. Input Konten Borderless (Memenuhi sisa ruang kosong)
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true, // Membuat TextField memanjang secara otomatis
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

        // --- PERUBAHAN UTAMA DI BAGIAN FOOTER ---
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Mendorong elemen ke ujung kiri dan kanan
            children: [
              // Tombol Reset di sebelah kiri
              TextButton.icon(
                onPressed: () {
                  titleController.clear();
                  contentController.clear();
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Tombol Simpan di sebelah kanan
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;

                  setState(() {
                    if (existingNote == null) {
                      _currentGroup.notes.add(
                        NoteModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                    } else {
                      final index = _currentGroup.notes.indexWhere(
                        (n) => n.id == existingNote.id,
                      );
                      if (index != -1) {
                        _currentGroup.notes[index] = NoteModel(
                          id: existingNote.id,
                          title: titleController.text.trim(),
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
