// lib/features/notes/presentation/screens/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import 'category_notes_screen.dart'; // Import screen detail kategori baru

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Warna tema khusus untuk fitur Notes
  final Color _themeColor = Colors.orange[700]!;

  // State untuk mode edit manual lokal tetap dipertahankan sebagai fallback
  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;

  // DATA DUMMY TELAH DIHAPUS.
  // Untuk keperluan visualisasi awal, struktur Map & List dikosongkan.
  // Di masa mendatang, isi list dan map ini diambil dari database / state management (Bloc/Provider).
  final List<String> _sectionKeys = [];
  final Map<String, List<NoteModel>> _groupedNotes = {};

  @override
  Widget build(BuildContext context) {
    return GroupedSectionLayout<NoteModel>(
      title: 'Catatan Saya',
      drawer: const DrawerMenu(isNotesActive: true),
      isLoading: false,
      isEmpty: _groupedNotes.isEmpty,
      emptyMessage: 'Belum ada catatan. Silakan tambah baru!',
      sectionKeys: _sectionKeys,
      groupedItems: _groupedNotes,

      // ==========================================
      // INTEGRASI PROPERTI GROUPED SECTION LAYOUT
      // ==========================================
      isSelectMode: false,
      selectedItemsCount: 0,
      onClearSelection: () {},
      enableSearch: true,
      enableMultiSelect: false,
      // ==========================================

      // Floating Action Button untuk menambah kategori atau catatan baru
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActionMsg('Tambah catatan baru ditekan');
        },
        backgroundColor: _themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // Menangkap parameter isLayoutEditMode dari internal layout
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
          onDelete: () => _showActionMsg('Hapus kategori: $sectionName'),
          onAddItem: () => _showActionMsg('Tambah item di: $sectionName'),
          onMoveUp: () => _showActionMsg('Pindah ke atas'),
          onMoveDown: () => _showActionMsg('Pindah ke bawah'),
        );
      },

      // Menangkap parameter isLayoutEditMode dari internal layout
      gridItemBuilder: (context, note, index, sectionItems, isLayoutEditMode) {
        return InteractiveGridCard(
          themeColor: _themeColor,
          isEditMode: isLayoutEditMode ? true : _isCardEditMode,
          isFirst: index == 0,
          isLast: index == sectionItems.length - 1,
          onTap: () {
            // Membuka detail catatan spesifik
            _showActionMsg('Membuka catatan: ${note.title}');
          },
          onLongPress: () {
            setState(() {
              _isCardEditMode = !_isCardEditMode;
            });
          },
          onMoveLeft: () => _showActionMsg('Geser kiri: ${note.title}'),
          onMoveRight: () => _showActionMsg('Geser kanan: ${note.title}'),

          // Menu pop-up di mode edit
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

          // Konten visual dalam kartu pratinjau catatan
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

  // Fungsi pembantu untuk menampilkan info aksi sementara
  void _showActionMsg(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
