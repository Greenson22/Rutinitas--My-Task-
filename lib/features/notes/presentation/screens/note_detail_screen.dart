// lib/features/notes/presentation/screens/note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE
import '../../models/note_model.dart';
import '../controllers/note_detail_controller.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import 'note_edit_dialog.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteGroup noteGroup;

  const NoteDetailScreen({super.key, required this.noteGroup});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteDetailController _controller;
  // STATE BARU: Menyimpan jenis pengurutan aktif ('manual', 'az', 'za')
  String _currentSortType = 'manual';
  bool _isLoadingFolders = true;

  @override
  void initState() {
    super.initState();
    _controller = NoteDetailController(
      noteGroup: widget.noteGroup,
      context: context,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    await _controller.loadChildFolders();
    if (mounted) {
      setState(() => _isLoadingFolders = false);
    }
  }

  void _showSubFolderDialog({NoteGroup? existingFolder}) {
    final nameController = TextEditingController(
      text: existingFolder?.groupName ?? '',
    );
    final iconController = TextEditingController(
      text: existingFolder?.icon.isNotEmpty == true
          ? existingFolder!.icon
          : '📁',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existingFolder == null ? 'Buat Sub-Folder' : 'Edit Sub-Folder',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Folder',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Ikon / Emoji',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final icon = iconController.text.trim().isEmpty
                  ? '📁'
                  : iconController.text.trim();
              Navigator.pop(ctx);
              if (existingFolder == null) {
                await _controller.createSubFolder(name: name, icon: icon);
              } else {
                await _controller.renameSubFolder(existingFolder, name, icon);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget? _buildSubFoldersHeader() {
    if (_controller.childFolders.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sub-Folder (${_controller.childFolders.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[700],
            ),
          ),
          const SizedBox(height: 8),
          ..._controller.childFolders.map((folder) {
            final displayIcon = folder.icon.isNotEmpty ? folder.icon : '📁';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Text(
                  displayIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  folder.groupName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${folder.notes.length} catatan',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'edit') {
                      _showSubFolderDialog(existingFolder: folder);
                    } else if (val == 'move') {
                      _showMoveSubFolderDialog(folder);
                    } else if (val == 'delete') {
                      final confirm = await _controller.showConfirmDialog(
                        title: 'Hapus Sub-Folder',
                        content:
                            'Yakin ingin menghapus folder "${folder.groupName}" beserta seluruh isi di dalamnya?',
                      );
                      if (confirm) {
                        await _controller.deleteSubFolder(folder);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Folder')),
                    PopupMenuItem(value: 'move', child: Text('Pindah Folder')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Hapus Folder',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailScreen(noteGroup: folder),
                    ),
                  );
                  _controller.loadChildFolders();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showNoteDialog({NoteModel? existingNote}) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          NoteEditDialog(controller: _controller, existingNote: existingNote),
    );
  }

  // =========================================================================
  // FITUR BARU: LOGIKA PROSES PENGURUTAN ITEM PROMPT
  // =========================================================================
  void _handleSort(String sortType) {
    setState(() {
      _currentSortType = sortType;
      if (sortType == 'az') {
        _controller.currentGroup.notes.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      } else if (sortType == 'za') {
        _controller.currentGroup.notes.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
      } else {
        // Mode Manual: Ditembalikan ke urutan default berdasarkan waktu pembuatan (createdAt)
        _controller.currentGroup.notes.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
      }
    });
    // Simpan susunan urutan baru ke penyimpanan lokal secara persisten
    _controller.saveCurrentGroup();
  }

  String _getFolderPath(NoteGroup group, Map<String, NoteGroup> groupMap) {
    final List<String> parts = [];
    String? currentParentId = group.parentId;
    final Set<String> visited = {group.id};
    while (currentParentId != null && !visited.contains(currentParentId)) {
      visited.add(currentParentId);
      final parent = groupMap[currentParentId];
      if (parent == null) break;
      parts.insert(0, parent.groupName);
      currentParentId = parent.parentId;
    }
    if (parts.isEmpty) return group.sectionName;
    return '${group.sectionName} > ${parts.join(' > ')}';
  }

  Future<void> _showFolderPickerDialog({
    required String title,
    required List<NoteGroup> allGroups,
    required Set<String> excludedIds,
    required Future<void> Function(NoteGroup target) onSelectTarget,
    String? cannotSelectTargetId,
    bool allowRootMove = false,
    Future<void> Function()? onMoveToRoot,
  }) async {
    final groupMap = {for (var g in allGroups) g.id: g};
    final validGroups =
        allGroups.where((g) => !excludedIds.contains(g.id)).toList();
    final sections = validGroups.map((g) => g.sectionName).toSet().toList()
      ..sort();

    if (validGroups.isEmpty && !allowRootMove) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak ada folder tujuan lain yang tersedia."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        String? selectedSection;
        NoteGroup? currentFolder;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final List<NoteGroup> currentList = selectedSection == null
                ? []
                : validGroups.where((g) {
                    if (currentFolder == null) {
                      return g.sectionName == selectedSection &&
                          g.parentId == null;
                    }
                    return g.parentId == currentFolder!.id;
                  }).toList();

            return BasePopupDialog(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              themeColor: Colors.indigo,
              titleColor: Colors.white,
              content: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedSection != null) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setDialogState(() {
                          if (currentFolder != null) {
                            currentFolder = currentFolder!.parentId != null
                                ? groupMap[currentFolder!.parentId]
                                : null;
                          } else {
                            selectedSection = null;
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 14,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  currentFolder == null
                                      ? "Kembali ke Daftar Seksi ($selectedSection)"
                                      : "Kembali (${currentFolder!.groupName})",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ] else ...[
                      const Text(
                        "Pilih Seksi:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (allowRootMove && selectedSection == null)
                      Card(
                        elevation: 0,
                        color: Colors.indigo.withValues(alpha: 0.06),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.indigo.withValues(alpha: 0.2),
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(
                            Icons.home_rounded,
                            color: Colors.indigo,
                          ),
                          title: const Text(
                            "Halaman Utama (Root)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.indigo,
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);
                            if (onMoveToRoot != null) await onMoveToRoot();
                          },
                        ),
                      ),
                    if (currentFolder != null &&
                        currentFolder!.id != cannotSelectTargetId) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.drive_file_move_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            "Pindah Di Sini (${currentFolder!.groupName})",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final target = currentFolder!;
                            Navigator.pop(ctx);
                            await onSelectTarget(target);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Flexible(
                      child: selectedSection == null
                          ? ListView.separated(
                              shrinkWrap: true,
                              itemCount: sections.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, idx) {
                                final sec = sections[idx];
                                final count = validGroups
                                    .where(
                                      (g) =>
                                          g.sectionName == sec &&
                                          g.parentId == null,
                                    )
                                    .length;
                                return Material(
                                  color: Colors.grey.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          Colors.indigo.withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.folder_copy_rounded,
                                        color: Colors.indigo,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      sec,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "$count group notes",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.grey[400],
                                    ),
                                    onTap: () => setDialogState(
                                      () => selectedSection = sec,
                                    ),
                                  ),
                                );
                              },
                            )
                          : currentList.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      currentFolder == null
                                          ? "Tidak ada group di seksi ini."
                                          : "Tidak ada sub-folder di dalam \"${currentFolder!.groupName}\".",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: currentList.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, idx) {
                                    final targetG = currentList[idx];
                                    final subCount = validGroups
                                        .where((g) => g.parentId == targetG.id)
                                        .length;
                                    return Material(
                                      color: Colors.grey.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      child: ListTile(
                                        dense: true,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        leading: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.indigo
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            targetG.icon.isEmpty
                                                ? "📁"
                                                : targetG.icon,
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        title: Text(
                                          targetG.groupName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          subCount > 0
                                              ? "$subCount sub-folder • ${targetG.notes.length} catatan"
                                              : "${targetG.notes.length} catatan",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        trailing: Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey[400],
                                        ),
                                        onTap: () => setDialogState(
                                          () => currentFolder = targetG,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Batal",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMoveSubFolderDialog(NoteGroup folder) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.indigo)),
    );

    final allGroups = await _controller.getAllNoteGroups();
    if (!mounted) return;
    Navigator.pop(context);

    final Set<String> excludedIds = {folder.id};
    bool added = true;
    while (added) {
      added = false;
      for (var g in allGroups) {
        if (g.parentId != null &&
            excludedIds.contains(g.parentId) &&
            !excludedIds.contains(g.id)) {
          excludedIds.add(g.id);
          added = true;
        }
      }
    }
    if (folder.parentId != null) {
      excludedIds.add(folder.parentId!);
    }

    await _showFolderPickerDialog(
      title: "Pindahkan \"${folder.groupName}\"",
      allGroups: allGroups,
      excludedIds: excludedIds,
      allowRootMove: folder.parentId != null,
      onMoveToRoot: () => _controller.moveSubFolder(folder, null),
      onSelectTarget: (target) => _controller.moveSubFolder(folder, target.id),
    );
  }

  void _showMoveMassiveDialog(List<NoteModel> selectedItems) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.indigo)),
    );

    final allGroups = await _controller.getAllNoteGroups();
    if (!mounted) return;
    Navigator.pop(context);

    final hasSubFoldersInCurrent = allGroups.any(
      (g) => g.parentId == _controller.currentGroup.id,
    );

    await _showFolderPickerDialog(
      title: "Pindahkan ${selectedItems.length} Catatan Terpilih",
      allGroups: allGroups,
      excludedIds: hasSubFoldersInCurrent ? {} : {_controller.currentGroup.id},
      cannotSelectTargetId: _controller.currentGroup.id,
      onSelectTarget: (targetG) async {
        await _controller.moveMassiveNotes(selectedItems, targetG);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${selectedItems.length} catatan berhasil dipindahkan ke \"${targetG.groupName}\"!",
              ),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingFolders) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(
            _controller.currentGroup.groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(0xFF3F51B5),
          elevation: 2,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    // ================= TANGANI KEADAAN AWAL KOSONG DI SINI =================
    if (_controller.currentGroup.notes.isEmpty &&
        _controller.childFolders.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(
          0xFFF5F6FA,
        ), // Menyelaraskan background BaseDetailListScreen
        appBar: AppBar(
          title: Text(
            _controller.currentGroup.groupName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(
            0xFF3F51B5,
          ), // Menyelaraskan warna AppBar utama (Indigo)
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.create_new_folder_rounded,
                color: Colors.white,
              ),
              tooltip: 'Buat Sub-Folder',
              onPressed: () => _showSubFolderDialog(),
            ),
          ],
        ),
        body: UniversalEmptyState(
          icon: Icons.note_add_rounded,
          title: 'Belum Ada Catatan',
          description:
              'Grup ini masih kosong dari lembar tulisan. Tekan tombol di bawah untuk membuat catatan teks atau lembar tabel data pertama Anda!',
          buttonLabel: 'Buat Catatan Baru',
          themeColor: const Color(0xFF3F51B5), // Warna tema Indigo
          onPressed: () => _showNoteDialog(),
        ),
        // IMPLEMENTASI LAYOUT FOOTER BANNER MENGGUNAKAN WIDGET ADAPTIVE PADA KONDISI DATA KOSONG
        bottomNavigationBar: const AdaptiveBannerAd(
          adKey: 'note_detail_banner',
        ),
      );
    }

    // ================= TAMPILKAN LIST UTAMA JIKA DATA TERSEDIA =================
    return Scaffold(
      body: BaseDetailListScreen<NoteModel>(
        pageTitle: _controller.currentGroup.groupName,
        items: _controller.currentGroup.notes,
        enableSearch: true,
        enableMultiSelect: true,
        enableAddButton: true,
        enableFavoriteSort: false,
        itemTitle: (note) => note.title,
        headerWidget: _buildSubFoldersHeader(),

        // =========================================================================
        // PERBAIKAN UTAMA: Menggunakan parameter 'additionalAction'
        // =========================================================================
        additionalAction: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.create_new_folder_rounded,
                color: Colors.white,
              ),
              tooltip: 'Buat Sub-Folder',
              onPressed: () => _showSubFolderDialog(),
            ),
            PopupMenuButton<String>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
          tooltip: 'Urutkan Prompt',
          onSelected: _handleSort,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'manual',
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: _currentSortType == 'manual'
                        ? Colors.indigo
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Urutan Manual (Waktu)',
                    style: TextStyle(
                      fontWeight: _currentSortType == 'manual'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'az',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    color: _currentSortType == 'az'
                        ? Colors.indigo
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Abjad: A ➔ Z',
                    style: TextStyle(
                      fontWeight: _currentSortType == 'az'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'za',
              child: Row(
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    color: _currentSortType == 'za'
                        ? Colors.indigo
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Abjad: Z ➔ A',
                    style: TextStyle(
                      fontWeight: _currentSortType == 'za'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ],
        ),

        // 1. Mengembalikan Layout Widget Custom dengan Warna Berbeda
        itemSubtitle: (note) {
          String created = _controller.formatDate(note.createdAt);
          String updated = _controller.formatDate(note.updatedAt);
          bool isTable = note.type == 'table';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Dibuat: $created',
                style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
              ),
              const SizedBox(height: 1),
              Text(
                'Diperbarui: $updated',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
              if (isTable) ...[
                const SizedBox(height: 2),
                Text(
                  'Tipe: Tabel (${note.tableData.length} Baris)',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          );
        },

        // 2. Mengembalikan data String murni agar sistem search bawaan tetap berfungsi
        itemSearchString: (note) {
          String created = _controller.formatDate(note.createdAt);
          String updated = _controller.formatDate(note.updatedAt);
          String typeInfo = note.type == 'table' ? 'tabel table' : 'text teks';
          return '$created $updated $typeInfo';
        },
        itemIsFavorite: (note) => false,
        onAddPressed: () => _showNoteDialog(),
        onItemTap: (note) => _showNoteDialog(existingNote: note),
        itemMenuBuilder: (note) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 18, color: Colors.teal),
                SizedBox(width: 10),
                Text('Edit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  'Hapus',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        onItemMenuSelected: (value, note) async {
          if (value == 'edit') {
            _showNoteDialog(existingNote: note);
          } else if (value == 'delete') {
            final bool confirm = await _controller.showConfirmDialog(
              title: 'Hapus Catatan',
              content:
                  'Apakah Anda yakin ingin menghapus catatan "${note.title}" secara permanen?',
            );

            if (confirm) {
              _controller.deleteNote(note);
            }
          }
        },
        onDeleteMassive: (selectedItems) async {
          await _controller.deleteMassiveNotes(selectedItems);
        },
        onMoveMassive: (selectedItems) {
          _showMoveMassiveDialog(selectedItems);
        },
      ),

      // IMPLEMENTASI LAYOUT FOOTER BANNER MENGGUNAKAN WIDGET ADAPTIVE YANG BARU & SEJAJAR DENGAN DATA UTAMA
      bottomNavigationBar: const AdaptiveBannerAd(adKey: 'note_detail_banner'),
    );
  }
}
