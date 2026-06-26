// lib/features/documents/presentation/screens/document_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
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
  late Directory groupDirectory;
  List<File> physicalFiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    groupDirectory = Directory(
      '${widget.baseDir}/my_documents/${widget.group.id}',
    );
    _loadPhysicalFiles();
  }

  Future<void> _loadPhysicalFiles() async {
    setState(() => isLoading = true);
    try {
      if (!await groupDirectory.exists()) {
        await groupDirectory.create(recursive: true);
      }
      final List<FileSystemEntity> entities = groupDirectory.listSync();
      setState(() {
        physicalFiles = entities
            .whereType<File>()
            .where((file) => !file.path.toLowerCase().endsWith('.json'))
            .toList();
      });
    } catch (e) {
      debugPrint("Gagal memuat daftar file fisik: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _importFileFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => isLoading = true);
        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            File sourceFile = File(pickedFile.path!);
            String fileName = pickedFile.name;
            String targetPath = '${groupDirectory.path}/$fileName';
            await sourceFile.copy(targetPath);
          }
        }
        await _loadPhysicalFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil mengimpor dokumen!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengimpor berkas luar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat mengimpor file.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- FITUR BARU: Dialog & Logika Ganti Nama File (Rename) ---
  void _renamePhysicalFile(File file) {
    final String currentFullName = file.path.split('/').last;
    final int lastDotIndex = currentFullName.lastIndexOf('.');

    // Pisahkan nama file utama dan ekstensinya (.pdf, .docx, dll)
    final String currentNameWithoutExt = lastDotIndex != -1
        ? currentFullName.substring(0, lastDotIndex)
        : currentFullName;
    final String extension = lastDotIndex != -1
        ? currentFullName.substring(lastDotIndex)
        : '';

    final TextEditingController renameController = TextEditingController(
      text: currentNameWithoutExt,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: Colors.blueGrey),
            SizedBox(width: 8),
            Text('Ubah Nama File'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: renameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nama File Baru',
              suffixText: extension,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama file tidak boleh kosong';
              }
              // Menghindari karakter ilegal pada file system OS
              if (value.contains(RegExp(r'[\\/:*?"<>|]'))) {
                return 'Nama mengandung karakter ilegal';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final String newName = renameController.text.trim();
              final String newFullName = '$newName$extension';
              final String targetPath = '${groupDirectory.path}/$newFullName';

              Navigator.pop(ctx);
              setState(() => isLoading = true);

              try {
                if (await File(targetPath).exists()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Gagal! File dengan nama tersebut sudah ada.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  // Eksekusi perubahan nama fisik file
                  await file.rename(targetPath);
                  await _loadPhysicalFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama file berhasil diubah!'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Gagal mengubah nama file fisik: $e");
              } finally {
                setState(() => isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deletePhysicalFile(File file) async {
    final String fileName = file.path.split('/').last;
    final bool confirm = await _showConfirmDeleteDialog(
      title: 'Hapus File?',
      content:
          'Apakah Anda yakin ingin menghapus "$fileName" selamanya dari folder grup ini?',
    );

    if (confirm) {
      try {
        if (await file.exists()) {
          await file.delete();
          await _loadPhysicalFiles();
        }
      } catch (e) {
        debugPrint("Gagal menghapus berkas dokumen: $e");
      }
    }
  }

  Future<void> _deleteMassiveFiles(List<File> selectedFiles) async {
    if (selectedFiles.isEmpty) return;

    final bool confirm = await _showConfirmDeleteDialog(
      title: 'Hapus Masal Berkas',
      content:
          'Apakah Anda yakin ingin menghapus ${selectedFiles.length} file yang dipilih secara masal? Tindakan ini tidak dapat dibatalkan.',
    );

    if (confirm) {
      setState(() => isLoading = true);
      try {
        for (var file in selectedFiles) {
          if (await file.exists()) {
            await file.delete();
          }
        }
        await _loadPhysicalFiles();
      } catch (e) {
        debugPrint("Gagal menghapus berkas dokumen secara massal: $e");
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmDeleteDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Konfirmasi Hapus'),
              ],
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
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

  Future<void> _openDocumentFile(File file) async {
    try {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      debugPrint("Gagal membuka file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada aplikasi yang kompatibel untuk membuka file ini.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String pageTitleWithIcon =
        '${widget.group.icon}  ${widget.group.groupName}';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            )
          : physicalFiles.isEmpty
          ? Scaffold(
              appBar: AppBar(
                title: Text(widget.group.groupName),
                backgroundColor: Colors.blueGrey[800],
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: UniversalEmptyState(
                icon: Icons.drive_folder_upload_rounded,
                title: 'Grup Dokumen Kosong',
                description:
                    'Belum ada berkas tersimpan di grup ini. Ketuk tombol di bawah untuk memasukkan file (PDF, Word, Excel, Gambar, dll).',
                buttonLabel: 'Masukkan File',
                themeColor: Colors.blueGrey,
                onPressed: _importFileFromDevice,
              ),
            )
          : BaseDetailListScreen<File>(
              pageTitle: pageTitleWithIcon,
              items: physicalFiles,
              enableSearch: true,
              enableMultiSelect: true,
              enableAddButton: true,
              enableFavoriteSort: false,
              itemTitle: (file) => file.path.split('/').last,
              itemSubtitle: (file) {
                final String fileName = file.path.split('/').last;
                final String extension = fileName.contains('.')
                    ? fileName.split('.').last.toUpperCase()
                    : 'FILE';

                final int bytes = file.lengthSync();
                final String fileSizeString = bytes >= 1024 * 1024
                    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : '${(bytes / 1024).toStringAsFixed(1)} KB';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        extension.length > 4
                            ? extension.substring(0, 4)
                            : extension,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fileSizeString,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                );
              },
              itemSearchString: (file) => file.path.split('/').last,
              itemIsFavorite: (file) => false,
              onAddPressed: _importFileFromDevice,
              onItemTap: _openDocumentFile,
              // --- MODIFIKASI: Menambahkan Menu Ubah Nama (Rename) ---
              itemMenuBuilder: (file) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                      SizedBox(width: 10),
                      Text('Ubah Nama', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
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
                        'Hapus',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              onItemMenuSelected: (value, file) {
                if (value == 'rename') {
                  _renamePhysicalFile(file);
                } else if (value == 'delete') {
                  _deletePhysicalFile(file);
                }
              },
              onDeleteMassive: (selectedItems) async {
                await _deleteMassiveFiles(selectedItems);
              },
            ),
      floatingActionButton: physicalFiles.isNotEmpty
          ? FloatingActionButton(
              onPressed: _importFileFromDevice,
              backgroundColor: Colors.blueGrey[800],
              tooltip: 'Masukkan File',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
