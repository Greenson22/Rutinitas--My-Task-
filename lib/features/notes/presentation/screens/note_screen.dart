// lib/features/notes/presentation/screens/notes_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final StorageService _storageService = StorageService();
  final Color _themeColor = Colors.indigo;

  bool _isLoading = true;
  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;

  // Variabel untuk menyimpan query pencarian
  String _searchQuery = '';

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

  // Fungsi untuk memfilter list kategori berdasarkan query pencarian
  Map<String, List<NoteGroup>> _getFilteredCategories() {
    if (_searchQuery.isEmpty) return _groupedCategories;

    Map<String, List<NoteGroup>> filtered = {};
    for (var key in _sectionKeys) {
      filtered[key] = (_groupedCategories[key] ?? []).where((group) {
        return group.groupName.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
      }).toList();
    }
    return filtered;
  }

  void _showAddGroupDialog(String sectionName) {
    final TextEditingController groupController = TextEditingController();
    final TextEditingController iconController = TextEditingController(
      text: '📁',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Grup Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: 'Nama Grup Catatan',
                hintText: 'Misal: Ide Bisnis, Jurnal...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Ikon Emoji'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = groupController.text.trim();
              final newIcon = iconController.text.trim();
              if (newName.isNotEmpty) {
                final newGroup = NoteGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  groupName: newName,
                  icon: newIcon.isEmpty ? '📁' : newIcon,
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

  // PERUBAHAN: Mengubah dialog edit agar mendukung perubahan nama sekaligus ikon emoji
  void _showEditGroupDialog(NoteGroup group) {
    final TextEditingController nameController = TextEditingController(
      text: group.groupName,
    );
    final TextEditingController iconController = TextEditingController(
      text: group.icon,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama & Ikon Grup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Grup Baru'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Ikon Emoji Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedName = nameController.text.trim();
              final updatedIcon = iconController.text.trim();
              if (updatedName.isNotEmpty) {
                setState(() {
                  group.groupName = updatedName;
                  group.icon = updatedIcon.isEmpty ? '📁' : updatedIcon;
                });
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
    // Ambil data yang sudah difilter
    final filteredCategories = _getFilteredCategories();

    return GroupedSectionLayout<NoteGroup>(
      title: 'Note Groups',
      drawer: const DrawerMenu(isNotesActive: true),
      isLoading: _isLoading,
      isEmpty: _groupedCategories['Catatan Utama']!.isEmpty,
      emptyMessage: 'Belum ada grup catatan. Buat folder catatan pertama Anda!',
      sectionKeys: _sectionKeys,
      groupedItems: filteredCategories,
      isSelectMode: false,
      selectedItemsCount: 0,
      onClearSelection: () {},
      enableSearch: true,
      enableMultiSelect: false,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
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
                        NoteDetailScreen(noteGroup: noteGroup),
                  ),
                ).then((_) => _loadNotesData());
              },
              onLongPress: () =>
                  setState(() => _isCardEditMode = !_isCardEditMode),
              onMoveLeft: () {},
              onMoveRight: () {},
              // PERUBAHAN: Menyesuaikan teks menu agar informatif bagi pengguna
              popupMenuItems: const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Ubah Nama & Ikon'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Hapus Grup', style: TextStyle(color: Colors.red)),
                    ],
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
