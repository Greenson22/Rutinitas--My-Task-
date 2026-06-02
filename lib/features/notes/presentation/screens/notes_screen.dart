import 'package:flutter/material.dart';
import '../../models/note_model.dart';
// Sesuaikan import ini dengan lokasi barrel file atau file template Anda
import '../../../../core/presentation/widgets/widgets.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Warna tema khusus untuk fitur Notes
  final Color _themeColor = Colors.orange[700]!;

  // State untuk mode edit (berlaku global atau per-item sesuai kebutuhan)
  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;

  // Dummy Data
  final List<String> _sectionKeys = ['Penting', 'Pekerjaan', 'Pribadi'];
  final Map<String, List<NoteModel>> _groupedNotes = {
    'Penting': [
      NoteModel(
        id: '1',
        title: 'Ide Proyek',
        content: 'Buat aplikasi manajemen tugas.',
        category: 'Penting',
      ),
      NoteModel(
        id: '2',
        title: 'Belanja',
        content: 'Beli kopi dan susu.',
        category: 'Penting',
      ),
    ],
    'Pekerjaan': [
      NoteModel(
        id: '3',
        title: 'Meeting Klien',
        content: 'Siapkan slide presentasi Q3.',
        category: 'Pekerjaan',
      ),
    ],
    'Pribadi': [], // Contoh seksi kosong
  };

  @override
  Widget build(BuildContext context) {
    return GroupedSectionLayout<NoteModel>(
      title: 'Catatan Saya',
      appBarColor: _themeColor,
      isLoading: false,
      isEmpty: _groupedNotes.isEmpty,
      emptyMessage: 'Belum ada catatan. Silakan tambah baru!',
      sectionKeys: _sectionKeys,
      groupedItems: _groupedNotes,

      // Floating Action Button (opsional)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aksi tambah catatan atau kategori baru
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tambah catatan ditekan')),
          );
        },
        backgroundColor: _themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // 1. Membangun Header Seksi
      sectionHeaderBuilder: (context, index, sectionName) {
        return InteractiveSectionHeader(
          sectionName: sectionName,
          themeColor: _themeColor,
          isEditMode: _isSectionEditMode,
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

      // 2. Membangun Kartu Grid untuk Catatan
      gridItemBuilder: (context, note, index, sectionItems) {
        return InteractiveGridCard(
          themeColor: _themeColor,
          isEditMode: _isCardEditMode,
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

          // Konten visual dalam kartu
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

  // Fungsi pembantu untuk menampilkan aksi (bisa diganti dengan logika asli)
  void _showActionMsg(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}
