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

  // PERUBAHAN: Mulai dengan list kosong agar inisialisasi seksi dilakukan secara dinamis dari storage
  List<String> _sectionKeys = [];
  final Map<String, List<NoteGroup>> _groupedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadNotesData();
  }

  // PERUBAHAN: Memuat dan mengelompokkan grup note secara dinamis berdasarkan data seksi aslinya
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

      // Bersihkan memory state lama sebelum memasukkan data hasil load
      _sectionKeys.clear();
      _groupedCategories.clear();

      // Distribusikan note groups ke dalam seksinya masing-masing
      for (var group in loadedGroups) {
        String secName =
            group.sectionName; // Menggunakan properti baru dari model

        if (!_sectionKeys.contains(secName)) {
          _sectionKeys.add(secName);
          _groupedCategories[secName] = [];
        }
        _groupedCategories[secName]!.add(group);
      }

      setState(() {
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
        for (var key in _sectionKeys) {
          _groupedCategories[key]?.remove(group);
        }
      });
    } catch (e) {
      debugPrint("Gagal menghapus grup: $e");
    }
  }

  // Fungsi helper untuk memicu konfirmasi dialog hapus grup
  Future<bool> _showConfirmDeleteDialog(NoteGroup group) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Konfirmasi Hapus'),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus grup "${group.groupName}"? '
              'Semua data catatan di dalam grup ini akan terhapus secara permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
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

  // Dialog khusus untuk menambah Seksi Baru
  void _showAddSectionDialog() {
    final TextEditingController sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Seksi Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            labelText: 'Nama Seksi',
            hintText: 'Misal: Kerja, Kuliah, Arsip...',
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
              final newSectionName = sectionController.text.trim();
              if (newSectionName.isNotEmpty &&
                  !_sectionKeys.contains(newSectionName)) {
                setState(() {
                  _sectionKeys.add(newSectionName);
                  _groupedCategories[newSectionName] = [];
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // PERUBAHAN: Memasukkan parameter `sectionName` ke dalam inisialisasi NoteGroup baru
  void _showAddGroupDialog(String sectionName) {
    final TextEditingController groupController = TextEditingController();
    final TextEditingController iconController = TextEditingController(
      text: '📁',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buat Grup Baru di $sectionName'),
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
                  sectionName:
                      sectionName, // Menyimpan relasi seksi tujuan ke local storage
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

  // Mengubah dialog edit agar mendukung perubahan nama sekaligus ikon emoji
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

  // Fungsi untuk Mengubah Nama Seksi
  void _showRenameSectionDialog(String oldSectionName) {
    final TextEditingController renameController = TextEditingController(
      text: oldSectionName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Seksi'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSectionName = renameController.text.trim();
              if (newSectionName.isNotEmpty &&
                  newSectionName != oldSectionName) {
                setState(() {
                  // 1. Update list seksi
                  int index = _sectionKeys.indexOf(oldSectionName);
                  if (index != -1) {
                    _sectionKeys[index] = newSectionName;
                  }

                  // 2. Pindahkan data map kategori ke key baru
                  final items = _groupedCategories.remove(oldSectionName) ?? [];
                  _groupedCategories[newSectionName] = items;

                  // 3. Update sectionName di setiap NoteGroup objeknya agar sinkron saat di-save
                  for (var group in items) {
                    group.sectionName = newSectionName;
                    _saveGroupData(
                      group,
                    ); // Save perubahan seksi ke local storage
                  }
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

  // Fungsi untuk Menghapus Seksi beserta seluruh isinya
  void _confirmDeleteSection(String sectionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Hapus Seksi?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus seksi "$sectionName"? '
          'Semua grup dan catatan di dalam seksi ini akan dihapus permanen dari penyimpanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final groupsToDelete = _groupedCategories[sectionName] ?? [];

              // 1. Hapus semua file group yang ada di seksi ini dari storage
              for (var group in groupsToDelete) {
                try {
                  final baseDir = await _storageService.getBaseDirSetting();
                  await _storageService.deleteNoteGroup(baseDir, group.id);
                } catch (e) {
                  debugPrint("Gagal menghapus grup disk: $e");
                }
              }

              // 2. Hapus dari state memory widget
              setState(() {
                _sectionKeys.remove(sectionName);
                _groupedCategories.remove(sectionName);
              });

              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
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
      // PERUBAHAN: Validasi state kosong yang disesuaikan dengan inisialisasi dinamis map data
      isEmpty:
          _sectionKeys.isEmpty ||
          _groupedCategories.values.every((list) => list.isEmpty),
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
      // Tombol tambah utama membuka dialog seksi baru
      onAddPressed: _showAddSectionDialog,
      sectionHeaderBuilder: (context, index, sectionName, isLayoutEditMode) {
        return InteractiveSectionHeader(
          sectionName: sectionName,
          themeColor: _themeColor,
          isEditMode: isLayoutEditMode ? true : _isSectionEditMode,
          isFirst: index == 0,
          isLast: index == _sectionKeys.length - 1,
          onToggleEdit: () =>
              setState(() => _isSectionEditMode = !_isSectionEditMode),
          onEditName: () => _showRenameSectionDialog(sectionName),
          onDelete: () => _confirmDeleteSection(sectionName),
          // Tombol tambah di header sub-seksi membuat grup baru di dalam seksi bersangkutan
          onAddItem: () => _showAddGroupDialog(sectionName),
          onMoveUp: () {
            if (index > 0) {
              setState(() {
                final temp = _sectionKeys[index];
                _sectionKeys[index] = _sectionKeys[index - 1];
                _sectionKeys[index - 1] = temp;
              });
            }
          },
          onMoveDown: () {
            if (index < _sectionKeys.length - 1) {
              setState(() {
                final temp = _sectionKeys[index];
                _sectionKeys[index] = _sectionKeys[index + 1];
                _sectionKeys[index + 1] = temp;
              });
            }
          },
        );
      },
      gridItemBuilder: (context, noteGroup, index, sectionItems, isLayoutEditMode) {
        final sectionName = noteGroup.sectionName;
        return InteractiveGridCard(
          themeColor: _themeColor,
          isEditMode: isLayoutEditMode ? true : _isCardEditMode,
          isFirst: index == 0,
          isLast: index == sectionItems.length - 1,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailScreen(noteGroup: noteGroup),
              ),
            ).then((_) => _loadNotesData());
          },
          onLongPress: () => setState(() => _isCardEditMode = !_isCardEditMode),
          onMoveLeft: () async {
            if (index > 0) {
              setState(() {
                // Tukar posisi item di dalam list seksi yang sama
                final list = _groupedCategories[sectionName]!;
                final temp = list[index];
                list[index] = list[index - 1];
                list[index - 1] = temp;
              });
              // Opsional: Simpan urutan baru ke penyimpanan lokal jika diperlukan
              await _saveGroupData(_groupedCategories[sectionName]![index]);
              await _saveGroupData(_groupedCategories[sectionName]![index - 1]);
            }
          },
          onMoveRight: () async {
            if (index < sectionItems.length - 1) {
              setState(() {
                // Tukar posisi item di dalam list seksi yang sama
                final list = _groupedCategories[sectionName]!;
                final temp = list[index];
                list[index] = list[index + 1];
                list[index + 1] = temp;
              });
              // Opsional: Simpan urutan baru ke penyimpanan lokal jika diperlukan
              await _saveGroupData(_groupedCategories[sectionName]![index]);
              await _saveGroupData(_groupedCategories[sectionName]![index + 1]);
            }
          },
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
          onPopupSelected: (value) async {
            if (value == 'edit') {
              _showEditGroupDialog(noteGroup);
            } else if (value == 'delete') {
              final bool isConfirmed = await _showConfirmDeleteDialog(
                noteGroup,
              );
              if (isConfirmed) {
                _deleteGroupData(noteGroup);
              }
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
