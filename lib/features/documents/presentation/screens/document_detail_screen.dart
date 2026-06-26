// lib/features/documents/presentation/screens/document_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
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
  late Directory groupDirectory;
  List<File> physicalFiles = [];
  bool isPageEditMode = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Path folder spesifik untuk grup ini: e.g., Documents/my_documents/{group_id}
    groupDirectory = Directory(
      '${widget.baseDir}/my_documents/${widget.group.id}',
    );
    _loadPhysicalFiles();
  }

  // Membaca file asli dari penyimpanan lokal grup
  Future<void> _loadPhysicalFiles() async {
    setState(() => isLoading = true);
    try {
      if (!await groupDirectory.exists()) {
        await groupDirectory.create(recursive: true);
      }

      final List<FileSystemEntity> entities = groupDirectory.listSync();
      setState(() {
        // PERBAIKAN UTAMA: Menampilkan semua file fisik KECUALI file konfigurasi .json
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

  // Alur memasukkan file luar (Import) ke dalam repositori aplikasi
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

            // Salin file ke dalam direktori khusus grup dokumen ini
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

  // Menghapus file dokumen dari penyimpanan fisik internal grup
  void _deletePhysicalFile(File file) async {
    final String fileName = file.path.split('/').last;
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus File?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "$fileName" selamanya dari folder grup ini?',
            ),
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

  // Membuka file menggunakan intent / aplikasi default bawaan OS HP atau Desktop
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.group.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(widget.group.groupName),
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            )
          : physicalFiles.isEmpty
          ? UniversalEmptyState(
              icon: Icons.drive_folder_upload_rounded,
              title: 'Grup Dokumen Kosong',
              description:
                  'Belum ada berkas tersimpan di grup ini. Ketuk tombol di bawah untuk memasukkan file (PDF, Word, Excel, Gambar, dll).',
              buttonLabel: 'Masukkan File',
              themeColor: Colors.blueGrey,
              onPressed: _importFileFromDevice,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: physicalFiles.length,
              itemBuilder: (context, index) {
                final File file = physicalFiles[index];
                final String fileName = file.path.split('/').last;
                final String extension = fileName.contains('.')
                    ? fileName.split('.').last.toUpperCase()
                    : 'FILE';

                // Hitung ukuran file secara dinamis
                final int bytes = file.lengthSync();
                final String fileSizeString = bytes >= 1024 * 1024
                    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
                    : '${(bytes / 1024).toStringAsFixed(1)} KB';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey.shade50,
                      child: Text(
                        extension.length > 3
                            ? extension.substring(0, 3)
                            : extension,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      fileSizeString,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: isPageEditMode
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePhysicalFile(file),
                          )
                        : const Icon(
                            Icons.open_in_new_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                    onTap: isPageEditMode
                        ? null
                        : () => _openDocumentFile(file),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importFileFromDevice,
        backgroundColor: Colors.blueGrey,
        tooltip: 'Masukkan File',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
