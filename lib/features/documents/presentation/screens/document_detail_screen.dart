// lib/features/documents/presentation/screens/document_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart'; // <-- TAMBAHAN: Untuk fitur bagikan file ke sistem OS Android/Linux
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/presentation/widgets/base_detail_list_screen.dart';
import '../../data/models/document_model.dart';
import '../controllers/documents_controller.dart';

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
  late DocumentsController _documentsController;
  late Directory groupDirectory;
  List<File> physicalFiles = [];
  bool isLoading = false;

  String _currentSortType = 'manual';

  @override
  void initState() {
    super.initState();
    _documentsController = DocumentsController();
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

      _handleSort(_currentSortType);
    } catch (e) {
      debugPrint("Gagal memuat daftar file fisik: $e");
    } finally {
      setState(() => isLoading = false);
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
    } finally {
      setState(() => isLoading = false);
    }
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

  // =========================================================================
  // FITUR BARU: LOGIKA MEMBAGIKAN BERKAS KE SYSTEM OS (WHATSAPP, DLL)
  // =========================================================================
  Future<void> _sharePhysicalFile(File file) async {
    try {
      if (await file.exists()) {
        final String fileName = file.path.split('/').last;
        // Menggunakan XFile dari paket share_plus untuk membagikan file fisik
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
              if (value == null || value.trim().isEmpty)
                return 'Nama file tidak boleh kosong';
              if (value.contains(RegExp(r'[\\/:*?"<>|]')))
                return 'Nama mengandung karakter ilegal';
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
              final String targetPath =
                  '${groupDirectory.path}/$newName$extension';

              Navigator.pop(ctx);
              setState(() => isLoading = true);
              try {
                if (!await File(targetPath).exists()) {
                  await file.rename(targetPath);
                  await _loadPhysicalFiles();
                }
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

                  final bool success = await _documentsController
                      .movePhysicalFiles(
                        filesToMove: filesToMove,
                        currentGroupId: widget.group.id,
                        targetGroupId: targetGroup.id,
                      );

                  if (success) {
                    await _loadPhysicalFiles();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Berhasil memindahkan dokumen ke "${targetGroup.groupName}"',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  } else {
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
      if (await file.exists()) {
        await file.delete();
        await _loadPhysicalFiles();
      }
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
      for (var file in selectedFiles) {
        if (await file.exists()) await file.delete();
      }
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
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("Gagal membuka file: $e");
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
              ),
              body: UniversalEmptyState(
                icon: Icons.drive_folder_upload_rounded,
                title: 'Grup Dokumen Kosong',
                description: 'Belum ada berkas tersimpan di grup ini.',
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
              additionalAction: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                tooltip: 'Pilihan Menu',
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
              itemSubtitle: (file) {
                final String fileName = file.path.split('/').last;
                final String extension = fileName.contains('.')
                    ? fileName.split('.').last.toUpperCase()
                    : 'FILE';
                return Text(
                  extension,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                );
              },
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
                // ---------------------------------------------------------
                // OPSI MENU BARU: BAGIKAN BERKAS (SHARE SATUAN)
                // ---------------------------------------------------------
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
                  _sharePhysicalFile(file); // Pemicu share berkas tunggal
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
              // ---------------------------------------------------------
              // INTEGRASI TERINTEGRASI: HANDLER KUSTOM BAGIKAN MASAL DI PARENT WIDGET
              // ---------------------------------------------------------
              onShareMassive: (selectedItems) async {
                await _shareMassiveFiles(selectedItems);
              },
            ),
    );
  }
}
