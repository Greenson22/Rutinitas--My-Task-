// lib/features/notes/presentation/screens/notes_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import 'category_notes_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final StorageService _storageService = StorageService();
  final Color _themeColor = Colors.orange[700]!;

  bool _isLoading = true;
  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;

  final List<String> _sectionKeys = ['Catatan Utama'];
  final Map<String, List<NoteGroup>> _groupedCategories = {'Catatan Utama': []};

  @override
  void initState() {
    super.initState();
    _loadNotesData();
  }

  Future<void> _loadNotesData() async {
    setState(() => _isLoading = true);
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllNoteGroups(baseDir);

      List<NoteGroup> loadedGroups = [];
      for (var file in files) {
        final content = await file.readAsString();
        loadedGroups.add(NoteGroup.fromJson(jsonDecode(content)));
      }

      setState(() {
        _groupedCategories['Catatan Utama'] = loadedGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Gagal memuat catatan: $e");
    }
  }

  Future<void> _saveGroupData(NoteGroup group) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final jsonString = _storageService.formatJsonPretty(group.toJson());
      await _storageService.saveNoteGroup(baseDir, group.id, jsonString);
    } catch (e) {
      debugPrint("Gagal menyimpan grup: $e");
    }
  }

  Future<void> _deleteGroupData(NoteGroup group) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      await _storageService.deleteNoteGroup(baseDir, group.id);
      setState(() {
        _groupedCategories['Catatan Utama']?.remove(group);
      });
    } catch (e) {
      debugPrint("Gagal menghapus grup: $e");
    }
  }

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
            onPressed: () async {
              final newName = groupController.text.trim();
              if (newName.isNotEmpty) {
                final newGroup = NoteGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  groupName: newName,
                  icon: '📁',
                  notes: [],
                );

                setState(() => _groupedCategories[sectionName]!.add(newGroup));
                await _saveGroupData(newGroup);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(NoteGroup group) {
    final TextEditingController nameController = TextEditingController(
      text: group.groupName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Grup'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Grup Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                setState(() => group.groupName = nameController.text.trim());
                await _saveGroupData(group);
                if (mounted) Navigator.pop(context);
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
      isLoading: _isLoading,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryNotesScreen(noteGroup: noteGroup),
                  ),
                ).then((_) => _loadNotesData());
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
                if (value == 'edit') {
                  _showEditGroupDialog(noteGroup);
                } else if (value == 'delete') {
                  _deleteGroupData(noteGroup);
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
