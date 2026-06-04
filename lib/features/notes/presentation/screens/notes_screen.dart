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

  // Struktur: Nama Seksi -> Daftar Grup Catatan
  final List<String> _sectionKeys = ['Catatan Utama'];
  final Map<String, List<NoteGroup>> _groupedCategories = {'Catatan Utama': []};

  void _showAddGroupDialog(String sectionName) {
    final TextEditingController groupController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Grup Catatan Baru'),
        content: TextField(
          controller: groupController,
          decoration: const InputDecoration(
            hintText: 'Misal: Ide Bisnis, Jurnal...',
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
              final newName = groupController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _groupedCategories[sectionName]!.add(
                    NoteGroup(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      groupName: newName,
                      icon: '📁',
                      notes: [],
                    ),
                  );
                });
                Navigator.pop(context);
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
    return GroupedSectionLayout<NoteGroup>(
      title: 'Notes',
      drawer: const DrawerMenu(isNotesActive: true),
      isLoading: false,
      isEmpty: _groupedCategories['Catatan Utama']!.isEmpty,
      emptyMessage: 'Belum ada grup catatan. Buat folder catatan pertama Anda!',
      sectionKeys: _sectionKeys,
      groupedItems: _groupedCategories,
      isSelectMode: false,
      selectedItemsCount: 0,
      onClearSelection: () {},
      enableSearch: true,
      enableMultiSelect: false,
      onAddPressed: () => _showAddGroupDialog(_sectionKeys.first),
      sectionHeaderBuilder: (context, index, sectionName, isLayoutEditMode) {
        return InteractiveSectionHeader(
          sectionName: sectionName,
          themeColor: _themeColor,
          isEditMode: isLayoutEditMode ? true : _isSectionEditMode,
          isFirst: index == 0,
          isLast: index == _sectionKeys.length - 1,
          onToggleEdit: () =>
              setState(() => _isSectionEditMode = !_isSectionEditMode),
          onEditName: () {},
          onDelete: () {},
          onAddItem: () => _showAddGroupDialog(sectionName),
          onMoveUp: () {},
          onMoveDown: () {},
        );
      },
      gridItemBuilder:
          (context, noteGroup, index, sectionItems, isLayoutEditMode) {
            return InteractiveGridCard(
              themeColor: _themeColor,
              isEditMode: isLayoutEditMode ? true : _isCardEditMode,
              isFirst: index == 0,
              isLast: index == sectionItems.length - 1,
              onTap: () {
                // Navigasi ke layar detail item
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryNotesScreen(
                      categoryName: noteGroup.groupName,
                      notes: noteGroup.notes,
                    ),
                  ),
                ).then((_) => setState(() {})); // Segarkan UI saat kembali
              },
              onLongPress: () =>
                  setState(() => _isCardEditMode = !_isCardEditMode),
              onMoveLeft: () {},
              onMoveRight: () {},
              popupMenuItems: const [
                PopupMenuItem(value: 'edit', child: Text('Edit Nama Grup')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Hapus Grup',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              onPopupSelected: (value) {
                if (value == 'delete') {
                  setState(() => sectionItems.remove(noteGroup));
                }
              },
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(noteGroup.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    noteGroup.groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${noteGroup.notes.length} Catatan',
                      style: TextStyle(
                        fontSize: 11,
                        color: _themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
