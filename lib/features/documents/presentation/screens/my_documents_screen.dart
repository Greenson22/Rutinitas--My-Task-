// lib/features/documents/presentation/screens/my_documents_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../data/models/document_model.dart';
import '../controllers/documents_controller.dart';
import 'document_detail_screen.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  late DocumentsController _controller;
  final Color _themeColor = Colors.blueGrey; // Warna tema khusus Documents

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

  // --- LOGIKA DIALOG (Serupa dengan Checklist) ---

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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialogAtSection(String targetMainSection) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📁');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              TextFormField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Ikon Emoji'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ikon tidak boleh kosong'
                    : null,
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
                  iconController.text.trim(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allKeys = _controller.groupedVisibleGroup.keys.toList();
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
        drawer: const DrawerMenu(isDocumentsActive: true),
        isLoading: _controller.isLoading,
        isEmpty: _controller.allGroupRaw.isEmpty && allKeys.isEmpty,
        emptyStateView: UniversalEmptyState(
          icon: Icons.folder_copy_rounded,
          title: 'Grup Dokumen Masih Kosong',
          description:
              'Belum ada grup dokumen yang terdaftar. Mulai rapikan catatan dan berkas Anda dengan membuat Seksi dan Grup pertama!',
          buttonLabel: 'Buat Kategori Dokumen',
          themeColor: _themeColor,
          onPressed: _showSequentialAddDialog,
        ),
        sectionKeys: allKeys,
        groupedItems: allItems,
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
              ? 'Sembunyikan'
              : 'Tampilkan Tersembunyi',
          onPressed: _controller.toggleShowHiddenSection,
        ),
        sectionHeaderBuilder: (context, index, sectionKey, isLayoutEditMode) {
          if (index >= visibleKeysCount) {
            String originalName = sectionKey.replaceAll('_hidden_key', '');
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '$originalName (Tersembunyi)',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            );
          }

          return InteractiveSectionHeader(
            sectionName: sectionKey,
            themeColor: _themeColor,
            isEditMode: isLayoutEditMode ? true : _controller.isSectionEditMode,
            isUpperCase: false,
            isFirst: index == 0,
            isLast: index == visibleKeysCount - 1,
            onToggleEdit: _controller.toggleSectionEditMode,
            onMoveUp: () => _controller.moveMainSectionOrder(sectionKey, -1),
            onMoveDown: () => _controller.moveMainSectionOrder(sectionKey, 1),
            onEditName: () {}, // Tambahkan logika edit seksi jika diperlukan
            onDelete: () => _controller.deleteMainSection(sectionKey),
            onAddItem: () => _showAddGroupDialogAtSection(sectionKey),
          );
        },
        gridItemBuilder: (context, group, index, sectionItems, isLayoutEditMode) {
          // UBAH BARIS INI: Ambil jumlah dokumen asli dari controller, bukan json
          int totalDocsCount = _controller.groupFileCounts[group.id] ?? 0;

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
                value: 'toggle_visibility',
                child: Row(
                  children: [
                    Icon(Icons.visibility),
                    SizedBox(width: 8),
                    Text('Visibilitas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus'),
                  ],
                ),
              ),
            ],
            onPopupSelected: (value) {
              if (value == 'toggle_visibility') {
                _controller.toggleGroupVisibility(group);
              }
              if (value == 'delete') {
                _controller.deleteGroup(group);
              }
            },
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (group.isHidden ? Colors.grey : _themeColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalDocsCount File', // <-- Ubah label sedikit agar lebih akurat (opsional)
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: group.isHidden ? Colors.grey[700] : _themeColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
