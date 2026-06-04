// lib/features/notes/presentation/screens/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import 'category_notes_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Color _themeColor = Colors.orange[700]!;

  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;

  // State lokal untuk visualisasi fitur UI
  final List<String> _sectionKeys = [];
  final Map<String, List<NoteModel>> _groupedNotes = {};

  // ==========================================
  // FITUR: TAMBAH GROUP / KATEGORI
  // ==========================================
  void _showAddGroupDialog() {
    final TextEditingController groupController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: groupController,
          decoration: const InputDecoration(
            hintText: 'Nama Kategori (Misal: Ide, Pekerjaan)...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newGroupName = groupController.text.trim();
              if (newGroupName.isNotEmpty) {
                setState(() {
                  // Mencegah duplikasi nama kategori
                  if (!_sectionKeys.contains(newGroupName)) {
                    _sectionKeys.add(newGroupName);
                    _groupedNotes[newGroupName] = [];
                  }
                });
                Navigator.pop(context);
                _showActionMsg(
                  'Kategori "$newGroupName" berhasil ditambahkan!',
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GroupedSectionLayout<NoteModel>(
      title: 'Catatan Saya',
      drawer: const DrawerMenu(isNotesActive: true),
      isLoading: false,
      isEmpty: _groupedNotes.isEmpty,
      emptyMessage:
          'Belum ada grup catatan. Tekan tombol + di atas untuk membuat kategori!',
      sectionKeys: _sectionKeys,
      groupedItems: _groupedNotes,

      isSelectMode: false,
      selectedItemsCount: 0,
      onClearSelection: () {},
      enableSearch: true,
      enableMultiSelect: false,

      // Menghubungkan fungsi ke tombol Add (+) di AppBar bawaan layout
      onAddPressed: _showAddGroupDialog,

      sectionHeaderBuilder: (context, index, sectionName, isLayoutEditMode) {
        return InteractiveSectionHeader(
          sectionName: sectionName,
          themeColor: _themeColor,
          isEditMode: isLayoutEditMode ? true : _isSectionEditMode,
          isFirst: index == 0,
          isLast: index == _sectionKeys.length - 1,
          onToggleEdit: () {
            setState(() {
              _isSectionEditMode = !_isSectionEditMode;
            });
          },
          onEditName: () => _showActionMsg('Edit nama kategori: $sectionName'),
          onDelete: () {
            // Logika hapus grup sementara di UI
            setState(() {
              _sectionKeys.remove(sectionName);
              _groupedNotes.remove(sectionName);
            });
            _showActionMsg('Kategori $sectionName dihapus');
          },
          onAddItem: () => _showActionMsg('Tambah item di: $sectionName'),
          onMoveUp: () => _showActionMsg('Pindah ke atas'),
          onMoveDown: () => _showActionMsg('Pindah ke bawah'),
        );
      },

      gridItemBuilder: (context, note, index, sectionItems, isLayoutEditMode) {
        return InteractiveGridCard(
          themeColor: _themeColor,
          isEditMode: isLayoutEditMode ? true : _isCardEditMode,
          isFirst: index == 0,
          isLast: index == sectionItems.length - 1,
          onTap: () {
            _showActionMsg('Membuka catatan: ${note.title}');
          },
          onLongPress: () {
            setState(() {
              _isCardEditMode = !_isCardEditMode;
            });
          },
          onMoveLeft: () => _showActionMsg('Geser kiri: ${note.title}'),
          onMoveRight: () => _showActionMsg('Geser kanan: ${note.title}'),

          popupMenuItems: const [
            PopupMenuItem(value: 'edit', child: Text('Edit Catatan')),
            PopupMenuItem(value: 'move', child: Text('Pindah Kategori')),
            PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
          onPopupSelected: (value) {
            _showActionMsg('Pilih pop-up [$value] pada: ${note.title}');
          },

          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.text_snippet_rounded, color: _themeColor, size: 28),
              const SizedBox(height: 8),
              Text(
                note.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  note.content,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActionMsg(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
