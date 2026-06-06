// lib/features/prompt/presentation/screens/prompt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../data/models/prompt_model.dart';
import '../controllers/prompt_controller.dart';
import '../widgets/prompt_detail_screen/add_prompt_item_dialog.dart';

class PromptDetailScreen extends StatefulWidget {
  final PromptGroup promptGroup;

  const PromptDetailScreen({super.key, required this.promptGroup});

  @override
  State<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends State<PromptDetailScreen> {
  late PromptGroup _currentGroup;
  final PromptController _controller = PromptController();

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.promptGroup;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAllPrompts(context);
    });
  }

  @override
  void dispose() {
    _controller.clearSelectedPrompts();
    super.dispose();
  }

  void _openAddPromptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddPromptItemDialog(
        currentGroup: _currentGroup,
        controller: _controller,
        onPromptAdded: (updatedGroup) {
          setState(() {
            _currentGroup = updatedGroup;
          });
        },
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Isi prompt berhasil disalin ke clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // =========================================================================
  // MANAJEMEN VERSI PROMPT (PILIH, TAMBAH, EDIT, HAPUS)
  // =========================================================================

  /// Menampilkan dialog untuk memilih versi aktif atau menavigasi ke pembuatan/perubahan versi
  void _openVersionSelectorDialog(PromptItem item) {
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.history, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Pilih Versi Prompt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: item.versions.length,
                itemBuilder: (context, idx) {
                  final version = item.versions[idx];
                  final isScalarActive = version.id == item.activeVersionId;

                  return ListTile(
                    dense: true,
                    title: Text(
                      version.versionName,
                      style: TextStyle(
                        fontWeight: isScalarActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isScalarActive ? Colors.indigo : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      version.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isScalarActive)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.indigo,
                              size: 20,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.teal,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openEditVersionDialog(item, version);
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showDeleteVersionDialog(item, version);
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _controller.switchPromptVersion(
                        group: _currentGroup,
                        itemId: item.id,
                        versionId: version.id,
                        context: context,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.add_rounded, color: Colors.teal),
              title: const Text(
                'Buat Versi Baru...',
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openCreateVersionDialog(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan dialog input nama untuk membuat salinan instruksi versi baru
  void _openCreateVersionDialog(PromptItem item) {
    final versionNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.teal,
        titleColor: Colors.white,
        title: Row(
          children: const [
            Icon(
              Icons.create_new_folder_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Buat Versi Baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: versionNameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Versi',
                hintText: 'Misal: v2.0 - Optimasi GPT4',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Nama versi tidak boleh kosong' : null,
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openVersionSelectorDialog(item);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx);
                    await _controller.createNewPromptVersion(
                      group: _currentGroup,
                      itemId: item.id,
                      versionName: versionNameController.text,
                      context: context,
                    );
                  }
                },
                child: const Text(
                  'Buat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan dialog untuk mengubah nama versi prompt
  void _openEditVersionDialog(PromptItem item, PromptVersion version) {
    final versionNameController = TextEditingController(
      text: version.versionName,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.teal,
        titleColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.edit_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Edit Nama Versi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: versionNameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama Versi',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Nama versi tidak boleh kosong' : null,
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openVersionSelectorDialog(item);
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx);
                    await _controller.editPromptVersionName(
                      group: _currentGroup,
                      itemId: item.id,
                      versionId: version.id,
                      newVersionName: versionNameController.text,
                      context: context,
                    );
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan dialog konfirmasi penghapusan versi prompt
  void _showDeleteVersionDialog(PromptItem item, PromptVersion version) {
    if (item.versions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak bisa menghapus satu-satunya versi!'),
        ),
      );
      _openVersionSelectorDialog(item);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Versi?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus versi "${version.versionName}"? Tindakan ini permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openVersionSelectorDialog(item);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.deletePromptVersion(
                group: _currentGroup,
                itemId: item.id,
                versionId: version.id,
                context: context,
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========= FITUR EDIT, HAPUS, MOVE/COPY DIALOG =========
  void _openEditPromptDialog(PromptItem item) {
    final actAsController = TextEditingController(text: item.actAs);
    final descController = TextEditingController(text: item.description ?? '');
    final contentController = TextEditingController(
      text: item.activeVersion.content,
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Edit Item Prompt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: actAsController,
                  decoration: const InputDecoration(
                    labelText: 'Act As / Judul',
                    hintText: 'Misal: Ahli SEO, Kode Reviewer',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat (Opsional)',
                    hintText: 'Keterangan singkat guna/fungsi prompt',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Isi Prompt (${item.activeVersion.versionName})',
                    hintText: 'Masukkan instruksi detail AI...',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v!.trim().isEmpty
                      ? 'Isi prompt tidak boleh kosong'
                      : null,
                ),
              ],
            ),
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx);
                    final res = await _controller.editPromptItem(
                      group: _currentGroup,
                      itemId: item.id,
                      newActAs: actAsController.text,
                      newDescription: descController.text,
                      newContent: contentController.text,
                      context: context,
                    );
                    if (res != null) {
                      setState(() {
                        _currentGroup = res;
                      });
                    }
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteSingleDialog(PromptItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Prompt "${item.actAs}"?'),
        content: const Text('Tindakan ini permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _controller.deletePromptItem(
                group: _currentGroup,
                itemId: item.id,
                context: context,
              );
              if (res != null) {
                setState(() {
                  _currentGroup = res;
                });
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteMassiveDialog(List<PromptItem> selectedItems) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item Terpilih?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${selectedItems.length} prompt ini secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

              _controller.clearSelectedPrompts();
              for (var item in selectedItems) {
                _controller.toggleSelectPromptItem(item.id);
              }

              final res = await _controller.deleteSelectedPromptItems(
                group: _currentGroup,
                context: context,
              );
              if (res != null) {
                setState(() {
                  _currentGroup = res;
                });
              }
            },
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoveOrCopyDialog(PromptItem item) {
    final otherGroups = _controller.promptGroups
        .where((g) => g.id != _currentGroup.id)
        .toList();
    if (otherGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada grup prompt lain yang tersedia.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: const Text(
          'Pindahkan / Salin Prompt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Grup Target:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherGroups.length,
                  itemBuilder: (c, idx) {
                    final targetG = otherGroups[idx];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        targetG.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetG.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        targetG.sectionName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final res = await _controller
                                  .moveOrCopyPromptItem(
                                    sourceGroup: _currentGroup,
                                    targetGroup: targetG,
                                    item: item,
                                    isCopy: true,
                                    context: context,
                                  );
                              if (res != null) {
                                setState(() {
                                  _currentGroup = res;
                                });
                              }
                            },
                            child: const Text(
                              'Salin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final res = await _controller
                                  .moveOrCopyPromptItem(
                                    sourceGroup: _currentGroup,
                                    targetGroup: targetG,
                                    item: item,
                                    isCopy: false,
                                    context: context,
                                  );
                              if (res != null) {
                                setState(() {
                                  _currentGroup = res;
                                });
                              }
                            },
                            child: const Text(
                              'Pindah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoveMassiveDialog(List<PromptItem> selectedItems) {
    final otherGroups = _controller.promptGroups
        .where((g) => g.id != _currentGroup.id)
        .toList();
    if (otherGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada grup prompt lain yang tersedia.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        title: Text(
          'Pindahkan ${selectedItems.length} Prompt Terpilih',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        themeColor: Colors.indigo,
        titleColor: Colors.white,
        content: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Grup Target Pemindahan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherGroups.length,
                  itemBuilder: (c, idx) {
                    final targetG = otherGroups[idx];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        targetG.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        targetG.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        targetG.sectionName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);

                          _controller.clearSelectedPrompts();
                          for (var item in selectedItems) {
                            _controller.toggleSelectPromptItem(item.id);
                          }

                          final res = await _controller.moveSelectedPromptItems(
                            sourceGroup: _currentGroup,
                            targetGroup: targetG,
                            context: context,
                          );
                          if (res != null) {
                            setState(() {
                              _currentGroup = res;
                            });
                          }
                        },
                        child: const Text(
                          'Pindah Ke Sini',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final PromptGroup updatedGroup = _controller.promptGroups.firstWhere(
          (g) => g.id == _currentGroup.id,
          orElse: () => _currentGroup,
        );
        _currentGroup = updatedGroup;

        return BaseDetailListScreen<PromptItem>(
          pageTitle: _currentGroup.title,
          items: _currentGroup.prompts,
          enableSearch: true,
          enableMultiSelect: true,
          enableAddButton: true,
          enableFavoriteSort: true,

          itemTitle: (item) => item.actAs,

          itemSubtitle: (item) {
            final hasDesc =
                item.description != null && item.description!.trim().isNotEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasDesc ? item.description! : 'Tidak ada deskripsi',
                  style: TextStyle(
                    color: hasDesc ? Colors.blueGrey[700] : Colors.grey[400],
                    fontSize: 13,
                    fontStyle: hasDesc ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Versi Aktif: ${item.activeVersion.versionName}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Total: ${item.versions.length} Versi',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },

          itemSearchString: (item) =>
              (item.description != null) ? item.description! : '',
          itemIsFavorite: (item) => item.isFavorite,

          onAddPressed: _openAddPromptDialog,
          onItemTap: (item) => _copyToClipboard(item.activeVersion.content),
          onDeleteMassive: _showDeleteMassiveDialog,
          onMoveMassive: _showMoveMassiveDialog,

          itemMenuBuilder: (item) => [
            const PopupMenuItem(
              value: 'manage_versions',
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.indigo),
                  SizedBox(width: 10),
                  Text('Pilih / Tambah Versi', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 20, color: Colors.teal),
                  SizedBox(width: 10),
                  Text('Edit Prompt', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_favorite',
              child: Row(
                children: [
                  Icon(
                    item.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.isFavorite ? 'Hapus Favorit' : 'Jadikan Favorit',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'move_or_copy',
              child: Row(
                children: [
                  Icon(
                    Icons.drive_file_move_outlined,
                    size: 20,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(width: 10),
                  Text('Pindah / Salin', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Hapus Prompt',
                    style: TextStyle(fontSize: 13, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],

          onItemMenuSelected: (value, item) async {
            if (value == 'manage_versions') {
              _openVersionSelectorDialog(item);
            } else if (value == 'edit') {
              _openEditPromptDialog(item);
            } else if (value == 'toggle_favorite') {
              final res = await _controller.toggleFavoritePromptItem(
                group: _currentGroup,
                itemId: item.id,
                context: context,
              );
              if (res != null) {
                setState(() {
                  _currentGroup = res;
                });
              }
            } else if (value == 'move_or_copy') {
              _showMoveOrCopyDialog(item);
            } else if (value == 'delete') {
              _showDeleteSingleDialog(item);
            }
          },
        );
      },
    );
  }
}
