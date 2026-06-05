// lib/features/notes/presentation/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
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
    return BaseDetailListScreen<NoteModel>(
      pageTitle: _controller.currentGroup.groupName,
      items: _controller.currentGroup.notes,
      enableSearch: true,
      enableMultiSelect: true,
      enableAddButton: true,
      enableFavoriteSort: false,
      itemTitle: (note) => note.title,
      itemSubtitle: (note) {
        String created = _controller.formatDate(note.createdAt);
        String updated = _controller.formatDate(note.updatedAt);
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
      onItemMenuSelected: (value, note) {
        if (value == 'edit') {
          _showNoteDialog(existingNote: note);
        } else if (value == 'delete') {
          _controller.deleteNote(note);
        }
      },
      onDeleteMassive: (selectedItems) {
        _controller.deleteMassiveNotes(selectedItems);
      },
      onMoveMassive: (selectedItems) {},
    );
  }
}
