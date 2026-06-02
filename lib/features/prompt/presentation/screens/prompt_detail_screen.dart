// lib/features/prompt/presentation/screens/prompt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/presentation/widgets/base_popup_dialog.dart';
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

    // Muat semua grup ke controller agar fitur pindah/salin bisa mengambil daftar grup lain
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAllPrompts(context);
    });
  }

  @override
  void dispose() {
    // Pastikan state multi-select dibersihkan saat keluar dari screen ini
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

  // ========= FITUR EDIT, HAPUS, MOVE/COPY DIALOG =========

  void _openEditPromptDialog(PromptItem item) {
    final actAsController = TextEditingController(text: item.actAs);
    final descController = TextEditingController(text: item.description ?? '');
    final contentController = TextEditingController(text: item.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item Prompt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: actAsController,
                decoration: const InputDecoration(labelText: 'Act As / Judul'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Singkat',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Isi Prompt template',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
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
            },
            child: const Text('Simpan'),
          ),
        ],
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

  void _showDeleteMassiveDialog(int totalSelected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item Terpilih?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus $totalSelected prompt ini secara permanen?',
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Isi prompt berhasil disalin ke clipboard!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showMoveMassiveDialog(int totalSelected) {
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
          'Pindahkan $totalSelected Prompt Terpilih',
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

        final bool isSelectMode = _controller.isMultiSelectMode;
        final int totalSelected = _controller.selectedPromptIds.length;

        return Scaffold(
          backgroundColor: const Color(
            0xFFF5F6FA,
          ), // Background abu-abu terang sesuai gambar
          appBar: AppBar(
            title: Text(
              isSelectMode ? '$totalSelected Terpilih' : _currentGroup.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: isSelectMode
                ? Colors.red[900]
                : const Color(0xFF3F51B5),
            elevation: 0,
            leading: isSelectMode
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => _controller.clearSelectedPrompts(),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
            actions: [
              if (isSelectMode)
                IconButton(
                  icon: const Icon(Icons.drive_file_move, color: Colors.white),
                  tooltip: 'Pindahkan Semua Terpilih',
                  onPressed: () => _showMoveMassiveDialog(totalSelected),
                ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Hapus Semua Terpilih',
                onPressed: () => _showDeleteMassiveDialog(totalSelected),
              ),
            ],
          ),
          body: _currentGroup.prompts.isEmpty
              ? const Center(
                  child: Text(
                    'Grup ini belum memiliki item prompt.\nSilakan tambah menggunakan tombol di bawah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  itemCount: _currentGroup.prompts.length,
                  itemBuilder: (context, index) {
                    final item = _currentGroup.prompts[index];
                    final bool isSelected = _controller.selectedPromptIds
                        .contains(item.id);

                    // Mengecek ketersediaan deskripsi
                    final bool hasDescription =
                        item.description != null &&
                        item.description!.trim().isNotEmpty;

                    return Card(
                      elevation: isSelected
                          ? 4
                          : 0, // Mengurangi elevasi default agar flat minimalis
                      color: isSelected
                          ? Colors.red.withOpacity(0.08)
                          : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          16,
                        ), // Sisi melengkung halus sesuai gambar
                        side: BorderSide(
                          color: isSelected
                              ? Colors.red[700]!
                              : Colors.grey.shade100, // Border tipis transparan
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (isSelectMode) {
                            _controller.toggleSelectPromptItem(item.id);
                          } else {
                            _copyToClipboard(item.content);
                          }
                        },
                        onLongPress: () {
                          _controller.toggleSelectPromptItem(item.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // MODE SELEKSI: Tampilkan Checkbox
                              if (isSelectMode) ...[
                                Checkbox(
                                  activeColor: Colors.red[700],
                                  value: isSelected,
                                  onChanged: (_) => _controller
                                      .toggleSelectPromptItem(item.id),
                                ),
                                const SizedBox(width: 12),
                              ]
                              // MODE NORMAL: Tampilkan Ikon Dokumen Biru Elegan
                              else ...[
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE8EAF6,
                                    ), // Biru pastel sangat muda
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.description_rounded,
                                    color: Color(
                                      0xFF3F51B5,
                                    ), // Warna ikon disesuaikan tema
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],

                              // TEXT CONTENT
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.actAs,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(
                                          0xFF2E3A59,
                                        ), // Warna teks kontras modern
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasDescription
                                          ? item.description!
                                          : 'Tidak ada deskripsi',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: hasDescription
                                            ? Colors.grey[600]
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ACTION BUTTONS (Hanya muncul jika tidak dalam select mode)
                              if (!isSelectMode) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.black38,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Salin Konten',
                                      onPressed: () =>
                                          _copyToClipboard(item.content),
                                    ),
                                    const SizedBox(width: 12),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.black38,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _openEditPromptDialog(item);
                                        } else if (value == 'move_or_copy') {
                                          _showMoveOrCopyDialog(item);
                                        } else if (value == 'delete') {
                                          _showDeleteSingleDialog(item);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_note_rounded,
                                                size: 20,
                                                color: Colors.teal,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Edit Prompt',
                                                style: TextStyle(fontSize: 13),
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
                                                color: Colors.indigo,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Pindah / Salin',
                                                style: TextStyle(fontSize: 13),
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
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: Colors.redAccent,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Hapus Prompt',
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
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: isSelectMode
              ? null
              : FloatingActionButton(
                  onPressed: _openAddPromptDialog,
                  backgroundColor: const Color(0xFF3F51B5),
                  tooltip: 'Tambah Item Prompt Baru',
                  child: const Icon(Icons.add, color: Colors.white),
                ),
        );
      },
    );
  }
}
