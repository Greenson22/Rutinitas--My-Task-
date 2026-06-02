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
    final descController = TextEditingController(text: item.description ?? '');
    final contentController = TextEditingController(text: item.content);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => BasePopupDialog(
        themeColor: Colors.indigo,
        titleColor: Colors.white,

        // 1. BANNER CUSTOM HEADER
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Ubah Detail Prompt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // 2. FORM BODY INPUTS
        content: Form(
          key: formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul / Peran (Act As)',
                  hintText: 'Contoh: Translator Bahasa, Senior Developer',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Judul/Peran tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Pendek (Opsional)',
                  hintText: 'Keterangan singkat guna/fungsi prompt',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contentController,
                maxLines: 6,
                minLines: 3,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Isi Perintah Prompt',
                  hintText: 'Tulis instruksi lengkap AI di sini...',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Isi prompt tidak boleh kosong' : null,
              ),
            ],
          ),
        ),

        // 3. DIALOG ACTIONS BUTTON PANEL
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
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 16, color: Colors.white),
                label: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(color: Colors.white),
                ),
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
                    final updatedGroup = await _controller.editPromptItem(
                      group: _currentGroup,
                      itemId: item.id,
                      newActAs: titleController.text.trim(),
                      newDescription: descController.text.trim(),
                      newContent: contentController.text.trim(),
                      context: context,
                    );
                    if (updatedGroup != null) {
                      setState(() => _currentGroup = updatedGroup);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('  Prompt berhasil diperbarui!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
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
                  margin: const EdgeInsets.only(
                    bottom: 8,
                  ), // Dikurangi dari 12 agar jarak antar kartu lebih rapat
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense:
                        true, // 1. MENGAKTIFKAN DENSE MODE: Membuat komponen internal ListTile otomatis lebih rapat/pendek
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ), // 2. DIKURANGI: Mengubah vertikal padding dari 16 menjadi 6
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      radius:
                          16, // 3. OPTIONAL: Sedikit mengecilkan ukuran lingkar avatar dari default bawaan (biasanya 20)
                      child: Icon(
                        item.isFavorite ? Icons.star : Icons.description,
                        color: item.isFavorite ? Colors.orange : Colors.indigo,
                        size:
                            16, // Menyesuaikan ukuran icon di dalam avatar kecil
                      ),
                    ),
                    title: Text(
                      item.actAs,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            14, // Sedikit disesuaikan untuk keseimbangan dense mode
                        color: Colors.indigo,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(
                        top: 2.0,
                      ), // Jarak atas teks subtitle dikurangi dari 6.0 menjadi 2.0
                      child: Text(
                        (item.description != null &&
                                item.description!.trim().isNotEmpty)
                            ? item.description!
                            : 'Tidak ada deskripsi',
                        maxLines:
                            1, // 4. PEMBATAS BARIS: Memastikan teks deskripsi yang panjang tidak merusak ukuran tinggi kartu
                        overflow: TextOverflow
                            .ellipsis, // Memberikan efek titik-titik (...) jika teks deskripsi terlalu panjang
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              (item.description != null &&
                                  item.description!.trim().isNotEmpty)
                              ? Colors.black87
                              : Colors.grey,
                          height: 1.2,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: Colors.grey,
                            size:
                                18, // Sedikit diperkecil agar pas dengan tinggi item yang pendek
                          ),
                          tooltip: 'Salin Teks Prompt',
                          constraints:
                              const BoxConstraints(), // Menghilangkan batas ukuran default IconButton
                          padding: const EdgeInsets.all(
                            4,
                          ), // Merapatkan area sentuh tombol copy
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
                            size: 18, // Sedikit diperkecil
                          ),
                          tooltip: 'Menu Tambahan',
                          constraints:
                              const BoxConstraints(), // Menghilangkan batas ukuran default
                          padding: const EdgeInsets.all(
                            4,
                          ), // Merapatkan area sentuh tombol menu
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
                            // ... isi item popupMenu Anda tetap sama seperti sebelumnya ...
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
