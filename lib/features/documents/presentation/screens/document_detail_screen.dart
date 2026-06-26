// lib/features/documents/presentation/screens/document_detail_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../data/models/document_model.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentGroup group;
  final String baseDir;

  const DocumentDetailScreen({
    super.key,
    required this.group,
    required this.baseDir,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final StorageService storageService = StorageService();
  late DocumentGroup currentGroup;
  bool isPageEditMode = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    currentGroup = widget.group;
  }

  Future<void> saveGroupData() async {
    try {
      File file = await storageService.getSpecificDocumentGroupFile(
        widget.baseDir,
        currentGroup.id,
      );
      String jsonStr = jsonEncode(currentGroup.toJson());
      await file.writeAsString(jsonStr);
      setState(() {});
    } catch (e) {
      debugPrint("Gagal menyimpan Document Detail: $e");
    }
  }

  void _showAddDocumentDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Dokumen Baru'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Judul Dokumen',
            hintText: 'Contoh: Rapat Q3, Resep Kue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final newItem = DocumentItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  lastModified: DateTime.now().toIso8601String(),
                );

                if (currentGroup.allList.isEmpty) {
                  currentGroup.allList.add(
                    DocumentSection(sectionName: 'General', items: [newItem]),
                  );
                } else {
                  currentGroup.allList.first.items.insert(0, newItem);
                }

                saveGroupData();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('Buat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteItem(DocumentItem item) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Dokumen?'),
            content: Text('Hapus "${item.title}" selamanya?'),
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
      setState(() {
        for (var section in currentGroup.allList) {
          section.items.removeWhere((i) => i.id == item.id);
        }
      });
      saveGroupData();
    }
  }

  // Fungsi untuk menampilkan editor/preview konten seperti notes
  void _openDocumentContent(DocumentItem item) {
    final contentController = TextEditingController(text: item.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item.title),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: contentController,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: 'Mulai menulis isi dokumen...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF9F9F9),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.content = contentController.text;
                item.lastModified = DateTime.now().toIso8601String();
              });
              saveGroupData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dokumen disimpan!'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = 0;
    for (var section in currentGroup.allList) {
      totalItems += section.items.length;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Text(currentGroup.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(currentGroup.groupName),
          ],
        ),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: Icon(isPageEditMode ? Icons.check : Icons.edit),
            onPressed: () => setState(() => isPageEditMode = !isPageEditMode),
          ),
        ],
      ),
      body: currentGroup.allList.isEmpty || totalItems == 0
          ? UniversalEmptyState(
              icon: Icons.note_add_rounded,
              title: 'Grup Dokumen Kosong',
              description:
                  'Grup dokumen ini belum memiliki lembar kerja. Tambahkan dokumen baru sekarang.',
              buttonLabel: 'Buat Dokumen',
              themeColor: Colors.blueGrey,
              onPressed: _showAddDocumentDialog,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: currentGroup.allList.length,
              itemBuilder: (context, sectionIndex) {
                final section = currentGroup.allList[sectionIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentGroup.allList.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Text(
                          section.sectionName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ...section.items.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.description,
                            color: Colors.blueGrey,
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            item.content.isEmpty
                                ? 'Isi dokumen kosong...'
                                : item.content.replaceAll('\n', ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: isPageEditMode
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteItem(item),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => _openDocumentContent(item),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDocumentDialog,
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
