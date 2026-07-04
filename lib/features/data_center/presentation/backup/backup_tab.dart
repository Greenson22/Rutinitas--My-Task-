import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/last_restore_banner.dart'; // Sertakan impor banner

class BackupTab extends StatefulWidget {
  final Map<String, String>? lastRestoreInfo; // Konstruktor tambahan
  final Function(File) onRestoreAllZip;
  final VoidCallback onImportZip;

  const BackupTab({
    super.key,
    this.lastRestoreInfo,
    required this.onRestoreAllZip,
    required this.onImportZip,
  });

  @override
  State<BackupTab> createState() => BackupTabState();
}

class BackupTabState extends State<BackupTab> {
  final StorageService _storageService = StorageService();
  String _baseDir = 'Documents';
  List<File> _localBackupFiles = [];
  bool _isSelectionMode = false;
  final List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
  }

  Future<void> _loadBaseDirectory() async {
    String dir = await _storageService.getBaseDirSetting();
    if (mounted) {
      setState(() {
        _baseDir = dir;
      });
      _loadLocalBackups();
    }
  }

  Future<void> _loadLocalBackups() async {
    List<File> files = await _storageService.getAllLocalBackupFiles(_baseDir);
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _localBackupFiles = files;
    });
  }

  void refreshLocalBackups() {
    _loadLocalBackups();
  }

  String _getFormattedFileName(String prefix, String extension) {
    final now = DateTime.now();
    const daftarHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    String namaHari = daftarHari[now.weekday - 1];
    String tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String waktu =
        "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
    return "${prefix}_${tanggal}_${namaHari}_$waktu.$extension";
  }

  // =========================================================================
  // HELPER FUNCTION: DIALOG PROGRESS BACKUP REAL-TIME (MENCEGAH UI FREEZE)
  // =========================================================================
  void _showBackupProgressDialog({
    required BuildContext context,
    required String title,
    required ValueNotifier<String> statusNotifier,
    required Function(BuildContext) onReady,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady(dialogCtx));
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.teal,
                          ),
                          backgroundColor: Colors.teal.withOpacity(0.1),
                        ),
                      ),
                      const Icon(
                        Icons.backup_outlined,
                        size: 40,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, child) {
                    return Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'PROSES MEMBUAT CADANGAN...',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.teal,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _backupAllFeature() async {
    try {
      // Tampilkan dialog konfirmasi pilihan kustom
      final bool? includeDocuments = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.backup_outlined, color: Colors.teal),
                SizedBox(width: 8),
                Text('Buat Cadangan Baru'),
              ],
            ),
            content: const Text(
              'Apakah Anda ingin menyertakan seluruh berkas fisik dari folder "My Documents" (PDF, Gambar, dll.) ke dalam file cadangan?\n\n*Catatan: Menyertakan dokumen dapat membuat ukuran file cadangan menjadi lebih besar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null), // Menekan luar/batal
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, false), // Backup tanpa dokumen
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text(
                  'Tanpa Dokumen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, true), // Backup dengan dokumen
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text(
                  'Sertakan Dokumen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      // Jika user menekan tombol Batal atau menutup dialog tanpa memilih, hentikan proses
      if (includeDocuments == null) return;

      // INISIALISASI DIALOG PROGRESS REAL-TIME
      BuildContext? progressCtx;
      final statusNotifier = ValueNotifier<String>('Menginisialisasi modul...');

      if (mounted) {
        _showBackupProgressDialog(
          context: context,
          title: 'Membuat Cadangan Data',
          statusNotifier: statusNotifier,
          onReady: (ctx) => progressCtx = ctx,
        );
      }

      statusNotifier.value = 'Membaca berkas Task Master...';
      File fileTasks = await _storageService.getTargetJsonFile(_baseDir);
      String kontenTasks = await fileTasks.exists()
          ? await fileTasks.readAsString()
          : "{}";

      statusNotifier.value = 'Membaca data Jurnal...';
      File fileJurnal = await _storageService.getJurnalJsonFile(_baseDir);
      String kontenJurnal = await fileJurnal.exists()
          ? await fileJurnal.readAsString()
          : "[]";

      statusNotifier.value = 'Mengumpulkan data Checklist...';
      List<File> hubFiles = await _storageService.getAllChecklistGroups(
        _baseDir,
      );

      statusNotifier.value = 'Mengumpulkan catatan harian (Notes)...';
      List<File> noteFiles = await _storageService.getAllNoteGroups(_baseDir);

      statusNotifier.value = 'Mengumpulkan data Prompts AI...';
      List<File> promptFiles = await _storageService.getAllPromptGroups(
        _baseDir,
      );

      final Archive backupArchive = Archive();

      backupArchive.addFile(
        ArchiveFile(
          'my_tasks.json',
          utf8.encode(kontenTasks).length,
          utf8.encode(kontenTasks),
        ),
      );

      backupArchive.addFile(
        ArchiveFile(
          'time_log.json',
          utf8.encode(kontenJurnal).length,
          utf8.encode(kontenJurnal),
        ),
      );

      for (var file in hubFiles) {
        final String namaFile = file.path.split('/').last;
        final List<int> bytes = await file.readAsBytes();
        backupArchive.addFile(
          ArchiveFile('my_checklist/$namaFile', bytes.length, bytes),
        );
      }

      for (var file in noteFiles) {
        final String namaFile = file.path.split('/').last;
        final List<int> bytes = await file.readAsBytes();
        backupArchive.addFile(
          ArchiveFile('notes/$namaFile', bytes.length, bytes),
        );
      }

      for (var file in promptFiles) {
        final String namaFile = file.path.split('/').last;
        final List<int> bytes = await file.readAsBytes();
        backupArchive.addFile(
          ArchiveFile('prompts/$namaFile', bytes.length, bytes),
        );
      }

      // Logika tambahan untuk memasukkan Folder Dokumen secara terstruktur dengan progress real-time
      if (includeDocuments == true) {
        final Directory documentsDir = Directory('$_baseDir/my_documents');
        if (await documentsDir.exists()) {
          statusNotifier.value = 'Memindai seluruh isi subfolder dokumen...';
          final List<FileSystemEntity> entities = documentsDir.listSync(
            recursive: true,
          );

          final List<File> filesToProcess = entities.whereType<File>().toList();
          int totalFiles = filesToProcess.length;

          for (int i = 0; i < totalFiles; i++) {
            final File file = filesToProcess[i];
            final String namaFileReal = file.path.split('/').last;

            // Memperbarui UI progress setiap file yang diproses agar tidak disangka hang/crash
            statusNotifier.value =
                'Mengompresi dokumen [${i + 1}/$totalFiles]\n$namaFileReal';

            // Dapatkan relative path agar struktur folder di dalam ZIP terjaga
            String relativePath = file.path.substring(
              documentsDir.parent.path.length + 1,
            );
            // Standardisasi karakter pembatas folder agar kompatibel saat dibuka di OS manapun
            relativePath = relativePath.replaceAll('\\', '/');

            final List<int> fileBytes = await file.readAsBytes();
            backupArchive.addFile(
              ArchiveFile(relativePath, fileBytes.length, fileBytes),
            );
          }
        }
      }

      statusNotifier.value =
          'Mengonversi dan menyusun berkas arsip ZIP final...';
      // Jeda mikro agar UI sempat merender teks status penyusunan ZIP
      await Future.delayed(const Duration(milliseconds: 100));

      final List<int>? finalZipBytes = ZipEncoder().encode(backupArchive);
      if (finalZipBytes == null) {
        if (progressCtx != null && progressCtx!.mounted)
          Navigator.pop(progressCtx!);
        return;
      }

      // Berikan penanda nama arsip yang jelas berdasarkan pilihan pengguna
      String prefixName = includeDocuments
          ? 'local_backup_full'
          : 'local_backup_core';
      String namaZipDinamis = _getFormattedFileName(prefixName, 'zip');

      statusNotifier.value = 'Menulis berkas cadangan ke penyimpanan HP...';
      File fileZipTarget = await _storageService.getLocalBackupZipFile(
        _baseDir,
        namaZipDinamis,
      );
      await fileZipTarget.writeAsBytes(finalZipBytes);

      // Tutup progress dialog sesaat setelah file selesai ditulis
      if (progressCtx != null && progressCtx!.mounted) {
        Navigator.pop(progressCtx!);
      }

      _loadLocalBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup semua fitur berhasil disimpan: $namaZipDinamis',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      debugPrint("Gagal membuat backup lokal: $e");
    }
  }

  void _exportBackupToCustomFolder(File fileBackup) async {
    try {
      final String namaFile = fileBackup.path.split('/').last;

      if (Platform.isLinux) {
        String? lokasiSimpan = await FilePicker.saveFile(
          dialogTitle: 'Simpan Berkas Cadangan',
          fileName: namaFile,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );

        if (lokasiSimpan != null) {
          await fileBackup.copy(lokasiSimpan);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berkas berhasil disimpan ke: $lokasiSimpan'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      } else {
        String? direktoriPilihan = await FilePicker.getDirectoryPath(
          dialogTitle: 'Pilih Folder Tujuan Penyimpanan',
        );

        if (direktoriPilihan != null) {
          final String pathTargetBaru = '$direktoriPilihan/$namaFile';
          await fileBackup.copy(pathTargetBaru);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berkas sukses disalin ke folder kustom!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Gagal mengekspor berkas backup ke folder kustom: $e");
    }
  }

  void _exportTaskMaster() async {
    try {
      File fileAsli = await _storageService.getTargetJsonFile(_baseDir);
      if (await fileAsli.exists()) {
        if (Platform.isLinux) {
          String? lokasiSimpan = await FilePicker.saveFile(
            dialogTitle: 'Simpan Backup Task Master',
            fileName: _getFormattedFileName('my_tasks_backup', 'json'),
            type: FileType.custom,
            allowedExtensions: ['json'],
          );
          if (lokasiSimpan != null) {
            await fileAsli.copy(lokasiSimpan);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup Berhasil Disimpan di Linux!'),
              ),
            );
          }
        } else {
          String namaDinamis = _getFormattedFileName('my_tasks_backup', 'json');
          final tempFile = await fileAsli.copy(
            '${Directory.systemTemp.path}/$namaDinamis',
          );
          await Share.shareXFiles([
            XFile(tempFile.path),
          ], text: 'Backup Task Master Data');
        }
      }
    } catch (e) {
      debugPrint("Gagal export: $e");
    }
  }

  void _importTaskMaster() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        String fileContent = await File(
          result.files.single.path!,
        ).readAsString();
        File targetFile = await _storageService.getTargetJsonFile(_baseDir);
        await _storageService.saveJsonData(targetFile, fileContent);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data Task Master berhasil di-import!')),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Task Master: $e");
    }
  }

  void _exportJurnal() async {
    try {
      File fileAsli = await _storageService.getJurnalJsonFile(_baseDir);
      if (await fileAsli.exists()) {
        if (Platform.isLinux) {
          String? lokasiSimpan = await FilePicker.saveFile(
            dialogTitle: 'Simpan Backup Jurnal Aktivitas',
            fileName: _getFormattedFileName('time_log_backup', 'json'),
            type: FileType.custom,
            allowedExtensions: ['json'],
          );
          if (lokasiSimpan != null) {
            await fileAsli.copy(lokasiSimpan);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup Jurnal Berhasil Disimpan di Linux!'),
              ),
            );
          }
        } else {
          String namaDinamis = _getFormattedFileName('time_log_backup', 'json');
          final tempFile = await fileAsli.copy(
            '${Directory.systemTemp.path}/$namaDinamis',
          );
          await Share.shareXFiles([
            XFile(tempFile.path),
          ], text: 'Backup Jurnal Aktivitas Data');
        }
      }
    } catch (e) {
      debugPrint("Gagal export Jurnal: $e");
    }
  }

  void _importJurnal() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        String fileContent = await File(
          result.files.single.path!,
        ).readAsString();
        File targetFile = await _storageService.getJurnalJsonFile(_baseDir);
        await _storageService.saveJsonData(targetFile, fileContent);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Jurnal Aktivitas berhasil di-import!'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Jurnal: $e");
    }
  }

  void _exportChecklist() async {
    try {
      List<File> hubFiles = await _storageService.getAllChecklistGroups(
        _baseDir,
      );
      if (hubFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data checklist untuk di-backup.'),
          ),
        );
        return;
      }
      final Archive archive = Archive();
      for (var file in hubFiles) {
        archive.addFile(
          ArchiveFile(
            file.path.split('/').last,
            file.lengthSync(),
            await file.readAsBytes(),
          ),
        );
      }
      final List<int>? zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return;

      String namaZipDinamis = _getFormattedFileName('checklist_backup', 'zip');
      final File zipFile = File('${Directory.systemTemp.path}/$namaZipDinamis')
        ..writeAsBytesSync(zipBytes);

      if (Platform.isLinux) {
        String? lokasiSimpan = await FilePicker.saveFile(
          dialogTitle: 'Simpan Backup Checklist (ZIP)',
          fileName: namaZipDinamis,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (lokasiSimpan != null) await zipFile.copy(lokasiSimpan);
      } else {
        await Share.shareXFiles([
          XFile(zipFile.path),
        ], text: 'Backup Semua Hub Checklist Data (ZIP)');
      }
    } catch (e) {
      debugPrint("Gagal export ZIP Checklist: $e");
    }
  }

  void _importChecklist() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.isNotEmpty) {
        String targetFolder = await _storageService.getChecklistDirPath(
          _baseDir,
        );
        int hitungSukses = 0;
        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            String isiFile = await File(pickedFile.path!).readAsString();
            String namaFileBaru = pickedFile.name;
            File fileBaru = File('$targetFolder/$namaFileBaru');
            if (await fileBaru.exists()) {
              final String timestamp = DateTime.now().millisecondsSinceEpoch
                  .toString();
              namaFileBaru = namaFileBaru.replaceAll(
                '.json',
                '_$timestamp.json',
              );
              fileBaru = File('$targetFolder/$namaFileBaru');
            }
            await _storageService.saveJsonData(fileBaru, isiFile);
            hitungSukses++;
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengimport $hitungSukses file Hub Checklist!',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Checklist: $e");
    }
  }

  void _exportNotesIndividual() async {
    try {
      List<File> noteFiles = await _storageService.getAllNoteGroups(_baseDir);
      if (noteFiles.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tidak ada data Notes.')));
        return;
      }
      final Archive archive = Archive();
      for (var f in noteFiles) {
        archive.addFile(
          ArchiveFile(
            f.path.split('/').last,
            f.lengthSync(),
            await f.readAsBytes(),
          ),
        );
      }
      final List<int>? zip = ZipEncoder().encode(archive);
      if (zip == null) return;

      String name = _getFormattedFileName('notes_individual_backup', 'zip');
      File tmp = File('${Directory.systemTemp.path}/$name')
        ..writeAsBytesSync(zip);

      if (Platform.isLinux) {
        String? path = await FilePicker.saveFile(
          dialogTitle: 'Simpan Notes (ZIP)',
          fileName: name,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (path != null) await tmp.copy(path);
      } else {
        await Share.shareXFiles([XFile(tmp.path)], text: 'Backup Notes (ZIP)');
      }
    } catch (e) {
      debugPrint("Gagal ekspor Notes: $e");
    }
  }

  void _importNotesIndividual() async {
    try {
      FilePickerResult? res = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (res != null && res.files.isNotEmpty) {
        Directory dir = await _storageService.getNotesDir(_baseDir);
        for (var pf in res.files) {
          if (pf.path != null) {
            File(pf.path!).copySync('${dir.path}/${pf.name}');
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes berhasil di-import!')),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Notes: $e");
    }
  }

  void _exportPromptsIndividual() async {
    try {
      List<File> promptFiles = await _storageService.getAllPromptGroups(
        _baseDir,
      );
      if (promptFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data Prompts.')),
        );
        return;
      }
      final Archive archive = Archive();
      for (var f in promptFiles) {
        archive.addFile(
          ArchiveFile(
            f.path.split('/').last,
            f.lengthSync(),
            await f.readAsBytes(),
          ),
        );
      }
      final List<int>? zip = ZipEncoder().encode(archive);
      if (zip == null) return;

      String name = _getFormattedFileName('prompts_individual_backup', 'zip');
      File tmp = File('${Directory.systemTemp.path}/$name')
        ..writeAsBytesSync(zip);

      if (Platform.isLinux) {
        String? path = await FilePicker.saveFile(
          dialogTitle: 'Simpan Prompts (ZIP)',
          fileName: name,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (path != null) await tmp.copy(path);
      } else {
        await Share.shareXFiles([
          XFile(tmp.path),
        ], text: 'Backup Prompts (ZIP)');
      }
    } catch (e) {
      debugPrint("Gagal ekspor Prompts: $e");
    }
  }

  void _importPromptsIndividual() async {
    try {
      FilePickerResult? res = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (res != null && res.files.isNotEmpty) {
        Directory dir = await _storageService.getPromptDir(_baseDir);
        for (var pf in res.files) {
          if (pf.path != null) {
            File(pf.path!).copySync('${dir.path}/${pf.name}');
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompts berhasil di-import!')),
        );
      }
    } catch (e) {
      debugPrint("Gagal import Prompts: $e");
    }
  }

  void _exportDocumentsIndividual() async {
    try {
      final Directory documentsDir = Directory('$_baseDir/my_documents');

      if (!await documentsDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data Documents untuk diekspor.'),
          ),
        );
        return;
      }

      final List<FileSystemEntity> entities = documentsDir.listSync(
        recursive: true,
      );

      if (entities.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder Documents kosong.')),
        );
        return;
      }

      final Archive archive = Archive();

      for (var entity in entities) {
        if (entity is File) {
          String relativePath = entity.path.substring(
            documentsDir.parent.path.length + 1,
          );
          relativePath = relativePath.replaceAll('\\', '/');

          final List<int> fileBytes = await entity.readAsBytes();
          archive.addFile(
            ArchiveFile(relativePath, fileBytes.length, fileBytes),
          );
        }
      }

      final List<int>? zip = ZipEncoder().encode(archive);
      if (zip == null) return;

      String name = _getFormattedFileName('documents_individual_backup', 'zip');
      File tmp = File('${Directory.systemTemp.path}/$name')
        ..writeAsBytesSync(zip);

      if (Platform.isLinux) {
        String? path = await FilePicker.saveFile(
          dialogTitle: 'Simpan Documents (ZIP)',
          fileName: name,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        if (path != null) await tmp.copy(path);
      } else {
        await Share.shareXFiles([
          XFile(tmp.path),
        ], text: 'Backup Dokumen & Struktur Grup (ZIP)');
      }
    } catch (e) {
      debugPrint("Gagal ekspor individual Documents: $e");
    }
  }

  void _importDocumentsIndividual() async {
    try {
      FilePickerResult? res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (res != null && res.files.single.path != null) {
        File selectedZipFile = File(res.files.single.path!);
        List<int> bytes = await selectedZipFile.readAsBytes();
        Archive archive = ZipDecoder().decodeBytes(bytes);

        int hitungFile = 0;

        for (ArchiveFile file in archive) {
          if (file.isFile) {
            File targetFile = File('$_baseDir/${file.name}');

            if (!targetFile.parent.existsSync()) {
              targetFile.parent.createSync(recursive: true);
            }

            await targetFile.writeAsBytes(file.content);
            hitungFile++;
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengekstrak $hitungFile berkas ke folder my_documents!',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal import individual Documents: $e");
    }
  }

  Future<bool> _showConfirmDeleteDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
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
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        LastRestoreBanner(lastRestoreInfo: widget.lastRestoreInfo),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactButton(
                  'Task Master',
                  Icons.format_list_bulleted,
                  _exportTaskMaster,
                  _importTaskMaster,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Checklist',
                  Icons.checklist_rtl,
                  _exportChecklist,
                  _importChecklist,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Jurnal',
                  Icons.menu_book,
                  _exportJurnal,
                  _importJurnal,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Notes',
                  Icons.note_alt,
                  _exportNotesIndividual,
                  _importNotesIndividual,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Prompts',
                  Icons.smart_toy,
                  _exportPromptsIndividual,
                  _importPromptsIndividual,
                ),
                const SizedBox(width: 16),
                _buildCompactButton(
                  'Documents',
                  Icons.description,
                  _exportDocumentsIndividual,
                  _importDocumentsIndividual,
                ),
              ],
            ),
          ),
        ),
        const Divider(thickness: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Berkas Backup',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              FittedBox(
                child: Row(
                  children: [
                    if (_isSelectionMode) ...[
                      IconButton(
                        icon: Icon(
                          _selectedFiles.length == _localBackupFiles.length
                              ? Icons.deselect
                              : Icons.select_all,
                          size: 18,
                          color: Colors.teal[700],
                        ),
                        tooltip:
                            _selectedFiles.length == _localBackupFiles.length
                            ? 'Batal Semua'
                            : 'Pilih Semua',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        onPressed: () {
                          setState(() {
                            if (_selectedFiles.length ==
                                _localBackupFiles.length) {
                              _selectedFiles.clear();
                            } else {
                              _selectedFiles.clear();
                              _selectedFiles.addAll(_localBackupFiles);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedFiles.length} Terpilih',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _selectedFiles.isEmpty
                            ? null
                            : () async {
                                final bool
                                confirm = await _showConfirmDeleteDialog(
                                  title: 'Hapus Masal',
                                  content:
                                      'Apakah Anda yakin ingin menghapus ${_selectedFiles.length} berkas cadangan terpilih secara permanen?',
                                );
                                if (confirm) {
                                  for (var file in _selectedFiles) {
                                    if (await file.exists()) {
                                      await file.delete();
                                    }
                                  }
                                  setState(() {
                                    _selectedFiles.clear();
                                    _isSelectionMode = false;
                                  });
                                  _loadLocalBackups();
                                }
                              },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedFiles.isEmpty
                                ? Colors.grey[200]
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _selectedFiles.isEmpty
                                  ? Colors.grey[300]!
                                  : Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_sweep,
                            size: 18,
                            color: _selectedFiles.isEmpty
                                ? Colors.grey[400]
                                : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedFiles.clear();
                            _isSelectionMode = false;
                          });
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: widget.onImportZip,
                        icon: const Icon(Icons.unarchive, size: 14),
                        label: const Text(
                          'Import',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: _backupAllFeature,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Backup',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        _localBackupFiles.isEmpty
            ? const Center(child: Text('Belum ada file backup.'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localBackupFiles.length,
                itemBuilder: (context, index) {
                  final file = _localBackupFiles[index];
                  final isSelected = _selectedFiles.contains(file);
                  final String fileName = file.path.split('/').last;
                  return ListTile(
                    onLongPress: () {
                      setState(() {
                        _isSelectionMode = true;
                        if (!isSelected) _selectedFiles.add(file);
                      });
                    },
                    onTap: _isSelectionMode
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedFiles.remove(file);
                              } else {
                                _selectedFiles.add(file);
                              }
                            });
                          }
                        : () async {
                            final bool confirm =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange[800],
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Restore Data Aplikasi?'),
                                      ],
                                    ),
                                    content: Text(
                                      'Apakah Anda yakin ingin memulihkan seluruh data menggunakan file cadangan "$fileName"?\n\n*Peringatan: Data aktif Anda saat ini akan sepenuhnya ditimpa.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text(
                                          'Batal',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
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
                              widget.onRestoreAllZip(file);
                            }
                          },
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            activeColor: Colors.red,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedFiles.add(file);
                                } else {
                                  _selectedFiles.remove(file);
                                }
                              });
                            },
                          )
                        : const Icon(Icons.folder_zip, color: Colors.amber),
                    title: Text(fileName),
                    trailing: _isSelectionMode
                        ? null
                        : PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'export_folder') {
                                _exportBackupToCustomFolder(file);
                              } else if (value == 'share_backup') {
                                // BARU: Mengirim berkas cadangan ke luar aplikasi (WhatsApp, Telegram, dll)
                                await Share.shareXFiles([
                                  XFile(file.path),
                                ], text: 'Berkas Cadangan Aplikasi: $fileName');
                              } else if (value == 'delete_backup') {
                                final bool
                                confirm = await _showConfirmDeleteDialog(
                                  title: 'Hapus Berkas Backup',
                                  content:
                                      'Apakah Anda yakin ingin menghapus berkas cadangan "$fileName" secara permanen?',
                                );
                                if (confirm) {
                                  if (await file.exists()) await file.delete();
                                  _loadLocalBackups();
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'export_folder',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.drive_file_move,
                                    color: Colors.indigo,
                                    size: 20,
                                  ),
                                  title: Text('Simpan ke Folder Kustom'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'share_backup',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.share_outlined,
                                    color: Colors.teal,
                                    size: 20,
                                  ),
                                  title: Text('Bagikan Berkas'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'delete_backup',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  title: Text(
                                    'Hapus Permanen',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildCompactButton(
    String label,
    IconData icon,
    VoidCallback onUp,
    VoidCallback onDown,
  ) {
    return Column(
      children: [
        CircleAvatar(child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: onUp,
            ),
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.cloud_download_outlined,
                color: Colors.green,
                size: 20,
              ),
              onPressed: onDown,
            ),
          ],
        ),
      ],
    );
  }
}
