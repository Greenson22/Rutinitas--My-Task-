// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
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
    // Daftarkan listener agar UI me-refresh otomatis saat controller memanggil notifyListeners()
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Checklist Groups'),
        backgroundColor: Colors.teal[800],
        actions: [
          IconButton(
            icon: Icon(
              _controller.showHiddenSection
                  ? Icons.visibility
                  : Icons.visibility_off,
            ),
            onPressed: _controller.toggleShowHiddenSection,
          ),
        ],
      ),
      drawer: const DrawerMenu(isDailyActive: true),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.allGroupRaw.isEmpty &&
                _controller.groupedVisibleGroup.isEmpty
          ? const Center(
              child: Text(
                'Belum ada Seksi Kategori. Tekan + di bawah untuk membuat baru!',
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final semuaKunciSeksi = _controller.groupedVisibleGroup.keys
                    .toList();

                return ListView(
                  children: [
                    ...semuaKunciSeksi.map((namaSeksiUtama) {
                      final listGroupDiSeksiIni =
                          _controller.groupedVisibleGroup[namaSeksiUtama] ?? [];
                      final int indexSeksi = semuaKunciSeksi.indexOf(
                        namaSeksiUtama,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            index: indexSeksi,
                            totalCount: semuaKunciSeksi.length,
                            sectionName: namaSeksiUtama,
                            color: Colors.teal[900]!,
                          ),
                          listGroupDiSeksiIni.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.only(
                                    left: 24,
                                    top: 12,
                                    bottom: 12,
                                  ),
                                  child: Text(
                                    'Belum ada group di seksi ini.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : _buildGroupGrid(
                                  listGroupDiSeksiIni,
                                  constraints,
                                ),
                        ],
                      );
                    }),
                    if (_controller.hiddenGroup.isNotEmpty &&
                        _controller.showHiddenSection) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Divider(thickness: 2, color: Colors.grey),
                      ),
                      ..._controller.groupedHiddenGroup.entries.map((grup) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${grup.key} (Tersembunyi)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildGroupGrid(grup.value, constraints),
                          ],
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
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
    );
  }

  Widget _buildSectionHeader({
    required int index,
    required int totalCount,
    required String sectionName,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.teal.withOpacity(0.1),
        highlightColor: Colors.teal.withOpacity(0.05),
        onLongPress: _controller.toggleSectionEditMode,
        onTap: () {},
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: _controller.isSectionEditMode
              ? const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)
              : const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sectionName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (_controller.isSectionEditMode) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index > 0
                              ? () => _controller.moveMainSectionOrder(
                                  sectionName,
                                  -1,
                                )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          onPressed: index < totalCount - 1
                              ? () => _controller.moveMainSectionOrder(
                                  sectionName,
                                  1,
                                )
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.teal,
                          ),
                          onPressed: () => _editMainSectionName(sectionName),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteMainSection(sectionName),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.teal,
                            size: 18,
                          ),
                          tooltip: 'Tambah Group ke Seksi Ini',
                          onPressed: () =>
                              _showAddGroupDialogAtSection(sectionName),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                ],
              ),
              const Divider(height: 2, thickness: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupGrid(
    List<ChecklistGroup> groupList,
    BoxConstraints constraints,
  ) {
    int crossAxisCount = 2;
    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: _controller.isPageEditMode ? 0.90 : 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: groupList.length,
      itemBuilder: (context, index) {
        final group = groupList[index];

        int totalItems = 0;
        for (var section in group.allList) {
          totalItems += section.items.length;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: group.isHidden ? Colors.grey : Colors.teal[800]!,
              width: 3.5,
            ),
          ),
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(
                      _controller.isPageEditMode ? 0 : 16,
                    ),
                    bottomRight: Radius.circular(
                      _controller.isPageEditMode ? 0 : 16,
                    ),
                  ),
                  onLongPress: _controller.togglePageEditMode,
                  onTap: _controller.isPageEditMode
                      ? null
                      : () {
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
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            group.icon,
                            style: TextStyle(
                              fontSize: 28,
                              color: group.isHidden
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            group.groupName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: group.isHidden
                                  ? Colors.grey
                                  : Colors.black87,
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
                                  color:
                                      (group.isHidden
                                              ? Colors.grey
                                              : Colors.teal[800]!)
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
                                      (group.isHidden
                                              ? Colors.grey
                                              : Colors.indigo[800]!)
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
                    ),
                  ),
                ),
              ),
              if (_controller.isPageEditMode) ...[
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        color: index > 0 ? Colors.teal[800] : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index > 0
                            ? () => _controller.moveGroupOrder(
                                groupList,
                                index,
                                -1,
                              )
                            : null,
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
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
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: const [
                                Icon(Icons.edit, size: 18, color: Colors.teal),
                                SizedBox(width: 10),
                                Text(
                                  'Ubah Nama & Ikon',
                                  style: TextStyle(fontSize: 13),
                                ),
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
                                Text(
                                  'Pindahkan Seksi',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_visibility',
                            child: Row(
                              children: [
                                Icon(
                                  group.isHidden
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 18,
                                  color: Colors.blueGrey[700],
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  group.isHidden
                                      ? 'Tampilkan Group'
                                      : 'Sembunyikan Group',
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
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Hapus Group',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        color: index < groupList.length - 1
                            ? Colors.teal[800]
                            : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index < groupList.length - 1
                            ? () => _controller.moveGroupOrder(
                                groupList,
                                index,
                                1,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
