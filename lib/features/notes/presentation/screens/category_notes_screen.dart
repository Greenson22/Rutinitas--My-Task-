import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';

class CategoryNotesScreen extends StatelessWidget {
  final String categoryName;
  final List<NoteModel> notes;

  const CategoryNotesScreen({
    super.key,
    required this.categoryName,
    required this.notes,
  });

  // Fungsi pembantu untuk memformat tanggal secara sederhana
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return BaseDetailListScreen<NoteModel>(
      pageTitle: 'Kategori: $categoryName',
      items: notes,
      enableSearch: true,
      enableMultiSelect: true,
      enableAddButton: true,
      enableFavoriteSort:
          false, // Diset false jika model belum memiliki field isFavorite
      // Mengatur judul item
      itemTitle: (note) => note.title,

      // Mengatur subjudul (Menampilkan isi dan tanggal)
      itemSubtitle: (note) {
        String created = _formatDate(note.createdAt);
        String updated = _formatDate(note.updatedAt);
        return '${note.content}\n\nDibuat: $created\nDiperbarui: $updated';
      },

      // Jika tidak ada fitur favorit, kembalikan false
      itemIsFavorite: (note) => false,

      // Aksi ketika tombol tambah (+) ditekan
      onAddPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tambah catatan di kategori $categoryName')),
        );
      },

      // Aksi ketika item catatan di-tap
      onItemTap: (note) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membuka catatan: ${note.title}')),
        );
      },

      // Membangun menu popup pada masing-masing item saat mode biasa / multi-select
      itemMenuBuilder: (note) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'move', child: Text('Pindah Kategori')),
        PopupMenuItem(
          value: 'delete',
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],

      // Aksi ketika menu popup dipilih
      onItemMenuSelected: (value, note) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Memilih $value pada ${note.title}')),
        );
      },

      // Aksi hapus massal (ketika beberapa item dipilih)
      onDeleteMassive: (selectedItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menghapus ${selectedItems.length} catatan')),
        );
      },

      // Aksi pindah massal
      onMoveMassive: (selectedItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Memindah ${selectedItems.length} catatan')),
        );
      },
    );
  }
}
