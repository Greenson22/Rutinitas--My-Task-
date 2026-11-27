// lib/features/documents/presentation/screens/document_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart'; // MENGGUNAKAN open_file biasa untuk mengatasi konflik duplikasi class
import 'package:share_plus/share_plus.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE[cite: 2]
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../data/models/document_model.dart';
import '../../data/services/document_file_service.dart';
import '../controllers/documents_controller.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentGroup group;
  final String baseDir;
  final String? initialFolderId;

  const DocumentDetailScreen({
    super.key,
    required this.group,
    required this.baseDir,
    this.initialFolderId,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late DocumentsController _documentsController;
  late DocumentFileService _fileService;
  List<File> physicalFiles = [];
  List<DocumentFolder> _childFolders = [];
  Map<String, ({int folderCount, int fileCount})> _folderCounts = {};
  String? _currentFolderId;
  bool isLoading = false;

  String _currentSortType = 'manual';

  DocumentGroup get _currentGroup =>
      _documentsController.allGroupRaw
          .where((g) => g.id == widget.group.id)
          .firstOrNull ??
      widget.group;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.initialFolderId;
    _documentsController = DocumentsController();
    _fileService = DocumentFileService(baseDir: widget.baseDir);
    _loadPhysicalFiles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPhysicalFiles() async {
    setState(() => isLoading = true);
    try {
      await _documentsController.loadGroupsData();
      final group = _currentGroup;
      final relPath = _documentsController.folderRelativePath(
        group,
        _currentFolderId,
      );
      final listing = await _fileService.listDirectory(
        group.id,
        relativePath: relPath,
      );
      final folders = _documentsController.getChildFolders(
        group,
        _currentFolderId,
      );
      final counts = <String, ({int folderCount, int fileCount})>{};
      for (final folder in folders) {
        final folderPath = _documentsController.folderRelativePath(
          group,
          folder.id,
        );
        counts[folder.id] = await _fileService.countDirectoryEntries(
          group.id,
          relativePath: folderPath,
        );
      }

      if (mounted) {
        setState(() {
          _childFolders = folders;
          _folderCounts = counts;
          physicalFiles = listing.files;
        });
        _handleSort(_currentSortType);
      }
    } catch (e) {
      debugPrint("Gagal memuat daftar file fisik: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _handleSort(String sortType) {
    setState(() {
      _currentSortType = sortType;
      if (sortType == 'az') {
        physicalFiles.sort((a, b) {
          final nameA = a.path.split('/').last.toLowerCase();
          final nameB = b.path.split('/').last.toLowerCase();
          return nameA.compareTo(nameB);
        });
      } else if (sortType == 'za') {
        physicalFiles.sort((a, b) {
          final nameA = a.path.split('/').last.toLowerCase();
          final nameB = b.path.split('/').last.toLowerCase();
          return nameB.compareTo(nameA);
        });
      } else {
        physicalFiles.sort((a, b) {
          return a.lastModifiedSync().compareTo(b.lastModifiedSync());
        });
      }
    });
  }

  // =========================================================================
  // HELPER FUNCTION 1: SEBELAH KIRI - CONTAINER CIRCLE + ICON SESUAI EKSTENSI
  // =========================================================================
  Widget _getFileIconWidget(String filePath) {
    final File file = File(filePath);
    final String fileName = filePath.split('/').last.toLowerCase();
    final String extension = fileName.contains('.')
        ? fileName.split('.').last
        : '';

    // 1. CEK EKSTENSI GAMBAR UNTUK MEMBERIKAN THUMBNAIL NYATA
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    if (imageExtensions.contains(extension)) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF5F5F5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback ikon jika gambar gagal dimuat (misal korup atau permission)
              return const Icon(
                Icons.broken_image_rounded,
                color: Colors.grey,
                size: 20,
              );
            },
          ),
        ),
      );
    }

    // 2. DEFINE VALUE SEPERTI BIASA UNTUK NON-GAMBAR
    IconData iconData = Icons.insert_drive_file_rounded;
    Color iconColor = const Color(0xFF3F51B5);
    Color bgColor = const Color(0xFFE8EAF6);

    switch (extension) {
      // Documents & Text
      case 'pdf':
        iconData = Icons.picture_as_pdf_rounded;
        iconColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        break;
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        iconData = Icons.description_rounded;
        iconColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        break;
      case 'xls':
      case 'xlsx':
      case 'ods':
      case 'csv':
        iconData = Icons.table_view_rounded;
        iconColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        break;
      case 'ppt':
      case 'pptx':
      case 'odp':
        iconData = Icons.slideshow_rounded;
        iconColor = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;
      case 'txt':
      case 'log':
        iconData = Icons.article_rounded;
        iconColor = Colors.blueGrey.shade700;
        bgColor = Colors.blueGrey.shade50;
        break;

      // Audio
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'flac':
      case 'ogg':
      case 'aac':
      case 'wma':
        iconData = Icons.audiotrack_rounded;
        iconColor = Colors.teal.shade700;
        bgColor = Colors.teal.shade50;
        break;

      // Video
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case '3gp':
        iconData = Icons.video_collection_rounded;
        iconColor = Colors.red.shade900;
        bgColor = Colors.red.shade100;
        break;

      // Archives / Compressed
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        iconData = Icons.folder_zip_rounded;
        iconColor = Colors.amber.shade900;
        bgColor = Colors.amber.shade50;
        break;

      // Code / Programming
      case 'dart':
      case 'java':
      case 'py':
      case 'js':
      case 'ts':
      case 'html':
      case 'css':
      case 'cpp':
      case 'c':
      case 'kt':
      case 'swift':
      case 'php':
      case 'xml':
      case 'yaml':
      case 'json':
        iconData = Icons.code_rounded;
        iconColor = Colors.deepPurpleAccent;
        bgColor = Colors.deepPurple.shade50;
        break;

      // Database
      case 'db':
      case 'sqlite':
      case 'sql':
        iconData = Icons.storage_rounded;
        iconColor = Colors.blueGrey.shade900;
        bgColor = Colors.blueGrey.shade100;
        break;

      // Executables / System
      case 'apk':
        iconData = Icons.android_rounded;
        iconColor = Colors.lightGreen.shade800;
        bgColor = Colors.lightGreen.shade50;
        break;
      case 'exe':
      case 'msi':
        iconData = Icons.laptop_windows_rounded;
        iconColor = Colors.lightBlue.shade900;
        bgColor = Colors.lightBlue.shade100;
        break;

      default:
        iconData = Icons.insert_drive_file_rounded;
        iconColor = Colors.grey.shade700;
        bgColor = Colors.grey.shade200;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  // =========================================================================
  // HELPER FUNCTION 2: FORMALISASI UKURAN FILE (B, KB, MB, GB)
  // =========================================================================
  String _getFileSizeString(File file) {
    try {
      final int bytes = file.lengthSync();
      if (bytes <= 0) return "0 B";
      const suffixes = ["B", "KB", "MB", "GB", "TB"];
      var i = (bytes.toString().length - 1) / 3;
      int floorIndex = i.floor();
      double num = bytes / (1024 * floorIndex * 1024);
      if (floorIndex == 0) num = bytes.toDouble();
      if (floorIndex == 1) num = bytes / 1024;
      if (floorIndex == 2) num = bytes / (1024 * 1024);
      if (floorIndex == 3) num = bytes / (1024 * 1024 * 1024);

      return "${num.toStringAsFixed(1)} ${suffixes[floorIndex]}";
    } catch (_) {
      return "0 B";
    }
  }

  // =========================================================================
  // HELPER FUNCTION 3: FORMALISASI TANGGAL FILE (YYYY-MM-DD HH:MM)
  // =========================================================================
  String _getFileDateString(File file) {
    try {
      final DateTime date = file.lastModifiedSync();
      final String year = date.year.toString();
      final String month = date.month.toString().padLeft(2, '0');
      final String day = date.day.toString().padLeft(2, '0');
      final String hour = date.hour.toString().padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      return "$year-$month-$day $hour:$minute";
    } catch (_) {
      return "-";
    }
  }

  Future<void> _importFileFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => isLoading = true);

        int successCount = 0;

        for (var pickedFile in result.files) {
          if (pickedFile.path == null) continue;
          final File sourceFile = File(pickedFile.path!);
          final String fileName = pickedFile.name;

          DocumentNameConflictPolicy policy =
              DocumentNameConflictPolicy.keepBoth;

          if (await _fileService.fileExistsInGroup(widget.group.id, fileName)) {
            // Sembunyikan loading sejenak agar dialog terlihat jelas
            setState(() => isLoading = false);

            final String? choice = await _showDuplicateConflictDialog(fileName);
            setState(() => isLoading = true);

            if (choice == 'cancel' || choice == null) {
              continue; // Lewati file ini, lanjut ke file berikutnya jika ada
            }

            policy = choice == 'overwrite'
                ? DocumentNameConflictPolicy.overwrite
                : DocumentNameConflictPolicy.keepBoth;
          }

          final File? imported = await _fileService.importFile(
            groupId: widget.group.id,
            sourceFile: sourceFile,
            fileName: fileName,
            relativePath: _documentsController.folderRelativePath(
              _currentGroup,
              _currentFolderId,
            ),
            conflictPolicy: policy,
          );
          if (imported != null) successCount++;
        }

        await _loadPhysicalFiles();

        if (successCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil mengimpor $successCount dokumen!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Gagal mengimpor berkas luar: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String?> _showDuplicateConflictDialog(String fileName) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Pengguna wajib memilih opsi
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('File Sudah Ada'),
          ],
        ),
        content: Text(
          'Berkas dengan nama "$fileName" sudah ada di grup ini. Apa yang ingin Anda lakukan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'copy'),
            child: const Text(
              'Buat Salinan',
              style: TextStyle(color: Colors.teal),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'overwrite'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Timpah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPhysicalFile(File file) async {
    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        setState(() => isLoading = true);

        final String fileName = file.path.split('/').last;
        final String targetPath = '$selectedDirectory/$fileName';

        await file.copy(targetPath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil mengekspor "$fileName" ke direktori tujuan!',
              ),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Gagal mengekspor berkas: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor berkas: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _exportMassiveFiles(List<File> selectedFiles) async {
    if (selectedFiles.isEmpty) return;
    try {
      String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        setState(() => isLoading = true);
        int successCount = 0;

        for (var file in selectedFiles) {
          if (await file.exists()) {
            final String fileName = file.path.split('/').last;
            final String targetPath = '$selectedDirectory/$fileName';
            await file.copy(targetPath);
            successCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Berhasil mengekspor $successCount dari ${selectedFiles.length} berkas!',
              ),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Gagal melakukan ekspor masal: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal ekspor masal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sharePhysicalFile(File file) async {
    try {
      if (await file.exists()) {
        final String fileName = file.path.split('/').last;
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Membagikan berkas: $fileName');
      }
    } catch (e) {
      debugPrint("Gagal membagikan berkas: $e");
    }
  }

  Future<void> _shareMassiveFiles(List<File> selectedFiles) async {
    if (selectedFiles.isEmpty) return;
    try {
      List<XFile> xFilesToShare = [];
      for (var file in selectedFiles) {
        if (await file.exists()) {
          xFilesToShare.add(XFile(file.path));
        }
      }
      if (xFilesToShare.isNotEmpty) {
        await Share.shareXFiles(
          xFilesToShare,
          text: 'Membagikan ${xFilesToShare.length} berkas dokumen.',
        );
      }
    } catch (e) {
      debugPrint("Gagal membagikan beberapa berkas secara masal: $e");
    }
  }

  void _renamePhysicalFile(File file) {
    final String currentFullName = file.path.split('/').last;
    final int lastDotIndex = currentFullName.lastIndexOf('.');

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
        title: const Row(
          children: [
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
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final String newName = renameController.text.trim();

              Navigator.pop(ctx);
              setState(() => isLoading = true);
              try {
                await _fileService.renameFile(
                  groupId: widget.group.id,
                  file: file,
                  newFileName: '$newName$extension',
                  relativePath: _documentsController.folderRelativePath(
                    _currentGroup,
                    _currentFolderId,
                  ),
                  autoRenameOnConflict: true,
                );
                await _loadPhysicalFiles();
              } catch (e) {
                debugPrint("Gagal ganti nama: $e");
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

  void _showMoveDocumentsDialog(List<File> filesToMove) async {
    await _documentsController.loadGroupsData();
    final List<DocumentGroup> availableGroups = _documentsController
        .getAvailableTargetGroups(widget.group.id);

    if (availableGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada grup dokumen lain yang tersedia sebagai tujuan.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.drive_file_move_outlined, color: Colors.blueGrey[800]),
            const SizedBox(width: 10),
            Text('Pindahkan ${filesToMove.length} Dokumen'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableGroups.length,
            itemBuilder: (context, index) {
              final targetGroup = availableGroups[index];
              return ListTile(
                leading: Text(
                  targetGroup.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(targetGroup.groupName),
                subtitle: Text('Kategori: ${targetGroup.sectionCategory}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => isLoading = true);

                  bool success = filesToMove.isNotEmpty;
                  try {
                    for (final file in filesToMove) {
                      final moved = await _fileService.moveFile(
                        file: file,
                        targetGroupId: targetGroup.id,
                        autoRenameWithNumber: true,
                      );
                      if (moved == null) success = false;
                    }
                  } catch (e) {
                    debugPrint("Gagal memindahkan berkas: $e");
                    success = false;
                  }

                  if (success) {
                    await _loadPhysicalFiles();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil memindahkan dokumen ke "${targetGroup.groupName}"',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal memindahkan beberapa berkas.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                  setState(() => isLoading = false);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _deletePhysicalFile(File file) async {
    final String fileName = file.path.split('/').last;
    final bool confirm = await _showConfirmDeleteDialog(
      title: 'Hapus File?',
      content: 'Apakah Anda yakin ingin menghapus "$fileName" selamanya?',
    );
    if (confirm) {
      await _fileService.deleteFile(file);
      await _loadPhysicalFiles();
    }
  }

  Future<void> _deleteMassiveFiles(List<File> selectedFiles) async {
    if (selectedFiles.isEmpty) return;
    final bool confirm = await _showConfirmDeleteDialog(
      title: 'Hapus Masal Berkas',
      content:
          'Apakah Anda yakin ingin menghapus ${selectedFiles.length} file secara masal?',
    );
    if (confirm) {
      setState(() => isLoading = true);
      await _fileService.deleteFiles(selectedFiles);
      await _loadPhysicalFiles();
      setState(() => isLoading = false);
    }
  }

  Future<bool> _showConfirmDeleteDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
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
      final String filePath = file.path.toLowerCase();

      if (filePath.endsWith('.apk')) {
        await OpenFile.open(
          file.path,
          type: "application/vnd.android.package-archive",
        );
      } else {
        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint("Gagal membuka file: $e");
    }
  }

  List<DocumentFolder> _breadcrumbFolders() {
    final byId = {for (final f in _currentGroup.folders) f.id: f};
    final chain = <DocumentFolder>[];
    String? current = _currentFolderId;
    final visited = <String>{};
    while (current != null && current.isNotEmpty) {
      if (!visited.add(current)) break;
      final folder = byId[current];
      if (folder == null) break;
      chain.add(folder);
      current = folder.parentId;
    }
    return chain.reversed.toList();
  }

  Widget _buildBreadcrumbBar() {
    final chain = _breadcrumbFolders();
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: _currentFolderId == null
                  ? null
                  : () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  _currentGroup.groupName,
                  style: TextStyle(
                    fontWeight: _currentFolderId == null
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _currentFolderId == null
                        ? Colors.indigo
                        : Colors.blueGrey,
                  ),
                ),
              ),
            ),
            for (int i = 0; i < chain.length; i++) ...[
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              InkWell(
                onTap: i == chain.length - 1
                    ? null
                    : () {
                        final stepsBack = chain.length - 1 - i;
                        int popped = 0;
                        Navigator.of(context).popUntil((_) => popped++ >= stepsBack);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    chain[i].name,
                    style: TextStyle(
                      fontWeight: i == chain.length - 1
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: i == chain.length - 1
                          ? Colors.indigo
                          : Colors.blueGrey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSection() {
    if (_childFolders.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final folder in _childFolders)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: Text(folder.icon, style: const TextStyle(fontSize: 24)),
              title: Text(
                folder.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _folderSummaryText(folder.id),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'rename') {
                    _showRenameFolderDialog(folder);
                  } else if (action == 'move') {
                    _showMoveFolderDialog(folder);
                  } else if (action == 'delete') {
                    _confirmDeleteFolder(folder);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
                  PopupMenuItem(value: 'move', child: Text('Pindahkan')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              onTap: () => _openFolder(folder),
            ),
          ),
      ],
    );
  }

  String _folderSummaryText(String folderId) {
    final counts = _folderCounts[folderId];
    if (counts == null) return 'Kosong';
    if (counts.folderCount == 0 && counts.fileCount == 0) return 'Kosong';
    return '${counts.folderCount} folder • ${counts.fileCount} berkas';
  }

  Future<void> _openFolder(DocumentFolder folder) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          group: _currentGroup,
          baseDir: widget.baseDir,
          initialFolderId: folder.id,
        ),
      ),
    );
    await _loadPhysicalFiles();
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Folder Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Folder',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final err = await _documentsController.createFolder(
                groupId: _currentGroup.id,
                parentId: _currentFolderId,
                name: controller.text,
              );
              if (!ctx.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              } else {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (created == true) {
      await _loadPhysicalFiles();
    }
  }

  Future<void> _showRenameFolderDialog(DocumentFolder folder) async {
    final controller = TextEditingController(text: folder.name);
    final renamed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Nama Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Folder',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final err = await _documentsController.renameFolder(
                groupId: _currentGroup.id,
                folderId: folder.id,
                newName: controller.text,
              );
              if (!ctx.mounted) return;
              if (err != null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(err)),
                );
              } else {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (renamed == true) {
      await _loadPhysicalFiles();
    }
  }

  Future<void> _showMoveFolderDialog(DocumentFolder folder) async {
    final targets = _currentGroup.folders
        .where((f) => f.id != folder.id)
        .toList();
    String? selectedParentId = folder.parentId;
    final moved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Pindahkan Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                RadioListTile<String?>(
                  value: null,
                  groupValue: selectedParentId,
                  title: Text('Root (${_currentGroup.groupName})'),
                  onChanged: (val) => setDialogState(() => selectedParentId = val),
                ),
                for (final target in targets)
                  RadioListTile<String?>(
                    value: target.id,
                    groupValue: selectedParentId,
                    title: Text('${target.icon} ${target.name}'),
                    onChanged: (val) =>
                        setDialogState(() => selectedParentId = val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final err = await _documentsController.moveFolder(
                  groupId: _currentGroup.id,
                  folderId: folder.id,
                  newParentId: selectedParentId,
                );
                if (!ctx.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Pindahkan'),
            ),
          ],
        ),
      ),
    );
    if (moved == true) {
      await _loadPhysicalFiles();
    }
  }

  Future<void> _confirmDeleteFolder(DocumentFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Folder?'),
        content: Text(
          'Folder "${folder.name}" beserta seluruh subfolder dan berkas di dalamnya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _documentsController.deleteFolder(
        groupId: _currentGroup.id,
        folderId: folder.id,
      );
      await _loadPhysicalFiles();
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
          : physicalFiles.isEmpty && _childFolders.isEmpty
          ? Scaffold(
              appBar: AppBar(
                title: Text(widget.group.groupName),
                backgroundColor: Colors.blueGrey[800],
                actions: [
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    tooltip: 'Folder Baru',
                    onPressed: _showCreateFolderDialog,
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (_currentFolderId != null) _buildBreadcrumbBar(),
                  Expanded(
                    child: UniversalEmptyState(
                      icon: Icons.drive_folder_upload_rounded,
                      title: 'Grup Dokumen Kosong',
                      description: 'Belum ada berkas tersimpan di grup ini.',
                      buttonLabel: 'Masukkan File',
                      themeColor: Colors.blueGrey,
                      onPressed: _importFileFromDevice,
                    ),
                  ),
                ],
              ),
              // IMPLEMENTASI LAYOUT FOOTER BANNER MENGGUNAKAN WIDGET ADAPTIVE PADA KONDISI DATA KOSONG
              bottomNavigationBar: const AdaptiveBannerAd(
                adKey: 'document_detail_banner',
              ),
            )
          : Column(
              children: [
                if (_currentFolderId != null) _buildBreadcrumbBar(),
                if (_childFolders.isNotEmpty) _buildFolderSection(),
                Expanded(
                  child: BaseDetailListScreen<File>(
              pageTitle: pageTitleWithIcon,
              items: physicalFiles,
              enableSearch: true,
              enableMultiSelect: true,
              enableAddButton: true,
              enableFavoriteSort: false,
              itemTitle: (file) => file.path.split('/').last,
              itemIconBuilder: (file) => _getFileIconWidget(file.path),
              itemSubtitle: (file) {
                final String sizeStr = _getFileSizeString(file);
                final String dateStr = _getFileDateString(file);
                return Text(
                  "$sizeStr  •  $dateStr",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
              additionalAction: PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white),
                tooltip: 'Urutkan Dokumen',
                onSelected: _handleSort,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'Urutkan Dokumen',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'manual',
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: _currentSortType == 'manual'
                              ? Colors.blueGrey
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
                              ? Colors.blueGrey
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
                              ? Colors.blueGrey
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
              itemSearchString: (file) => file.path.split('/').last,
              itemIsFavorite: (file) => false,
              onAddPressed: _importFileFromDevice,
              onItemTap: _openDocumentFile,
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
                  value: 'move',
                  child: Row(
                    children: [
                      Icon(
                        Icons.drive_file_move_outlined,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      SizedBox(width: 10),
                      Text('Pindahkan Grup', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.output_rounded, size: 18, color: Colors.amber),
                      SizedBox(width: 10),
                      Text('Ekspor Berkas', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 18, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('Bagikan Berkas', style: TextStyle(fontSize: 13)),
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
                } else if (value == 'move') {
                  _showMoveDocumentsDialog([file]);
                } else if (value == 'export') {
                  _exportPhysicalFile(file);
                } else if (value == 'share') {
                  _sharePhysicalFile(file);
                } else if (value == 'delete') {
                  _deletePhysicalFile(file);
                }
              },
              onDeleteMassive: (selectedItems) async {
                await _deleteMassiveFiles(selectedItems);
              },
              onMoveMassive: (selectedItems) {
                _showMoveDocumentsDialog(selectedItems);
              },
              onExportMassive: (selectedItems) async {
                await _exportMassiveFiles(selectedItems);
              },
              onShareMassive: (selectedItems) async {
                await _shareMassiveFiles(selectedItems);
              },
            ),
                ),
              ],
            ),
      // MENGGUNAKAN WIDGET KUSTOM ADMOB YANG BARU DAN MODULAR PADA FOOTER LAYOUT DATA UTAMA
      bottomNavigationBar: const AdaptiveBannerAd(
        adKey: 'document_detail_banner',
      ),
    );
  }
}
