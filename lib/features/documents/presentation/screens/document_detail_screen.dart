// lib/features/documents/presentation/screens/document_detail_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
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

  // Variabel kontrol untuk Banner AdMob
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Getter adaptif untuk menentukan Ad Unit ID Iklan Banner
  String get adUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        // ID Test Resmi dari Google untuk pengujian iklan Banner Android
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        // GANTI dengan Ad Unit ID asli Anda dari dasbor AdMob khusus halaman detail dokumen saat rilis nanti
        return 'ca-app-pub-5320800343545863/5518848739';
      }
    }
    return ''; // Kosongkan jika berjalan di Desktop / platform non-Android agar tidak crash
  }

  @override
  void initState() {
    super.initState();
    _documentsController = DocumentsController();
    groupDirectory = Directory(
      '${widget.baseDir}/my_documents/${widget.group.id}',
    );
    _loadPhysicalFiles();

    // Panggil fungsi pemuatan iklan banner
    _loadBannerAd();
  }

  // Fungsi untuk mengunduh iklan banner AdMob
  void _loadBannerAd() {
    if (adUnitId.isEmpty) return; // Batalkan jika bukan platform Android

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Iklan Banner Document Detail gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd
        ?.dispose(); // Hancurkan objek iklan dari memori saat halaman ditutup untuk mencegah kebocoran memori
    super.dispose();
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

  // =========================================================================
  // HELPER FUNCTION 1: SEBELAH KIRI - CONTAINER CIRCLE + ICON SESUAI EKSTENSI
  // =========================================================================
  Widget _getFileIconWidget(String filePath) {
    final String fileName = filePath.split('/').last.toLowerCase();
    final String extension = fileName.contains('.')
        ? fileName.split('.').last
        : '';

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

      // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
      case 'ico':
        iconData = Icons.image_rounded;
        iconColor = Colors.purple.shade700;
        bgColor = Colors.purple.shade50;
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
      double num =
          bytes /
          (1024 *
              floorIndex *
              1024); // Menggunakan pembagian eksponensial sederhana
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
          if (pickedFile.path != null) {
            File sourceFile = File(pickedFile.path!);

            // 1. Ambil waktu modifikasi asli dari file asal sebelum disalin
            DateTime originalLastModified = await sourceFile.lastModified();

            String fileName = pickedFile.name;
            String targetPath = '${groupDirectory.path}/$fileName';
            File targetFile = File(targetPath);

            // LOGIKA KONFIRMASI JIKA FILE SUDAH ADA
            if (await targetFile.exists()) {
              // Sembunyikan loading sejenak agar dialog terlihat jelas
              setState(() => isLoading = false);

              String? choice = await _showDuplicateConflictDialog(fileName);

              setState(() => isLoading = true);

              if (choice == 'cancel' || choice == null) {
                continue; // Lewati file ini, lanjut ke file berikutnya jika ada
              }

              if (choice == 'copy') {
                // Pemisahan Nama dan Ekstensi File untuk membuat format (1), (2), dst.
                final int lastDotIndex = fileName.lastIndexOf('.');
                final String nameWithoutExt = lastDotIndex != -1
                    ? fileName.substring(0, lastDotIndex)
                    : fileName;
                final String extension = lastDotIndex != -1
                    ? fileName.substring(lastDotIndex)
                    : '';

                int counter = 1;
                while (await targetFile.exists()) {
                  targetPath =
                      '${groupDirectory.path}/$nameWithoutExt ($counter)$extension';
                  targetFile = File(targetPath);
                  counter++;
                }
              }
              // Jika memilih 'overwrite', targetPath tetap sama dan langsung ditimpah
            }

            // 2. Salin file ke direktori aplikasi (baik menimpah atau membuat salinan baru)
            await sourceFile.copy(targetPath);

            // 3. Setel ulang waktu modifikasi file baru agar sama dengan yang asli
            await targetFile.setLastModified(originalLastModified);
            successCount++;
          }
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
              // IMPLEMENTASI FOOTER AD BANNER PADA KONDISI DATA KOSONG
              bottomNavigationBar:
                  _isAdLoaded && _bannerAd != null && Platform.isAndroid
                  ? SafeArea(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    )
                  : const SizedBox.shrink(),
            )
          : BaseDetailListScreen<File>(
              pageTitle: pageTitleWithIcon,
              items: physicalFiles,
              enableSearch: true,
              enableMultiSelect: true,
              enableAddButton: true,
              enableFavoriteSort: false,
              itemTitle: (file) => file.path.split('/').last,

              // =========================================================================
              // MODIFIKASI 1: PASANG LOGIKA SEBELAH KIRI (MENGGANTI IKON BAWAAN)
              // =========================================================================
              itemIconBuilder: (file) => _getFileIconWidget(file.path),

              // =========================================================================
              // MODIFIKASI 2: SUBTITLE DIBAWAH NAMA FILE DIUBAH MENJADI UKURAN & TANGGAL
              // =========================================================================
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
      // IMPLEMENTASI LAYOUT FOOTER BANNER ADMOB KHUSUS ANDROID
      bottomNavigationBar:
          _isAdLoaded && _bannerAd != null && Platform.isAndroid
          ? SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
