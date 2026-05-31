// lib/features/prompt/presentation/screens/prompt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ========= FITUR BARU DIALOG =========

  void _showEditPromptDialog(PromptItem item) {
    final titleController = TextEditingController(text: item.actAs);
    final contentController = TextEditingController(text: item.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Prompt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul / Peran',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Isi Prompt',
                  border: OutlineInputBorder(),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  contentController.text.trim().isEmpty)
                return;

              final updatedGroup = await _controller.editPromptItem(
                group: _currentGroup,
                itemId: item.id,
                newActAs: titleController.text,
                newContent: contentController.text,
                context: context,
              );

              if (updatedGroup != null) {
                setState(() => _currentGroup = updatedGroup);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeletePromptDialog(PromptItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Prompt?'),
        content: Text(
          'Anda yakin ingin menghapus prompt "${item.actAs}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final updatedGroup = await _controller.deletePromptItem(
                group: _currentGroup,
                itemId: item.id,
                context: context,
              );

              if (updatedGroup != null) {
                setState(() => _currentGroup = updatedGroup);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMoveOrCopyDialog(PromptItem item, bool isCopy) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            // Tampilkan list grup. Jika Move (pindah), sembunyikan grup yang sama.
            final availableGroups = _controller.promptGroups.where((g) {
              return isCopy || g.id != _currentGroup.id;
            }).toList();

            return AlertDialog(
              title: Text(isCopy ? 'Salin ke Group...' : 'Pindah ke Group...'),
              content: SizedBox(
                width: double.maxFinite,
                child: availableGroups.isEmpty
                    ? const Text('Tidak ada group prompt lain yang tersedia.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableGroups.length,
                        itemBuilder: (context, index) {
                          final targetGroup = availableGroups[index];
                          return ListTile(
                            leading: Text(
                              targetGroup.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(targetGroup.title),
                            subtitle: Text(
                              targetGroup.sectionName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () async {
                              final updatedGroup = await _controller
                                  .moveOrCopyPromptItem(
                                    sourceGroup: _currentGroup,
                                    targetGroup: targetGroup,
                                    item: item,
                                    isCopy: isCopy,
                                    context: context,
                                  );

                              if (updatedGroup != null) {
                                setState(() => _currentGroup = updatedGroup);
                              }
                              if (context.mounted) Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Text(_currentGroup.icon),
            const SizedBox(width: 8),
            Text(_currentGroup.title),
          ],
        ),
        backgroundColor: Colors.indigo,
      ),
      body: _currentGroup.prompts.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada item prompt di dalam grup ini.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentGroup.prompts.length,
              itemBuilder: (context, index) {
                final item = _currentGroup.prompts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      child: Icon(
                        item.isFavorite ? Icons.star : Icons.description,
                        color: item.isFavorite ? Colors.orange : Colors.indigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.actAs,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.indigo,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        item.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    // ========= MENU AKSI BARU (TRAILING) =========
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.grey,
                            size: 20,
                          ),
                          tooltip: 'Salin Teks Prompt',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: item.content),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Berhasil menyalin: ${item.actAs}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
                          ),
                          tooltip: 'Menu Tambahan',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditPromptDialog(item);
                            } else if (value == 'move') {
                              _showMoveOrCopyDialog(item, false);
                            } else if (value == 'copy') {
                              _showMoveOrCopyDialog(item, true);
                            } else if (value == 'delete') {
                              _showDeletePromptDialog(item);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: Colors.indigo,
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
                              value: 'move',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.drive_file_move_outline,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Pindah Group',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.content_copy,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Salin ke Group Lain',
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
                                    Icons.delete_outline,
                                    size: 18,
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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPromptDialog,
        backgroundColor: Colors.indigo,
        tooltip: 'Tambah Item Prompt Baru',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
