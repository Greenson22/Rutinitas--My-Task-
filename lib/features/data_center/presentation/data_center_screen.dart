import 'dart:convert'; // DITAMBAHKAN untuk memproses serialisasi JSON string
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import 'package:rutinitasku/features/data_center/presentation/backup/backup_tab.dart';
import 'package:rutinitasku/features/data_center/presentation/local_sharing/local_sharing_tab.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/presentation/widgets/drawer_menu.dart';
import 'widgets/last_restore_banner.dart'; // Impor widget banner
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
        // GANTI dengan Ad Unit ID asli Anda dari dasbor AdMob saat rilis nanti
        return 'ca-app-pub-5320800343545863/8571499437';
      }
    }
    return ''; // Kosongkan jika berjalan di Desktop (Windows/Linux/macOS) agar tidak crash
  }

  @override
  void initState() {
    super.initState();
    _loadBaseDirectory();
    _loadLastRestoreInfo(); // DITAMBAHKAN: Ambil data restore terakhir dari lokal disk saat inisialisasi awal

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
          debugPrint('Iklan Banner Data Center gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd
        ?.dispose(); // Hancurkan objek iklan dari memori untuk mencegah kebocoran memori
    super.dispose();
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

  // DITAMBAHKAN: Mengambil data status restore persisten dari StorageService
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
  // LOGIKA OVERWRITE TOTAL SELURUH ISI ZIP (Dibutuhkan oleh kedua Tab)
  // =========================================================================
  void _importAllFromZip(File zipFile) async {
    try {
      List<int> bytes = await zipFile.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      // 1. Bersihkan dan inisialisasi folder Checklist
      String folderChecklist = await _storageService.getChecklistDirPath(
        _baseDir,
      );
      Directory checklistDir = Directory(folderChecklist);
      if (checklistDir.existsSync()) {
        checklistDir.deleteSync(recursive: true);
      }
      checklistDir.createSync(recursive: true);

      // 2. Bersihkan dan inisialisasi folder Notes
      Directory notesDir = await _storageService.getNotesDir(_baseDir);
      if (notesDir.existsSync()) {
        notesDir.deleteSync(recursive: true);
      }
      notesDir.createSync(recursive: true);

      // 3. Bersihkan dan inisialisasi folder Prompts
      Directory promptsDir = await _storageService.getPromptDir(_baseDir);
      if (promptsDir.existsSync()) {
        promptsDir.deleteSync(recursive: true);
      }
      promptsDir.createSync(recursive: true);

      // 4. BARU: Bersihkan folder my_documents lama jika ada di dalam berkas cadangan ZIP
      // Logika pembersihan diletakkan di sini agar folder dokumen hanya dihapus jika ZIP tersebut memang memiliki data dokumen
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

      // Loop ekstraksi berkas arsip
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
          } else if (file.name.startsWith('my_documents/')) {
            // BARU: Penanganan restore file fisik dokumen asli beserta subfolder strukturnya (id grup)
            File targetFile = File('$_baseDir/${file.name}');

            // Pastikan subfolder penampung (grup id) dibuat terlebih dahulu jika belum ada
            if (!targetFile.parent.existsSync()) {
              targetFile.parent.createSync(recursive: true);
            }
            await targetFile.writeAsBytes(file.content);
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

      // MODIFIKASI: Mengamankan status banner ke memori permanen lokal HP/Device
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
      ),
    );
  }
}
