// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../data/models/daily_model.dart';
import '../controllers/daily_controller.dart';
import 'checklist_detail_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late DailyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DailyController();
    _controller.addListener(_onControllerNotify);
    _controller.loadGroupsData();
  }

  void _onControllerNotify() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerNotify);
    _controller.dispose();
    super.dispose();
  }

  void _showAddMainSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Kategori Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            hintText: 'Nama Seksi Utama (Misal: PRIORITAS)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final String namaSeksiBaru = sectionController.text.trim();
              if (namaSeksiBaru.isNotEmpty) {
                _controller.addLocalMainSection(namaSeksiBaru);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seksi "$namaSeksiBaru" berhasil dibuat! Tekan tombol + di kanannya untuk menambah group.',
                    ),
                    backgroundColor: Colors.teal[800],
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialogAtSection(String targetMainSection) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📁');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buat Group Baru di $targetMainSection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Group (Misal: Pekerjaan)',
              ),
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
              if (nameController.text.isNotEmpty) {
                await _controller.createGroupAtSection(
                  nameController.text.trim(),
                  iconController.text.trim(),
                  targetMainSection,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Buat Group'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(ChecklistGroup group) {
    final nameController = TextEditingController(text: group.groupName);
    final iconController = TextEditingController(text: group.icon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Checklist Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Group'),
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
              if (nameController.text.isNotEmpty) {
                await _controller.updateGroup(
                  group,
                  nameController.text.trim(),
                  iconController.text.trim(),
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(ChecklistGroup group) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Checklist Group?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus Group "${group.groupName}" secara permanen beserta seluruh isinya?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _controller.deleteGroup(group);
    }
  }

  void _showMoveSectionDialog(ChecklistGroup group) {
    List<String> availableSections = _controller.groupedVisibleGroup.keys
        .toList();

    if (!availableSections.contains("Lainnya")) {
      availableSections.add("Lainnya");
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pindahkan "${group.groupName}" ke Seksi...'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableSections.length,
              itemBuilder: (context, index) {
                final sectionName = availableSections[index];
                final bool isCurrentSection =
                    group.sectionCategory == sectionName;

                return ListTile(
                  title: Text(sectionName.toUpperCase()),
                  leading: Icon(
                    isCurrentSection ? Icons.folder_special : Icons.folder_open,
                    color: isCurrentSection ? Colors.teal[800] : Colors.grey,
                  ),
                  trailing: isCurrentSection
                      ? const Icon(Icons.check_circle, color: Colors.teal)
                      : null,
                  selected: isCurrentSection,
                  onTap: isCurrentSection
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _controller.moveGroupToAnotherSection(
                            group,
                            sectionName,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Group "${group.groupName}" berhasil dipindahkan ke seksi "$sectionName"',
                                ),
                                backgroundColor: Colors.teal[800],
                              ),
                            );
                          }
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _editMainSectionName(String oldSectionName) {
    final editController = TextEditingController(text: oldSectionName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Seksi Kategori'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final String newSectionName = editController.text.trim();
              if (newSectionName.isNotEmpty &&
                  newSectionName != oldSectionName) {
                await _controller.updateMainSectionName(
                  oldSectionName,
                  newSectionName,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteMainSection(String sectionName) async {
    final listGroupDiSeksiIni =
        _controller.groupedVisibleGroup[sectionName] ?? [];

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Seksi Kategori?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus seksi "$sectionName"?\n\n'
              'Peringatan: Tindakan ini juga akan menghapus ${listGroupDiSeksiIni.length} Hub di dalamnya secara permanen!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _controller.deleteMainSection(sectionName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allKeys = _controller.groupedVisibleGroup.keys.toList();
    final Map<String, List<ChecklistGroup>> allItems = Map.from(
      _controller.groupedVisibleGroup,
    );
    final int visibleKeysCount = allKeys.length;

    if (_controller.hiddenGroup.isNotEmpty && _controller.showHiddenSection) {
      for (var entry in _controller.groupedHiddenGroup.entries) {
        final hiddenKey = '${entry.key}_hidden_key';
        allKeys.add(hiddenKey);
        allItems[hiddenKey] = entry.value;
      }
    }

    return GroupedSectionLayout<ChecklistGroup>(
      title: 'My Checklist Groups',
      drawer: const DrawerMenu(isDailyActive: true),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMainSectionDialog,
        backgroundColor: Colors.teal[800],
        tooltip: 'Tambah Seksi Kategori Baru',
        child: const Icon(
          Icons.create_new_folder_outlined,
          size: 28,
          color: Colors.white,
        ),
      ),
      isLoading: _controller.isLoading,
      isEmpty: _controller.allGroupRaw.isEmpty,
      emptyMessage:
          'Belum ada Seksi Kategori. Tekan + di bawah untuk membuat baru!',
      sectionKeys: allKeys,
      groupedItems: allItems,
      // childAspectRatio dilepas karena sudah dikalkulasi dinamis secara internal oleh layout

      // ==========================================
      // INTEGRASI PROPERTI GROUPED SECTION LAYOUT
      // ==========================================
      isSelectMode: false,
      selectedItemsCount: 0,
      onClearSelection: () {},
      enableSearch: true, // Berikan izin akses search bar
      enableMultiSelect: false,
      // ---> TAMBAHAN: Tautkan method controller untuk pencarian <---
      onSearchChanged: _controller.updateSearchQuery,
      // ---> TAMBAHAN: Tautkan dialog Add ke tombol (+) di Appbar <---
      onAddPressed: _showAddMainSectionDialog,
      // Parameter isSearchMode dan onToggleSearchMode dilepas karena dikelola internal layout
      // ==========================================

      // MENYESUAIKAN SIGNATURE BUILDER: Menangkap parameter isLayoutEditMode dari internal layout
      sectionHeaderBuilder: (context, index, sectionKey, isLayoutEditMode) {
        if (index >= visibleKeysCount) {
          String originalName = sectionKey.replaceAll('_hidden_key', '');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index == visibleKeysCount)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Divider(thickness: 2, color: Colors.grey),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '$originalName (Tersembunyi)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
            ],
          );
        }

        return InteractiveSectionHeader(
          sectionName: sectionKey,
          themeColor: Colors.teal[900]!,
          // Singkronisasi mode edit seksi mengikuti pemicu AppBar ditahan lama
          isEditMode: isLayoutEditMode ? true : _controller.isSectionEditMode,
          isFirst: index == 0,
          isLast: index == visibleKeysCount - 1,
          onToggleEdit: _controller.toggleSectionEditMode,
          onMoveUp: () => _controller.moveMainSectionOrder(sectionKey, -1),
          onMoveDown: () => _controller.moveMainSectionOrder(sectionKey, 1),
          onEditName: () => _editMainSectionName(sectionKey),
          onDelete: () => _deleteMainSection(sectionKey),
          onAddItem: () => _showAddGroupDialogAtSection(sectionKey),
        );
      },

      // MENYESUAIKAN SIGNATURE BUILDER: Menangkap parameter isLayoutEditMode dari internal layout
      gridItemBuilder: (context, group, index, sectionItems, isLayoutEditMode) {
        int totalItems = 0;
        for (var section in group.allList) {
          totalItems += section.items.length;
        }

        return InteractiveGridCard(
          themeColor: Colors.teal[800]!,
          // Singkronisasi mode edit card mengikuti pemicu AppBar ditahan lama
          isEditMode: isLayoutEditMode ? true : _controller.isPageEditMode,
          isHiddenStyle: group.isHidden,
          isFirst: index == 0,
          isLast: index == sectionItems.length - 1,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChecklistDetailScreen(
                  group: group,
                  baseDir: _controller.selectedBaseDir,
                ),
              ),
            ).then((_) => _controller.loadGroupsData());
          },
          onLongPress: _controller.togglePageEditMode,
          onMoveLeft: () => _controller.moveGroupOrder(sectionItems, index, -1),
          onMoveRight: () => _controller.moveGroupOrder(sectionItems, index, 1),
          popupMenuItems: [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit, size: 18, color: Colors.teal),
                  SizedBox(width: 10),
                  Text('Ubah Nama & Ikon', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'move_section',
              child: Row(
                children: const [
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
            PopupMenuItem(
              value: 'toggle_visibility',
              child: Row(
                children: [
                  Icon(
                    group.isHidden ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: Colors.blueGrey[700],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    group.isHidden ? 'Tampilkan Group' : 'Sembunyikan Group',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text(
                    'Hapus Group',
                    style: TextStyle(fontSize: 13, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
          onPopupSelected: (value) async {
            if (value == 'edit') {
              _showEditGroupDialog(group);
            } else if (value == 'move_section') {
              _showMoveSectionDialog(group);
            } else if (value == 'toggle_visibility') {
              await _controller.toggleGroupVisibility(group);
            } else if (value == 'delete') {
              _deleteGroup(group);
            }
          },
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                group.icon,
                style: TextStyle(
                  fontSize: 28,
                  color: group.isHidden ? Colors.grey : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                group.groupName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: group.isHidden ? Colors.grey : Colors.black87,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (group.isHidden ? Colors.grey : Colors.teal[800]!)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${group.allList.length} Seksi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: group.isHidden
                            ? Colors.grey[700]
                            : Colors.teal[900]!,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (group.isHidden ? Colors.grey : Colors.indigo[800]!)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$totalItems Item',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: group.isHidden
                            ? Colors.grey[700]
                            : Colors.indigo[900]!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
