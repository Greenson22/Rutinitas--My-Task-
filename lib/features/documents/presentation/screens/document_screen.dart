// lib/features/documents/presentation/screens/document_screen.dart
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/presentation/widgets/grouped_section_layout.dart';
import 'package:rutinitasku/core/presentation/widgets/interactive_grid_card.dart';
import 'package:rutinitasku/core/presentation/widgets/interactive_section_header.dart';
import 'package:rutinitasku/core/presentation/widgets/universal_empty_state.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE[cite: 2]
import '../../data/models/document_model.dart';
import '../controllers/documents_controller.dart';
import '../widgets/document_emoji_picker.dart';
import 'document_detail_screen.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  late DocumentsController _controller;

  // =========================================================================
  // PERUBAHAN WARNA TEMA: Disamakan menggunakan Colors.indigo seperti di Notes
  // =========================================================================
  final Color _themeColor = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _controller = DocumentsController();
    _controller.addListener(_onControllerNotify);
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

  void _showMoveGroupSectionDialog(DocumentGroup group) {
    if (group.id.startsWith("CORRUPTED_")) return;

    List<String> availableSections = _controller.groupedVisibleGroup.keys
        .toList();

    for (var key in _controller.groupedHiddenGroup.keys) {
      if (!availableSections.contains(key)) {
        availableSections.add(key);
      }
    }

    if (!availableSections.contains("Catatan Utama")) {
      availableSections.add("Catatan Utama");
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
                  title: Text(sectionName),
                  leading: Icon(
                    isCurrentSection ? Icons.folder_special : Icons.folder_open,
                    color: isCurrentSection ? _themeColor : Colors.grey,
                  ),
                  trailing: isCurrentSection
                      ? Icon(Icons.check_circle, color: _themeColor)
                      : null,
                  selected: isCurrentSection,
                  onTap: isCurrentSection
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);

                          await _controller.moveGroupToAnotherSection(
                            group,
                            sectionName.isEmpty ? "Catatan Utama" : sectionName,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Grup "${group.groupName}" berhasil dipindahkan ke seksi "$sectionName"',
                              ),
                              backgroundColor: _themeColor,
                            ),
                          );
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

  void _showSequentialAddDialog() {
    final sectionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langkah 1: Buat Seksi Kategori'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: sectionController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Seksi Utama',
              hintText: 'Contoh: PEKERJAAN, PRIBADI, KEUANGAN...',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama seksi tidak boleh kosong'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final String namaSeksiBaru = sectionController.text.trim();
                _controller.addLocalMainSection(namaSeksiBaru);
                Navigator.pop(context);
                _showAddGroupDialogAtSection(namaSeksiBaru);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text(
              'Lanjut ke Group',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMainSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Kategori Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(hintText: 'Nama Seksi Utama...'),
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialogAtSection(String targetMainSection) {
    final nameController = TextEditingController();
    String selectedIcon = '📁';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Buat Group Dokumen di $targetMainSection'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nama Group Dokumen',
                    hintText: 'Contoh: Arsip Pajak, Resep, Jurnal...',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama group tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                DocumentEmojiPicker(
                  selectedEmoji: selectedIcon,
                  onSelected: (emoji) =>
                      setDialogState(() => selectedIcon = emoji),
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
                if (formKey.currentState!.validate()) {
                  _controller.createGroupAtSection(
                    nameController.text.trim(),
                    selectedIcon,
                    targetMainSection,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
              child: const Text(
                'Buat Group',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGroupDialog(DocumentGroup group) {
    final TextEditingController nameController = TextEditingController(
      text: group.groupName,
    );
    String selectedIcon = group.icon.isEmpty ? '📁' : group.icon;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah Nama & Ikon Grup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Grup Baru'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DocumentEmojiPicker(
                selectedEmoji: selectedIcon,
                onSelected: (emoji) =>
                    setDialogState(() => selectedIcon = emoji),
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
                if (updatedName.isNotEmpty) {
                  group.groupName = updatedName;
                  group.icon = selectedIcon;
                  await _controller.saveGroupDataToFile(group);
                  await _controller.loadGroupsData();
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
              child:
                  const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDeleteSectionDialog(String sectionName) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Hapus Seksi?'),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus seksi "$sectionName"? '
              'Semua grup dan dokumen di dalam seksi ini akan dihapus permanen dari penyimpanan.',
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
                  'Hapus Semua',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showConfirmDeleteGroupDialog(DocumentGroup group) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Hapus Grup Dokumen?'),
              ],
            ),
            content: Text(
              'Apakah Anda yakin ingin menghapus grup "${group.groupName}"? '
              'Semua berkas di dalam grup ini akan dihapus permanen dari penyimpanan.',
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

  @override
  Widget build(BuildContext context) {
    final List<String> allKeys = _controller.groupedVisibleGroup.keys.toList();
    if (!_controller.showHiddenSections) {
      allKeys.removeWhere((k) => _controller.isSectionHidden(k));
    }
    final Map<String, List<DocumentGroup>> allItems = Map.from(
      _controller.groupedVisibleGroup,
    );
    final int visibleKeysCount = allKeys.length;

    if (_controller.groupedHiddenGroup.isNotEmpty &&
        _controller.showHiddenSection) {
      for (var entry in _controller.groupedHiddenGroup.entries) {
        final hiddenKey = '${entry.key}_hidden_key';
        allKeys.add(hiddenKey);
        allItems[hiddenKey] = entry.value;
      }
    }

    return Scaffold(
      body: GroupedSectionLayout<DocumentGroup>(
        title: 'My Documents',
        forceShowMenu: true,
        drawer: const DrawerMenu(isDocumentsActive: true),
        isLoading: _controller.isLoading,
        isEmpty: _controller.allGroupRaw.isEmpty && allKeys.isEmpty,
        emptyMessage: 'Belum ada data.',
        emptyStateView: UniversalEmptyState(
          icon: Icons.folder_copy_rounded,
          title: 'Grup Dokumen Masih Kosong',
          description:
              'Belum ada grup dokumen yang terdaftar. Mulai rapikan catatan dan berkas Anda dengan membuat Seksi dan Grup pertama!',
          buttonLabel: 'Buat Kategori Dokumen',
          themeColor: _themeColor,
          onPressed: _showSequentialAddDialog,
        ),

        // =========================================================================
        // SINKRONISASI APPBAR ACTION: Menampilkan Status Enkripsi sistem seperti di Notes
        // Karena Modul Dokumen tidak dienkripsi, menggunakan ikon gembok terbuka berwarna teal transparan
        // =========================================================================
        appBarTrailingAction: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: 'Dekripsi Sistem Aktif (Teks Biasa)',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open,
                color: Colors.tealAccent,
                size: 18,
              ),
            ),
          ),
        ),

        sectionKeys: allKeys,
        groupedItems: allItems,
        isSectionCollapsed: (key) => _controller.isSectionCollapsed(key),
        isSelectMode: false,
        selectedItemsCount: 0,
        onClearSelection: () {},
        enableSearch: true,
        enableMultiSelect: false,
        onSearchChanged: _controller.updateSearchQuery,
        onAddPressed: _showAddMainSectionDialog,
        additionalAction: IconButton(
          icon: Icon(
            _controller.showHiddenSection
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.white,
          ),
          tooltip: _controller.showHiddenSection
              ? 'Sembunyikan Seksi & Grup Nonaktif'
              : 'Tampilkan Seksi & Grup Tersembunyi',
          onPressed: () {
            _controller.toggleShowHiddenSection();
            _controller.toggleShowHiddenSections();
          },
        ),
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

          // =========================================================================
          // PERUBAHAN UTAMA: Mengaktifkan Huruf Besar Seksi (`isUpperCase: true`)
          // Menyamakan warna tema, state edit, serta perilaku tukar urutan persisten
          // =========================================================================
          return InteractiveSectionHeader(
            sectionName: sectionKey,
            themeColor: _themeColor,
            isEditMode: isLayoutEditMode ? true : _controller.isSectionEditMode,
            isCollapsed: _controller.isSectionCollapsed(sectionKey),
            onToggleCollapse: () =>
                _controller.toggleSectionCollapse(sectionKey),
            isHidden: _controller.isSectionHidden(sectionKey),
            onToggleVisibility: () =>
                _controller.toggleSectionHidden(sectionKey),
            isUpperCase:
                true, // <--- SEKARANG MENJADI HURUF BESAR SEPERTI DI NOTES
            isFirst: index == 0,
            isLast: index == visibleKeysCount - 1,
            onToggleEdit: _controller.toggleSectionEditMode,
            onMoveUp: () => _controller.moveMainSectionOrder(sectionKey, -1),
            onMoveDown: () => _controller.moveMainSectionOrder(sectionKey, 1),
            onEditName: () {},
            onDelete: () async {
              final bool confirm = await _showConfirmDeleteSectionDialog(
                sectionKey,
              );
              if (confirm) {
                _controller.deleteMainSection(sectionKey);
              }
            },
            onAddItem: () => _showAddGroupDialogAtSection(sectionKey),
          );
        },
        gridItemBuilder: (context, group, index, sectionItems, isLayoutEditMode) {
          int totalDocsCount = _controller.groupFileCounts[group.id] ?? 0;

          // =========================================================================
          // RE-DESIGN KARTU GRID: Sepenuhnya disamakan dengan struktur & warna Notes
          // =========================================================================
          return InteractiveGridCard(
            themeColor: _themeColor,
            isEditMode: isLayoutEditMode ? true : _controller.isPageEditMode,
            isHiddenStyle: group.isHidden,
            isFirst: index == 0,
            isLast: index == sectionItems.length - 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentDetailScreen(
                    group: group,
                    baseDir: _controller.selectedBaseDir,
                  ),
                ),
              ).then((_) => _controller.loadGroupsData());
            },
            onLongPress: _controller.togglePageEditMode,
            onMoveLeft: () =>
                _controller.moveGroupOrder(sectionItems, index, -1),
            onMoveRight: () =>
                _controller.moveGroupOrder(sectionItems, index, 1),
            popupMenuItems: [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Ubah Nama & Ikon', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
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
              PopupMenuItem(
                value: 'toggle_visibility',
                child: Row(
                  children: [
                    Icon(
                      group.isHidden ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.isHidden ? 'Tampilkan Grup' : 'Sembunyikan Grup',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
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
                      'Hapus Grup',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            onPopupSelected: (value) async {
              // <--- Ditambahkan async di sini
              if (value == 'edit') {
                _showEditGroupDialog(group);
              }
              if (value == 'move_section') {
                _showMoveGroupSectionDialog(group);
              }
              if (value == 'toggle_visibility') {
                _controller.toggleGroupVisibility(group);
              }
              if (value == 'delete') {
                // Integrasi dialog konfirmasi hapus grup
                final bool confirm = await _showConfirmDeleteGroupDialog(group);
                if (confirm) {
                  _controller.deleteGroup(group);
                }
              }
            },
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  group.icon.isEmpty ? '📁' : group.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  group.groupName,
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
                    '$totalDocsCount File',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _themeColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // MENGGUNAKAN WIDGET KUSTOM ADMOB YANG BARU DAN MODULAR PADA FOOTER LAYOUT
      bottomNavigationBar: const AdaptiveBannerAd(adKey: 'document_hub_banner'),
    );
  }
}
