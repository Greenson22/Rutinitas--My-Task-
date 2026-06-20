// lib/features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../data/models/time_log_model.dart';
import '../controllers/jurnal_aktivitas_controller.dart';
import '../widgets/jurnal_statistik_dialog.dart'; // Import sub-widget baru
import '../widgets/jurnal_empty_state.dart';
import '../widgets/jurnal_corrupted_state.dart';
import '../widgets/jurnal_task_item_card.dart';

class JurnalAktivitasScreen extends StatefulWidget {
  const JurnalAktivitasScreen({super.key});

  @override
  State<JurnalAktivitasScreen> createState() => _JurnalAktivitasScreenState();
}

class _JurnalAktivitasScreenState extends State<JurnalAktivitasScreen> {
  final JurnalAktivitasController _controller = JurnalAktivitasController();

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
        return 'ca-app-pub-5320800343545863/3079499608';
      }
    }
    return ''; // Kosongkan jika berjalan di Desktop (Windows/Linux/macOS) agar tidak crash
  }

  @override
  void initState() {
    super.initState();

    // OPTIMASI: Membungkus pemicu pemuatan data ke dalam post frame callback dan
    // memberikan jeda Future mikro (150ms). Langkah ini memisahkan beban CPU
    // antara rendering animasi perpindahan halaman dengan proses komputasi dekripsi biner storage harian.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _triggerLoadData();
        }
      });
    });

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
          debugPrint('Iklan Banner Jurnal Aktivitas gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  void _triggerLoadData() {
    _controller.loadData(onNotify: () => setState(() {})).catchError((
      jsonFile,
    ) {
      if (jsonFile is File && mounted) {
        _showDecryptionErrorDialog(jsonFile);
      }
    });
  }

  @override
  void dispose() {
    _bannerAd
        ?.dispose(); // Hancurkan objek iklan dari memori saat halaman ditutup untuk mencegah kebocoran memori
    super.dispose();
  }

  // --- LOGIKA DIALOG INTERAKSI (PRODUKSI WIDGET POPUP) ---
  void _showDecryptionErrorDialog(File jsonFile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Jurnal Terkunci / Rusak'),
          ],
        ),
        content: const Text(
          'Aplikasi gagal membaca data Jurnal Aktivitas. Berkas ini mungkin dienkripsi oleh sistem dengan kata sandi lain, atau format data di dalamnya rusak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showManualUnlockDialog(jsonFile);
            },
            child: const Text(
              'Buka Kunci (Input PIN)',
              style: TextStyle(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final bool? confirmNew = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Buat Baru?'),
                  content: const Text(
                    'Semua data lama di dalam berkas Jurnal Aktivitas ini akan dihapus total. Tindakan ini tidak bisa dibatalkan!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text(
                        'Ya, Hapus & Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmNew == true) {
                await _controller.resetAndCreateNewLog(jsonFile);
                _triggerLoadData();
              } else {
                _showDecryptionErrorDialog(jsonFile);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Buat Baru',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualUnlockDialog(File jsonFile) {
    final passController = TextEditingController();
    bool obscureText = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Masukkan Kata Sandi'),
          content: TextField(
            controller: passController,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: 'Kata Sandi Dekripsi',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () =>
                    setModalState(() => obscureText = !obscureText),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showDecryptionErrorDialog(jsonFile);
              },
              child: const Text(
                'Kembali',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = passController.text.trim();
                if (input.isEmpty) return;
                try {
                  String encryptedContent = await jsonFile.readAsString();
                  String decrypted = CryptoHelper.decrypt(
                    encryptedContent,
                    input,
                  );
                  if (_controller.handleManualUnlock(decrypted)) {
                    Navigator.pop(ctx);
                    _triggerLoadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Buka kunci data sukses!'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    return;
                  }
                  throw const FormatException();
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Kata sandi salah atau struktur data rusak!',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Buka Data',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialogTaskLink(TimeLogTask jurnalTask) {
    final String todayStr = _controller.getTodayDateString();
    final int todayLogIndex = _controller.logs.indexWhere(
      (entry) => entry.tanggal == todayStr,
    );
    final List<TimeLogTask> todayTasks = todayLogIndex != -1
        ? _controller.logs[todayLogIndex].tasks
        : [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Hubungkan: ${jurnalTask.nama}'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.5,
                child: _controller.allTaskCategories.isEmpty
                    ? const Center(
                        child: Text(
                          "Tidak ada kategori tugas ditemukan di Task Master.",
                        ),
                      )
                    : ListView.builder(
                        itemCount: _controller.allTaskCategories.length,
                        itemBuilder: (context, catIdx) {
                          final category =
                              _controller.allTaskCategories[catIdx];
                          return ExpansionTile(
                            leading: Text(
                              category.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: category.tasks.map((taskItem) {
                              final bool isLinkedWithThis = jurnalTask
                                  .linkedTaskIds
                                  .contains(taskItem.id);
                              return ListTile(
                                dense: true,
                                title: Text(taskItem.name),
                                trailing: Icon(
                                  isLinkedWithThis
                                      ? Icons.link
                                      : Icons.link_off,
                                  color: isLinkedWithThis
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    _controller.updateTaskLink(
                                      jurnalTask,
                                      taskItem.id,
                                      todayTasks,
                                    );
                                  });
                                  _controller.saveData();
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // MODIFIKASI: Memakai durasi default menit yang dinamis dari controller
  void _addActivityDuration(TimeLogTask task, {VoidCallback? onDone}) async {
    final int minutesToAdd = _controller.defaultIncrementMinutes;

    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Waktu?'),
        content: Text(
          'Apakah Anda yakin ingin menambah durasi "${task.nama}" sebanyak $minutesToAdd menit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Ya, Tambah'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;
    setState(() {
      _controller.addActivityDuration(task, minutesToAdd);
    });
    await _controller.saveData();
    if (onDone != null) onDone();
  }

  // DIALOG BARU: Mengubah interval/default menit tambah waktu secara bebas
  void _showSettingsDefaultTimeDialog() {
    final TextEditingController durationController = TextEditingController(
      text: _controller.defaultIncrementMinutes.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Default Tambah Waktu'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: durationController,
            decoration: const InputDecoration(
              labelText: 'Default Menit (Tombol +)',
              border: OutlineInputBorder(),
              suffixText: 'mnt',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null ||
                  int.tryParse(v.trim()) == null ||
                  int.parse(v.trim()) <= 0) {
                return 'Masukkan angka menit yang valid (> 0)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final int newMinutes = int.parse(
                  durationController.text.trim(),
                );
                await _controller.updateDefaultIncrement(newMinutes);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Default waktu berhasil diubah menjadi $newMinutes menit!',
                    ),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showTimerEditLiveDialog(TimeLogTask task, {VoidCallback? onDone}) {
    final TextEditingController timerController = TextEditingController(
      text: task.durasiMenit.toString(),
    );
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Durasi: ${task.nama}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: timerController,
            decoration: const InputDecoration(
              labelText: 'Durasi Waktu (Menit)',
              border: OutlineInputBorder(),
              suffixText: 'mnt',
            ),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (v == null ||
                    int.tryParse(v.trim()) == null ||
                    int.parse(v.trim()) < 0)
                ? 'Masukkan angka valid'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  task.durasiMenit = int.parse(timerController.text.trim());
                });
                await _controller.saveData();
                if (onDone != null) onDone();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog() {
    final TextEditingController inputController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Aktivitas Hari Ini'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: inputController,
            decoration: const InputDecoration(
              labelText: 'Nama Aktivitas / Tugas',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _controller.addNewActivity(inputController.text.trim());
                });
                await _controller.saveData();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditActivityDialog(TimeLogTask task) {
    final TextEditingController editController = TextEditingController(
      text: task.nama,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Aktivitas'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Nama Aktivitas Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  task.nama = newName;
                });
                await _controller.saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _hapusAktivitas(TimeLogTask task) async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Aktivitas?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${task.nama}" dari list hari ini?',
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
    );
    if (konfirmasi == true) {
      setState(() {
        _controller.removeActivity(task);
      });
      await _controller.saveData();
    }
  }

  void _showDialogHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sortedLogs = List<TimeLogEntry>.from(_controller.logs);
            sortedLogs.sort((a, b) => b.tanggal.compareTo(a.tanggal));
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.history, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Riwayat Aktivitas'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: sortedLogs.isEmpty
                    ? const Center(child: Text("Belum ada riwayat aktivitas."))
                    : ListView.builder(
                        itemCount: sortedLogs.length,
                        itemBuilder: (context, index) {
                          final log = sortedLogs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ExpansionTile(
                              title: Text(
                                log.tanggal,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('${log.tasks.length} aktivitas'),
                              children: log.tasks.map((task) {
                                final isLinked = _controller.isTaskTrulyLinked(
                                  task,
                                );
                                return ListTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(task.nama)),
                                      if (isLinked)
                                        const Icon(
                                          Icons.link,
                                          size: 14,
                                          color: Colors.teal,
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _showTimerEditLiveDialog(
                                          task,
                                          onDone: () => setDialogState(() {}),
                                        ),
                                        child: Text(
                                          '  ${task.durasiMenit} mnt',
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.link,
                                          color: Colors.blueGrey,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _showDialogTaskLink(task),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.indigo,
                                          size: 20,
                                        ),
                                        onPressed: () => _addActivityDuration(
                                          task,
                                          onDone: () => setDialogState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final String todayStr = _controller.getTodayDateString();
    final todayLogIndex = _controller.logs.indexWhere(
      (entry) => entry.tanggal == todayStr,
    );
    final List<TimeLogTask> todayTasks = todayLogIndex != -1
        ? _controller.logs[todayLogIndex].tasks
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Jurnal Aktivitas'),
        backgroundColor: Colors.indigo[700],
        actions: [
          // TOMBOL BARU: Mengonfigurasi limit penambahan default menit
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.white),
            tooltip: 'Atur Default Waktu',
            onPressed: _showSettingsDefaultTimeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            onPressed: () {
              if (_controller.logs.isEmpty) return;
              showDialog(
                context: context,
                builder: (context) =>
                    JurnalStatistikDialog(logs: _controller.logs),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _showDialogHistory,
          ),
        ],
      ),
      drawer: const DrawerMenu(isJurnalActive: true),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.isJurnalFileCorrupted
          ? JurnalCorruptedState(
              onActionPressed: () async {
                File jsonFile = await _controller.getJurnalFile();
                _showDecryptionErrorDialog(jsonFile);
              },
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.today, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Aktivitas Hari Ini ($todayStr)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: todayTasks.isEmpty
                      ? JurnalEmptyState(onPressed: _showAddActivityDialog)
                      : ListView.builder(
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            return JurnalTaskItemCard(
                              task: task,
                              index: index,
                              totalTasks: todayTasks.length,
                              isEditMode: _controller.isEditMode,
                              isLinked: _controller.isTaskTrulyLinked(task),
                              onLongPress: () => setState(
                                () => _controller.isEditMode =
                                    !_controller.isEditMode,
                              ),
                              onMoveOrder: (direction) {
                                setState(
                                  () => _controller.moveTaskOrder(
                                    todayTasks,
                                    index,
                                    direction,
                                  ),
                                );
                                _controller.saveData();
                              },
                              onLinkTap: () => _showDialogTaskLink(task),
                              onEditTap: () => _showEditActivityDialog(task),
                              onDeleteTap: () => _hapusAktivitas(task),
                              onEditDurationTap: () =>
                                  _showTimerEditLiveDialog(task),
                              onAddDurationTap: () =>
                                  _addActivityDuration(task),
                            );
                          },
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
    );
  }
}
