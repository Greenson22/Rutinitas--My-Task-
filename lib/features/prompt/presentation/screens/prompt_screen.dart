// lib/features/prompt/presentation/screens/prompt_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../data/models/prompt_model.dart';
import '../controllers/prompt_controller.dart';
import 'prompt_detail_screen.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  late final PromptController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PromptController();
    _controller.loadAllPrompts(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Kategori Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            hintText: 'Nama Seksi Utama (Misal: CODING, COPYWRITING)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (sectionController.text.trim().isNotEmpty) {
                _controller.addSection(sectionController.text, context);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionNameDialog(String oldName) {
    final textController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Nama Seksi "$oldName"'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.editSectionName(
                oldName,
                textController.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(String sectionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Seksi "$sectionName"?'),
        content: Text(
          'Tindakan ini akan menghapus seluruh grup prompt yang ada di dalam seksi "$sectionName". Perubahan ini permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _controller.deleteSection(sectionName, context);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog({String? defaultSection}) {
    final titleController = TextEditingController();
    final iconController = TextEditingController(text: '🤖');
    final sectionController = TextEditingController(text: defaultSection ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Group Prompt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Group (e.g. Copywriting, Coding)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Icon Emoji'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Nama Seksi / Kategori',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              _controller.addPromptGroup(
                title: titleController.text,
                icon: iconController.text,
                section: sectionController.text,
                context: context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(PromptGroup group) {
    final titleController = TextEditingController(text: group.title);
    final iconController = TextEditingController(text: group.icon);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama & Ikon Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Group'),
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
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              _controller.editGroup(
                group,
                titleController.text,
                iconController.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMoveSectionDialog(PromptGroup group) {
    final Map<String, List<PromptGroup>> sectionsMap = {};
    for (var g in _controller.promptGroups) {
      final name = g.sectionName.isEmpty
          ? 'GENERAL'
          : g.sectionName.toUpperCase();
      sectionsMap.putIfAbsent(name, () => []);
    }
    for (var sec in _controller.localEmptySections) {
      sectionsMap.putIfAbsent(sec, () => []);
    }
    final List<String> availableSections = sectionsMap.keys.toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindahkan Group ke Seksi Lain'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSections.length,
            itemBuilder: (context, index) {
              final secName = availableSections[index];
              return ListTile(
                title: Text(secName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _controller.moveGroupToSection(group, secName, context);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteGroupItemDialog(PromptGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Group "${group.title}"?'),
        content: const Text(
          'Tindakan ini akan menghapus group ini secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _controller.deleteGroupItem(group, context);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final Map<String, List<PromptGroup>> sectionsMap = {};
        for (var group in _controller.promptGroups) {
          final secName = group.sectionName.isEmpty
              ? 'GENERAL'
              : group.sectionName.toUpperCase();
          if (!sectionsMap.containsKey(secName)) {
            sectionsMap[secName] = [];
          }
          sectionsMap[secName]!.add(group);
        }
        for (var sec in _controller.localEmptySections) {
          sectionsMap.putIfAbsent(sec, () => []);
        }
        final sectionKeys = sectionsMap.keys.toList();
        if (sectionKeys.contains('GENERAL')) {
          sectionKeys.remove('GENERAL');
          sectionKeys.insert(0, 'GENERAL');
        }

        return GroupedSectionLayout<PromptGroup>(
          title: 'My Prompts',
          drawer: const DrawerMenu(isPromptActive: true),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddSectionDialog,
            backgroundColor: Colors.indigo,
            tooltip: 'Tambah Seksi Baru',
            child: const Icon(
              Icons.create_new_folder_outlined,
              size: 28,
              color: Colors.white,
            ),
          ),
          isLoading: _controller.isLoading,
          isEmpty:
              _controller.promptGroups.isEmpty &&
              _controller.localEmptySections.isEmpty,
          emptyMessage: 'Belum ada data seksi / prompt di penyimpanan.',

          // ==========================================
          // INTEGRASI PROPERTI GROUPED SECTION LAYOUT
          // ==========================================
          isSelectMode: false,
          selectedItemsCount: 0,
          onClearSelection: () {},
          enableSearch: true, // Izinkan input search diaktifkan secara internal
          enableMultiSelect: false,

          // Parameter isSearchMode dan onToggleSearchMode dihilangkan karena dikontrol internal layout
          // childAspectRatio dihitung otomatis oleh state internal layout (.dart baru)
          // ==========================================
          sectionKeys: sectionKeys,
          groupedItems: sectionsMap,
          // MENYESUAIKAN SIGNATURE BUILDER: Menangkap variabel `isLayoutEditMode` dari internal layout
          sectionHeaderBuilder: (context, sIndex, sectionName, isLayoutEditMode) {
            return InteractiveSectionHeader(
              sectionName: sectionName,
              themeColor: Colors.indigo[900]!,
              // Menggunakan mode edit internal layout jika aktif, jika tidak kembali ke controller
              isEditMode: isLayoutEditMode
                  ? true
                  : _controller.isSectionEditMode,
              isUpperCase: false,
              isFirst: sIndex == 0,
              isLast: sIndex == sectionKeys.length - 1,
              onToggleEdit: () {
                if (_controller.isCardEditMode || isLayoutEditMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Matikan Mode Edit Kotak/Card terlebih dahulu!',
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                _controller.toggleSectionEditMode();
              },
              onMoveUp: () => _controller.moveSectionOrder(sIndex, -1, context),
              onMoveDown: () =>
                  _controller.moveSectionOrder(sIndex, 1, context),
              onEditName: () => _showEditSectionNameDialog(sectionName),
              onDelete: () => _showDeleteSectionDialog(sectionName),
              onAddItem: () => _showAddGroupDialog(defaultSection: sectionName),
            );
          },
          // MENYESUAIKAN SIGNATURE BUILDER: Menangkap variabel `isLayoutEditMode` dari internal layout
          gridItemBuilder: (context, promptGroup, index, items, isLayoutEditMode) {
            return InteractiveGridCard(
              themeColor: Colors.indigo,
              // Otomatis aktifkan edit mode card jika AppBar sedang ditahan lama
              isEditMode: isLayoutEditMode ? true : _controller.isCardEditMode,
              isFirst: index == 0,
              isLast: index == items.length - 1,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PromptDetailScreen(promptGroup: promptGroup),
                  ),
                ).then((_) => _controller.loadAllPrompts(context));
              },
              onLongPress: () {
                if (_controller.isSectionEditMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Matikan Mode Edit Kategori/Seksi terlebih dahulu!',
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                _controller.toggleCardEditMode();
              },
              onMoveLeft: () =>
                  _controller.moveGroupOrderHorizontal(items, index, -1),
              onMoveRight: () =>
                  _controller.moveGroupOrderHorizontal(items, index, 1),
              popupMenuItems: const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Ubah Nama & Ikon', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'move_section',
                  child: Row(
                    children: [
                      Icon(
                        Icons.drive_file_move_outlined,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      SizedBox(width: 10),
                      Text('Pindahkan Seksi', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Hapus Group',
                        style: TextStyle(fontSize: 13, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
              onPopupSelected: (value) {
                if (value == 'edit') {
                  _showEditGroupDialog(promptGroup);
                } else if (value == 'move_section') {
                  _showMoveSectionDialog(promptGroup);
                } else if (value == 'delete') {
                  _showDeleteGroupItemDialog(promptGroup);
                }
              },
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    promptGroup.icon,
                    style: const TextStyle(fontSize: 28, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promptGroup.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${promptGroup.prompts.length} Item',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
