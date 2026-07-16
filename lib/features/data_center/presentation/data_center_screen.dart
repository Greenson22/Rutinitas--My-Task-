// lib/features/data_center/presentation/screens/data_center_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/features/data_center/presentation/backup/backup_tab.dart';
import 'package:rutinitasku/features/data_center/presentation/local_sharing/local_sharing_tab.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE[cite: 2, 4]
import '../../../core/services/storage_service.dart';
import '../../../core/presentation/widgets/drawer_menu.dart';
import 'widgets/last_restore_banner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  final StorageService _storageService = StorageService();
  String _baseDir = 'Documents';
  bool _isLoading = false;

  Map<String, String>? _lastRestoreInfo;

  final GlobalKey<BackupTabState> _backupTabKey = GlobalKey<BackupTabState>();
  final GlobalKey<LocalSharingTabState> _sharingTabKey =
      GlobalKey<LocalSharingTabState>();

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
    _loadLastRestoreInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      _sharingTabKey.currentState?.refreshServerBackups();
    }
  }

  void _loadLastRestoreInfo() async {
    try {
      String? savedInfo = await _storageService.getLastRestoreInfo();
      if (savedInfo != null && savedInfo.isNotEmpty) {
        Map<String, dynamic> decoded = jsonDecode(savedInfo);
        if (mounted) {
          setState(() {
            _lastRestoreInfo = decoded.map(
              (key, value) => MapEntry(key, value.toString()),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat status riwayat restore terakhir: $e");
    }
  }

  // =========================================================================
  // LOGIKA RESET PABRIK (WIPE SEMUA DATA)
  // =========================================================================
  void _showResetDataDialog() {
    final TextEditingController confirmController = TextEditingController();
    const String confirmationText = "HAPUS SEMUA DATA";
    bool isMatch = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Text('Reset Sistem', style: TextStyle(color: Colors.red)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peringatan Kritis! Tindakan ini akan menghapus seluruh data (Task, Jurnal, Checklist, Catatan, Prompt, Dokumen) secara permanen tanpa kecuali.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Untuk melanjutkan, ketik persis kalimat berikut:',
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const SelectableText(
                      confirmationText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2.0,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ketik di sini...',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        isMatch = val == confirmationText;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isMatch
                      ? () async {
                          Navigator.pop(ctx);
                          await _performFactoryReset();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade200,
                  ),
                  child: const Text(
                    'Ya, Hapus Bersih',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performFactoryReset() async {
    setState(() => _isLoading = true);
    try {
      await _storageService.wipeAllData();

      // Refresh state di tab
      _backupTabKey.currentState?.refreshLocalBackups();
      _sharingTabKey.currentState?.refreshServerBackups();

      setState(() {
        _lastRestoreInfo = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sistem berhasil di-reset. Seluruh data telah dibersihkan.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  // LOGIKA OVERWRITE TOTAL SELURUH ISI ZIP (Dibutuhkan oleh kedua Tab)
  // =========================================================================
  void _importAllFromZip(File zipFile) async {
    try {
      List<int> bytes = await zipFile.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      // Bersihkan dan inisialisasi folder Jurnal Aktivitas partisi multi-file kustom
      String folderJurnal = '$_baseDir/jurnal_aktivitas';
      Directory jurnalDir = Directory(folderJurnal);
      if (jurnalDir.existsSync()) {
        jurnalDir.deleteSync(recursive: true);
      }
      jurnalDir.createSync(recursive: true);

      String folderChecklist = await _storageService.getChecklistDirPath(
        _baseDir,
      );
      Directory checklistDir = Directory(folderChecklist);
      if (checklistDir.existsSync()) {
        checklistDir.deleteSync(recursive: true);
      }
      checklistDir.createSync(recursive: true);

      Directory notesDir = await _storageService.getNotesDir(_baseDir);
      if (notesDir.existsSync()) {
        notesDir.deleteSync(recursive: true);
      }
      notesDir.createSync(recursive: true);

      Directory promptsDir = await _storageService.getPromptDir(_baseDir);
      if (promptsDir.existsSync()) {
        promptsDir.deleteSync(recursive: true);
      }
      promptsDir.createSync(recursive: true);

      bool hasDocumentsInZip = archive.any(
        (file) => file.isFile && file.name.startsWith('my_documents/'),
      );
      if (hasDocumentsInZip) {
        Directory documentsDir = Directory('$_baseDir/my_documents');
        if (documentsDir.existsSync()) {
          documentsDir.deleteSync(recursive: true);
        }
        documentsDir.createSync(recursive: true);
      }

      for (ArchiveFile file in archive) {
        if (file.isFile) {
          if (file.name == 'my_tasks.json') {
            File target = await _storageService.getTargetJsonFile(_baseDir);
            await target.writeAsBytes(file.content);
          } else if (file.name.startsWith('jurnal_aktivitas/')) {
            // Mengekstraksi multi-file berkas partisi bulanan ke dalam subfolder jurnal_aktivitas/
            String namaFileJurnal = file.name.split('/').last;
            if (namaFileJurnal.isNotEmpty) {
              await File(
                '$folderJurnal/$namaFileJurnal',
              ).writeAsBytes(file.content);
            }
          } else if (file.name.startsWith('my_checklist/')) {
            String namaFileHub = file.name.split('/').last;
            if (namaFileHub.isNotEmpty) {
              await File(
                '$folderChecklist/$namaFileHub',
              ).writeAsBytes(file.content);
            }
          } else if (file.name.startsWith('notes/')) {
            String namaFileNote = file.name.split('/').last;
            if (namaFileNote.isNotEmpty) {
              await File(
                '${notesDir.path}/$namaFileNote',
              ).writeAsBytes(file.content);
            }
          } else if (file.name.startsWith('prompts/')) {
            String namaFilePrompt = file.name.split('/').last;
            if (namaFilePrompt.isNotEmpty) {
              await File(
                '${promptsDir.path}/$namaFilePrompt',
              ).writeAsBytes(file.content);
            }
          } else if (file.name.startsWith('my_documents/')) {
            File targetFile = File('$_baseDir/${file.name}');

            if (!targetFile.parent.existsSync()) {
              targetFile.parent.createSync(recursive: true);
            }
            await targetFile.writeAsBytes(file.content);
          }
        }
      }

      _loadBaseDirectory();
      _backupTabKey.currentState?.refreshLocalBackups();

      final String fileName = zipFile.path.split('/').last;
      final now = DateTime.now();
      final String timeString =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final infoData = {
        'source':
            fileName.startsWith('server_backup') ||
                fileName.startsWith('client_backup')
            ? 'Server Sharing'
            : 'Penyimpanan Lokal',
        'time': timeString,
        'file': fileName,
      };

      setState(() {
        _lastRestoreInfo = infoData;
      });

      await _storageService.saveLastRestoreInfo(jsonEncode(infoData));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore Berhasil! Seluruh data disinkronkan dari "$fileName".',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal mengimpor file ZIP global: $e");
    }
  }

  void _importZipLokal() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null && result.files.single.path != null) {
        File selectedZipFile = File(result.files.single.path!);

        if (!mounted) return;
        final bool confirm =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Import & Restore ZIP?'),
                  ],
                ),
                content: Text(
                  'Apakah Anda yakin ingin memulihkan data dari berkas luar "${selectedZipFile.path.split('/').last}"?\n\n*Peringatan: Seluruh data aktif aplikasi saat ini akan dihapus dan ditimpa.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text(
                      'Ya, Restore',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirm) {
          _importAllFromZip(selectedZipFile);
        }
      }
    } catch (e) {
      debugPrint("Gagal mengimport file cadangan ZIP: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Center'),
          backgroundColor: Colors.indigo[700],
          actions: [
            // TOMBOL RESET DATA DITAMBAHKAN DI SINI
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: 'Reset Semua Data',
              onPressed: _showResetDataDialog,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.backup_outlined), text: 'Backup'),
              Tab(icon: Icon(Icons.wifi_find_outlined), text: 'Local Sharing'),
            ],
          ),
        ),
        drawer: const DrawerMenu(isDataCenterActive: true),
        body: Stack(
          children: [
            TabBarView(
              children: [
                // TAB 1: Backup
                BackupTab(
                  key: _backupTabKey,
                  lastRestoreInfo: _lastRestoreInfo,
                  onRestoreAllZip: (file) => _importAllFromZip(file),
                  onImportZip: () => _importZipLokal(),
                ),
                // TAB 2: Local Sharing
                LocalSharingTab(
                  key: _sharingTabKey,
                  lastRestoreInfo: _lastRestoreInfo,
                  onRestoreAllZip: (file) => _importAllFromZip(file),
                  onLoadingStatusChanged: (statusLoading) {
                    setState(() {
                      _isLoading = statusLoading;
                    });
                  },
                  onDataSynchronized: () {
                    _backupTabKey.currentState?.refreshLocalBackups();
                  },
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Card(
                    elevation: 4,
                    shape: CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // MENGGUNAKAN WIDGET KUSTOM ADMOB YANG BARU DAN MODULAR PADA FOOTER LAYOUT[cite: 2]
        bottomNavigationBar: const AdaptiveBannerAd(
          adKey: 'jurnal_activity_banner',
        ),
      ),
    );
  }
}
