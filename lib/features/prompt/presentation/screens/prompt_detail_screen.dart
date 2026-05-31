// lib/features/prompt/presentation/screens/prompt_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/prompt_model.dart';
import '../controllers/prompt_controller.dart';

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
    // Menyalin referensi data awal ke variabel state lokal
    _currentGroup = widget.promptGroup;
  }

  void _showAddPromptItemDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.playlist_add, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Tambah Item Prompt'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul / Peran (Title)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Title tidak boleh kosong' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Pendek (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Perintah Prompt (Content)',
                    border: OutlineInputBorder(),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Memanggil fungsi simpan dan mengambil objek Group terbaru yang dikembalikan controller
                final updatedGroup = await _controller.addPromptItemToGroup(
                  group: _currentGroup,
                  title: titleController.text,
                  description: descController.text,
                  content: contentController.text,
                  context: context,
                );

                if (updatedGroup != null && mounted) {
                  setState(() {
                    // Paksa UI memperbarui state dengan data grup yang paling baru
                    _currentGroup = updatedGroup;
                  });
                }

                if (context.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text(
              'Simpan Prompt',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.grey,
                        size: 20,
                      ),
                      tooltip: 'Salin Prompt',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: item.content),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Berhasil menyalin: ${item.actAs}'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPromptItemDialog(context),
        backgroundColor: Colors.indigo,
        tooltip: 'Tambah Item Prompt Baru',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
