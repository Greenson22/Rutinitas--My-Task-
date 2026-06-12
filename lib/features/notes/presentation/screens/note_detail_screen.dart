// lib/features/notes/presentation/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart'; // <-- IMPORT BARU DARI CORE
import 'note_edit_dialog.dart'; // Import file dialog baru

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
    showDialog(
      context: context,
      builder: (dialogContext) =>
          NoteEditDialog(controller: _controller, existingNote: existingNote),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ================= TANGANI KEADAAN AWAL KOSONG DI SINI =================
    if (_controller.currentGroup.notes.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(
          0xFFF5F6FA,
        ), // Menyelaraskan background BaseDetailListScreen
        appBar: AppBar(
          title: Text(
            _controller.currentGroup.groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(
            0xFF3F51B5,
          ), // Menyelaraskan warna AppBar utama (Indigo)
          elevation: 2,
        ),
        body: UniversalEmptyState(
          icon: Icons.note_add_rounded,
          title: 'Belum Ada Catatan',
          description:
              'Grup ini masih kosong dari lembar tulisan. Tekan tombol di bawah untuk membuat catatan teks atau lembar tabel data pertama Anda!',
          buttonLabel: 'Buat Catatan Baru',
          themeColor: const Color(0xFF3F51B5), // Warna tema Indigo
          onPressed: () => _showNoteDialog(),
        ),
      );
    }

    // ================= TAMPILKAN LIST UTAMA JIKA DATA TERSEDIA =================
    return BaseDetailListScreen<NoteModel>(
      pageTitle: _controller.currentGroup.groupName,
      items: _controller.currentGroup.notes,
      enableSearch: true,
      enableMultiSelect: true,
      enableAddButton: true,
      enableFavoriteSort: false,
      itemTitle: (note) => note.title,

      // 1. Mengembalikan Layout Widget Custom dengan Warna Berbeda
      itemSubtitle: (note) {
        String created = _controller.formatDate(note.createdAt);
        String updated = _controller.formatDate(note.updatedAt);
        bool isTable = note.type == 'table';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dibuat: $created',
              style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
            ),
            const SizedBox(height: 1),
            Text(
              'Diperbarui: $updated',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
            if (isTable) ...[
              const SizedBox(height: 2),
              Text(
                'Tipe: Tabel (${note.tableData.length} Baris)',
                style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
      },

      // 2. Mengembalikan data String murni agar sistem search bawaan tetap berfungsi
      itemSearchString: (note) {
        String created = _controller.formatDate(note.createdAt);
        String updated = _controller.formatDate(note.updatedAt);
        String typeInfo = note.type == 'table' ? 'tabel table' : 'text teks';
        return '$created $updated $typeInfo';
      },
      itemIsFavorite: (note) => false,
      onAddPressed: () => _showNoteDialog(),
      onItemTap: (note) => _showNoteDialog(existingNote: note),
      itemMenuBuilder: (note) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: Colors.teal),
              SizedBox(width: 10),
              Text('Edit', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Hapus',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      // PERUBAHAN: Menjadikan method ini asinkron untuk menunggu konfirmasi dialog
      onItemMenuSelected: (value, note) async {
        if (value == 'edit') {
          _showNoteDialog(existingNote: note);
        } else if (value == 'delete') {
          // Memanggil utilitas konfirmasi yang ada di controller Anda
          final bool confirm = await _controller.showConfirmDialog(
            title: 'Hapus Catatan',
            content:
                'Apakah Anda yakin ingin menghapus catatan "${note.title}" secara permanen?',
          );

          // Eksekusi penghapusan hanya jika user memilih "Hapus" (true)
          if (confirm) {
            _controller.deleteNote(note);
          }
        }
      },
      onDeleteMassive: (selectedItems) async {
        await _controller.deleteMassiveNotes(selectedItems);
      },
      onMoveMassive: (selectedItems) {},
    );
  }
}
