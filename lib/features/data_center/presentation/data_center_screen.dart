import 'dart:convert'; // DITAMBAHKAN untuk memproses serialisasi JSON string[cite: 20]
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import 'package:rutinitasku/features/data_center/presentation/backup/backup_tab.dart'; //[cite: 20]
import 'package:rutinitasku/features/data_center/presentation/local_sharing/local_sharing_tab.dart'; //[cite: 20]
import '../../../core/services/storage_service.dart'; //[cite: 20]
import '../../../core/presentation/widgets/drawer_menu.dart'; //[cite: 20]
import 'widgets/last_restore_banner.dart'; // Impor widget banner[cite: 20]
import 'package:file_picker/file_picker.dart'; //[cite: 20]
import 'package:archive/archive_io.dart'; //[cite: 20]

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  final StorageService _storageService = StorageService(); //[cite: 20]
  String _baseDir = 'Documents'; //[cite: 20]
  bool _isLoading = false; //[cite: 20]

  // State untuk menyimpan informasi status restore terakhir[cite: 20]
  Map<String, String>? _lastRestoreInfo; //[cite: 20]

  // GlobalKey untuk memicu pembaruan daftar berkas lokal di dalam BackupTab[cite: 20]
  final GlobalKey<BackupTabState> _backupTabKey =
      GlobalKey<BackupTabState>(); //[cite: 20]

  // GlobalKey untuk memicu pembaruan daftar berkas server di dalam LocalSharingTab[cite: 20]
  final GlobalKey<LocalSharingTabState> _sharingTabKey =
      GlobalKey<LocalSharingTabState>(); //[cite: 20]

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
    super.initState(); //[cite: 20]
    _loadBaseDirectory(); //[cite: 20]
    _loadLastRestoreInfo(); // DITAMBAHKAN: Ambil data restore terakhir dari lokal disk saat inisialisasi awal[cite: 20]

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
    String dir = await _storageService.getBaseDirSetting(); //[cite: 20]
    if (mounted) {
      //[cite: 20]
      setState(() {
        //[cite: 20]
        _baseDir = dir; //[cite: 20]
      }); //[cite: 20]
      // Memperbarui tab sharing melalui GlobalKey jika sudah terpasang[cite: 20]
      _sharingTabKey.currentState?.refreshServerBackups(); //[cite: 20]
    } //[cite: 20]
  }

  // DITAMBAHKAN: Mengambil data status restore persisten dari StorageService[cite: 20]
  void _loadLastRestoreInfo() async {
    try {
      //[cite: 20]
      String? savedInfo = await _storageService
          .getLastRestoreInfo(); //[cite: 20]
      if (savedInfo != null && savedInfo.isNotEmpty) {
        //[cite: 20]
        Map<String, dynamic> decoded = jsonDecode(savedInfo); //[cite: 20]
        if (mounted) {
          //[cite: 20]
          setState(() {
            //[cite: 20]
            _lastRestoreInfo = decoded.map(
              //[cite: 20]
              (key, value) => MapEntry(key, value.toString()), //[cite: 20]
            ); //[cite: 20]
          }); //[cite: 20]
        } //[cite: 20]
      } //[cite: 20]
    } catch (e) {
      //[cite: 20]
      debugPrint(
        "Gagal memuat status riwayat restore terakhir: $e",
      ); //[cite: 20]
    } //[cite: 20]
  }

  // =========================================================================
  // LOGIKA OVERWRITE TOTAL SELURUH ISI ZIP (Dibutuhkan oleh kedua Tab)
  // =========================================================================
  void _importAllFromZip(File zipFile) async {
    try {
      //[cite: 20]
      List<int> bytes = await zipFile.readAsBytes(); //[cite: 20]
      Archive archive = ZipDecoder().decodeBytes(bytes); //[cite: 20]

      String folderChecklist = await _storageService.getChecklistDirPath(
        //[cite: 20]
        _baseDir, //[cite: 20]
      ); //[cite: 20]
      Directory checklistDir = Directory(folderChecklist); //[cite: 20]
      if (checklistDir.existsSync())
        checklistDir.deleteSync(recursive: true); //[cite: 20]
      checklistDir.createSync(recursive: true); //[cite: 20]

      Directory notesDir = await _storageService.getNotesDir(
        _baseDir,
      ); //[cite: 20]
      if (notesDir.existsSync())
        notesDir.deleteSync(recursive: true); //[cite: 20]
      notesDir.createSync(recursive: true); //[cite: 20]

      Directory promptsDir = await _storageService.getPromptDir(
        _baseDir,
      ); //[cite: 20]
      if (promptsDir.existsSync())
        promptsDir.deleteSync(recursive: true); //[cite: 20]
      promptsDir.createSync(recursive: true); //[cite: 20]

      for (ArchiveFile file in archive) {
        //[cite: 20]
        if (file.isFile) {
          //[cite: 20]
          if (file.name == 'my_tasks.json') {
            //[cite: 20]
            File target = await _storageService.getTargetJsonFile(
              _baseDir,
            ); //[cite: 20]
            await target.writeAsBytes(file.content); //[cite: 20]
          } else if (file.name == 'time_log.json') {
            //[cite: 20]
            File target = await _storageService.getJurnalJsonFile(
              _baseDir,
            ); //[cite: 20]
            await target.writeAsBytes(file.content); //[cite: 20]
          } else if (file.name.startsWith('my_checklist/')) {
            //[cite: 20]
            String namaFileHub = file.name.split('/').last; //[cite: 20]
            if (namaFileHub.isNotEmpty) {
              //[cite: 20]
              await File(
                //[cite: 20]
                '$folderChecklist/$namaFileHub', //[cite: 20]
              ).writeAsBytes(file.content); //[cite: 20]
            } //[cite: 20]
          } else if (file.name.startsWith('notes/')) {
            //[cite: 20]
            String namaFileNote = file.name.split('/').last; //[cite: 20]
            if (namaFileNote.isNotEmpty) {
              //[cite: 20]
              await File(
                //[cite: 20]
                '${notesDir.path}/$namaFileNote', //[cite: 20]
              ).writeAsBytes(file.content); //[cite: 20]
            } //[cite: 20]
          } else if (file.name.startsWith('prompts/')) {
            //[cite: 20]
            String namaFilePrompt = file.name.split('/').last; //[cite: 20]
            if (namaFilePrompt.isNotEmpty) {
              //[cite: 20]
              await File(
                //[cite: 20]
                '${promptsDir.path}/$namaFilePrompt', //[cite: 20]
              ).writeAsBytes(file.content); //[cite: 20]
            } //[cite: 20]
          } //[cite: 20]
        } //[cite: 20]
      } //[cite: 20]

      _loadBaseDirectory(); //[cite: 20]
      // Picu pembaruan daftar file cadangan lokal setelah sistem berhasil melakukan data restore total[cite: 20]
      _backupTabKey.currentState?.refreshLocalBackups(); //[cite: 20]

      // Format informasi nama file, waktu, dan penentuan sumber data untuk LastRestoreBanner[cite: 20]
      final String fileName = zipFile.path.split('/').last; //[cite: 20]
      final now = DateTime.now(); //[cite: 20]
      final String timeString = //[cite: 20]
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}"; //[cite: 20]

      final infoData = {
        //[cite: 20]
        'source': //[cite: 20]
            fileName.startsWith('server_backup') || //[cite: 20]
                fileName.startsWith('client_backup') //[cite: 20]
            ? 'Server Sharing' //[cite: 20]
            : 'Penyimpanan Lokal', //[cite: 20]
        'time': timeString, //[cite: 20]
        'file': fileName, //[cite: 20]
      }; //[cite: 20]

      setState(() {
        //[cite: 20]
        _lastRestoreInfo = infoData; //[cite: 20]
      }); //[cite: 20]

      // MODIFIKASI: Mengamankan status banner ke memori permanen lokal HP/Device[cite: 20]
      await _storageService.saveLastRestoreInfo(
        jsonEncode(infoData),
      ); //[cite: 20]

      if (!mounted) return; //[cite: 20]
      ScaffoldMessenger.of(context).showSnackBar(
        //[cite: 20]
        SnackBar(
          //[cite: 20]
          content: Text(
            //[cite: 20]
            'Restore Berhasil! Seluruh data disinkronkan dari "$fileName".', //[cite: 20]
          ), //[cite: 20]
          backgroundColor: Colors.teal, //[cite: 20]
        ), //[cite: 20]
      ); //[cite: 20]
    } catch (e) {
      //[cite: 20]
      debugPrint("Gagal mengimpor file ZIP global: $e"); //[cite: 20]
    } //[cite: 20]
  }

  void _importZipLokal() async {
    try {
      //[cite: 20]
      FilePickerResult? result = await FilePicker.pickFiles(
        //[cite: 20]
        type: FileType.custom, //[cite: 20]
        allowedExtensions: ['zip'], //[cite: 20]
      ); //[cite: 20]
      if (result != null && result.files.single.path != null) {
        //[cite: 20]
        File selectedZipFile = File(result.files.single.path!); //[cite: 20]

        if (!mounted) return; //[cite: 20]
        final bool confirm = //[cite: 20]
            await showDialog<bool>(
              //[cite: 20]
              context: context, //[cite: 20]
              builder: (ctx) => AlertDialog(
                //[cite: 20]
                shape: RoundedRectangleBorder(
                  //[cite: 20]
                  borderRadius: BorderRadius.circular(16), //[cite: 20]
                ), //[cite: 20]
                title: Row(
                  //[cite: 20]
                  children: const [
                    //[cite: 20]
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                    ), //[cite: 20]
                    SizedBox(width: 8), //[cite: 20]
                    Text('Import & Restore ZIP?'), //[cite: 20]
                  ], //[cite: 20]
                ), //[cite: 20]
                content: Text(
                  //[cite: 20]
                  'Apakah Anda yakin ingin memulihkan data dari berkas luar "${selectedZipFile.path.split('/').last}"?\n\n*Peringatan: Seluruh data aktif aplikasi saat ini akan dihapus dan ditimpa.', //[cite: 20]
                ), //[cite: 20]
                actions: [
                  //[cite: 20]
                  TextButton(
                    //[cite: 20]
                    onPressed: () => Navigator.pop(ctx, false), //[cite: 20]
                    child: const Text(
                      //[cite: 20]
                      'Batal', //[cite: 20]
                      style: TextStyle(color: Colors.grey), //[cite: 20]
                    ), //[cite: 20]
                  ), //[cite: 20]
                  ElevatedButton(
                    //[cite: 20]
                    onPressed: () => Navigator.pop(ctx, true), //[cite: 20]
                    style: ElevatedButton.styleFrom(
                      //[cite: 20]
                      backgroundColor: Colors.indigo, //[cite: 20]
                    ), //[cite: 20]
                    child: const Text(
                      //[cite: 20]
                      'Ya, Restore', //[cite: 20]
                      style: TextStyle(color: Colors.white), //[cite: 20]
                    ), //[cite: 20]
                  ), //[cite: 20]
                ], //[cite: 20]
              ), //[cite: 20]
            ) ?? //[cite: 20]
            false; //[cite: 20]

        if (confirm) {
          //[cite: 20]
          _importAllFromZip(selectedZipFile); //[cite: 20]
        } //[cite: 20]
      } //[cite: 20]
    } catch (e) {
      //[cite: 20]
      debugPrint("Gagal mengimport file cadangan ZIP: $e"); //[cite: 20]
    } //[cite: 20]
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      //[cite: 20]
      length: 2, //[cite: 20]
      child: Scaffold(
        //[cite: 20]
        appBar: AppBar(
          //[cite: 20]
          title: const Text('Data Center'), //[cite: 20]
          backgroundColor: Colors.indigo[700], //[cite: 20]
          bottom: const TabBar(
            //[cite: 20]
            indicatorColor: Colors.amberAccent, //[cite: 20]
            indicatorWeight: 3, //[cite: 20]
            labelStyle: TextStyle(fontWeight: FontWeight.bold), //[cite: 20]
            tabs: [
              //[cite: 20]
              Tab(
                icon: Icon(Icons.backup_outlined),
                text: 'Backup',
              ), //[cite: 20]
              Tab(
                icon: Icon(Icons.wifi_find_outlined),
                text: 'Local Sharing',
              ), //[cite: 20]
            ], //[cite: 20]
          ), //[cite: 20]
        ), //[cite: 20]
        drawer: const DrawerMenu(isDataCenterActive: true), //[cite: 20]
        body: Stack(
          //[cite: 20]
          children: [
            //[cite: 20]
            TabBarView(
              //[cite: 20]
              children: [
                //[cite: 20]
                // TAB 1: Backup[cite: 20]
                BackupTab(
                  //[cite: 20]
                  key: _backupTabKey, //[cite: 20]
                  lastRestoreInfo: //[cite: 20]
                      _lastRestoreInfo, // Meneruskan state info restore[cite: 20]
                  onRestoreAllZip: (file) =>
                      _importAllFromZip(file), //[cite: 20]
                  onImportZip: () => _importZipLokal(), //[cite: 20]
                ), //[cite: 20]
                // TAB 2: Local Sharing[cite: 20]
                LocalSharingTab(
                  //[cite: 20]
                  key: _sharingTabKey, //[cite: 20]
                  lastRestoreInfo: //[cite: 20]
                      _lastRestoreInfo, // Meneruskan state info restore[cite: 20]
                  onRestoreAllZip: (file) =>
                      _importAllFromZip(file), //[cite: 20]
                  onLoadingStatusChanged: (statusLoading) {
                    //[cite: 20]
                    setState(() {
                      //[cite: 20]
                      _isLoading = statusLoading; //[cite: 20]
                    }); //[cite: 20]
                  }, //[cite: 20]
                  onDataSynchronized: () {
                    //[cite: 20]
                    // Ketika Client menerima data dari server, segarkan juga daftar berkas lokal pada Tab 1[cite: 20]
                    _backupTabKey.currentState
                        ?.refreshLocalBackups(); //[cite: 20]
                  }, //[cite: 20]
                ), //[cite: 20]
              ], //[cite: 20]
            ), //[cite: 20]
            if (_isLoading) //[cite: 20]
              Container(
                //[cite: 20]
                color: Colors.black.withOpacity(0.4), //[cite: 20]
                child: const Center(
                  //[cite: 20]
                  child: Card(
                    //[cite: 20]
                    elevation: 4, //[cite: 20]
                    shape: CircleBorder(), //[cite: 20]
                    child: Padding(
                      //[cite: 20]
                      padding: EdgeInsets.all(16.0), //[cite: 20]
                      child: CircularProgressIndicator(
                        //[cite: 20]
                        valueColor: AlwaysStoppedAnimation<Color>(
                          //[cite: 20]
                          Colors.indigo, //[cite: 20]
                        ), //[cite: 20]
                      ), //[cite: 20]
                    ), //[cite: 20]
                  ), //[cite: 20]
                ), //[cite: 20]
              ), //[cite: 20]
          ], //[cite: 20]
        ), //[cite: 20]
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
      ), //[cite: 20]
    );
  }
}
