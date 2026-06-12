import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/features/data_center/backup/backup_tab.dart';
import 'package:rutinitasku/features/data_center/local_sharing/local_sharing_tab.dart';
import '../../core/services/storage_service.dart';
import '../../core/presentation/widgets/drawer_menu.dart';
import 'presentation/widgets/last_restore_banner.dart'; // Impor widget banner
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

  // State untuk menyimpan informasi status restore terakhir
  Map<String, String>? _lastRestoreInfo;

  // GlobalKey untuk memicu pembaruan daftar berkas lokal di dalam BackupTab
  final GlobalKey<BackupTabState> _backupTabKey = GlobalKey<BackupTabState>();

  // GlobalKey untuk memicu pembaruan daftar berkas server di dalam LocalSharingTab
  final GlobalKey<LocalSharingTabState> _sharingTabKey =
      GlobalKey<LocalSharingTabState>();

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  void _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      // Memperbarui tab sharing melalui GlobalKey jika sudah terpasang
      _sharingTabKey.currentState?.refreshServerBackups();
    }
  }

  // =========================================================================
  // LOGIKA OVERWRITE TOTAL SELURUH ISI ZIP (Dibutuhkan oleh kedua Tab)
  // =========================================================================
  void _importAllFromZip(File zipFile) async {
    try {
      List<int> bytes = await zipFile.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      String folderChecklist = await _storageService.getChecklistDirPath(
        _baseDir,
      );
      Directory checklistDir = Directory(folderChecklist);
      if (checklistDir.existsSync()) checklistDir.deleteSync(recursive: true);
      checklistDir.createSync(recursive: true);

      Directory notesDir = await _storageService.getNotesDir(_baseDir);
      if (notesDir.existsSync()) notesDir.deleteSync(recursive: true);
      notesDir.createSync(recursive: true);

      Directory promptsDir = await _storageService.getPromptDir(_baseDir);
      if (promptsDir.existsSync()) promptsDir.deleteSync(recursive: true);
      promptsDir.createSync(recursive: true);

      for (ArchiveFile file in archive) {
        if (file.isFile) {
          if (file.name == 'my_tasks.json') {
            File target = await _storageService.getTargetJsonFile(_baseDir);
            await target.writeAsBytes(file.content);
          } else if (file.name == 'time_log.json') {
            File target = await _storageService.getJurnalJsonFile(_baseDir);
            await target.writeAsBytes(file.content);
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
          }
        }
      }

      _loadBaseDirectory();
      // Picu pembaruan daftar file cadangan lokal setelah sistem berhasil melakukan data restore total
      _backupTabKey.currentState?.refreshLocalBackups();

      // Format informasi nama file, waktu, dan penentuan sumber data untuk LastRestoreBanner
      final String fileName = zipFile.path.split('/').last;
      final now = DateTime.now();
      final String timeString =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      setState(() {
        _lastRestoreInfo = {
          'source':
              fileName.startsWith('server_backup') ||
                  fileName.startsWith('client_backup')
              ? 'Server Sharing'
              : 'Penyimpanan Lokal',
          'time': timeString,
          'file': fileName,
        };
      });

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
                  lastRestoreInfo:
                      _lastRestoreInfo, // Meneruskan state info restore
                  onRestoreAllZip: (file) => _importAllFromZip(file),
                  onImportZip: () => _importZipLokal(),
                ),

                // TAB 2: Local Sharing
                LocalSharingTab(
                  key: _sharingTabKey,
                  lastRestoreInfo:
                      _lastRestoreInfo, // Meneruskan state info restore
                  onRestoreAllZip: (file) => _importAllFromZip(file),
                  onLoadingStatusChanged: (statusLoading) {
                    setState(() {
                      _isLoading = statusLoading;
                    });
                  },
                  onDataSynchronized: () {
                    // Ketika Client menerima data dari server, segarkan juga daftar berkas lokal pada Tab 1
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
      ),
    );
  }
}
