// lib/features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../data/models/time_log_model.dart';
import '../widgets/jurnal_statistik_dialog.dart';
import '../controllers/jurnal_aktivitas_controller.dart'; // Import Controller Baru

class JurnalAktivitasScreen extends StatefulWidget {
  const JurnalAktivitasScreen({super.key});

  @override
  State<JurnalAktivitasScreen> createState() => _JurnalAktivitasScreenState();
}

class _JurnalAktivitasScreenState extends State<JurnalAktivitasScreen> {
  // Inisialisasi controller pembawa state logika bisnis
  final JurnalAktivitasController _controller = JurnalAktivitasController();

  @override
  void initState() {
    super.initState();
    _triggerLoadData();
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

  // --- INTERAKSI DIALOG UI ---
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
            onPressed: () async {
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
                    'Semua data lama di dalam berkas Jurnal Aktivitas ini akan dihapus total dan diganti dengan struktur baru yang kosong. Tindakan ini tidak bisa dibatalkan!',
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

                  bool success = _controller.handleManualUnlock(decrypted);
                  if (success) {
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
                                subtitle: Text(
                                  'Total hitungan: ${taskItem.count}',
                                ),
                                trailing: Icon(
                                  isLinkedWithThis
                                      ? Icons.link
                                      : Icons.link_off,
                                  color: isLinkedWithThis
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                tileColor: isLinkedWithThis
                                    ? Colors.teal.withOpacity(0.05)
                                    : null,
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

  void _addActivityDuration(TimeLogTask task, {VoidCallback? onDone}) async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Waktu?'),
        content: Text(
          'Apakah Anda yakin ingin menambah durasi "${task.nama}" sebanyak 30 menit?',
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
      _controller.addActivityDuration30Minutes(task);
    });
    await _controller.saveData();
    if (onDone != null) onDone();
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
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Durasi tidak boleh kosong';
              if (int.tryParse(v.trim()) == null)
                return 'Masukkan angka yang valid';
              if (int.parse(v.trim()) < 0) return 'Durasi tidak boleh negatif';
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

  Widget _buildCorruptedJurnalEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gpp_maybe_rounded,
                size: 72,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Berkas Jurnal Terkunci / Rusak',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Aplikasi gagal memuat data Jurnal Aktivitas dari disk lokal Anda.\nStruktur penyimpanan teks JSON bermasalah atau memerlukan PIN dekripsi enkripsi AES-256 yang tepat untuk membukanya kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                File jsonFile = await _controller.getJurnalFile();
                _showDecryptionErrorDialog(jsonFile);
              },
              icon: const Icon(
                Icons.lock_open_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Buka Opsi Pemulihan Jurnal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            tooltip: 'Lihat Statistik',
            onPressed: () {
              if (_controller.logs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Belum ada data untuk dianalisis.'),
                  ),
                );
                return;
              }
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
          ? _buildCorruptedJurnalEmptyState()
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
                      ? UniversalEmptyState(
                          icon: Icons.edit_calendar_rounded,
                          title: 'Jurnal Hari Ini Masih Kosong',
                          description:
                              'Kamu belum mencatat produktivitas atau kegiatan apa pun hari ini. Yuk, mulai rekam aktivitas pertamamu sekarang juga!',
                          buttonLabel: 'Catat Aktivitas Sekarang',
                          themeColor: Colors.indigo,
                          onPressed: _showAddActivityDialog,
                        )
                      : ListView.builder(
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            final bool isLinked = _controller.isTaskTrulyLinked(
                              task,
                            );
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onLongPress: () {
                                  setState(() {
                                    _controller.isEditMode =
                                        !_controller.isEditMode;
                                  });
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _controller.isEditMode
                                      ? Colors.amber[50]
                                      : Colors.teal[50],
                                  radius: 16,
                                  child: Icon(
                                    _controller.isEditMode
                                        ? Icons.edit_attributes
                                        : Icons.check_circle_outline,
                                    color: _controller.isEditMode
                                        ? Colors.amber[800]
                                        : Colors.teal,
                                    size: 18,
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (isLinked)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6.0,
                                            ),
                                            child: Tooltip(
                                              message:
                                                  'Terhubung dengan Task Master',
                                              triggerMode:
                                                  TooltipTriggerMode.tap,
                                              child: const Icon(
                                                Icons.link,
                                                size: 16,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (_controller.isEditMode) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8.0,
                                        runSpacing: 6.0,
                                        children: [
                                          _buildMobileEditButton(
                                            icon: Icons.arrow_upward,
                                            color: index > 0
                                                ? Colors.indigo
                                                : Colors.grey[300]!,
                                            onPressed: index > 0
                                                ? () {
                                                    setState(() {
                                                      _controller.moveTaskOrder(
                                                        todayTasks,
                                                        index,
                                                        -1,
                                                      );
                                                    });
                                                    _controller.saveData();
                                                  }
                                                : null,
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.arrow_downward,
                                            color: index < todayTasks.length - 1
                                                ? Colors.indigo
                                                : Colors.grey[300]!,
                                            onPressed:
                                                index < todayTasks.length - 1
                                                ? () {
                                                    setState(() {
                                                      _controller.moveTaskOrder(
                                                        todayTasks,
                                                        index,
                                                        1,
                                                      );
                                                    });
                                                    _controller.saveData();
                                                  }
                                                : null,
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.link,
                                            color: Colors.teal,
                                            onPressed: () =>
                                                _showDialogTaskLink(task),
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.edit_note,
                                            color: Colors.blueGrey,
                                            onPressed: () =>
                                                _showEditActivityDialog(task),
                                          ),
                                          _buildMobileEditButton(
                                            icon: Icons.delete_outline,
                                            color: Colors.redAccent,
                                            onPressed: () =>
                                                _hapusAktivitas(task),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: _controller.isEditMode
                                    ? const SizedBox.shrink()
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _showTimerEditLiveDialog(task),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.amber.shade200,
                                                ),
                                              ),
                                              child: Text(
                                                ' ${task.durasiMenit} mnt',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber[900],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: Colors.indigo,
                                              size: 22,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            onPressed: () =>
                                                _addActivityDuration(task),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _controller.isJurnalFileCorrupted
          ? null
          : FloatingActionButton(
              onPressed: _showAddActivityDialog,
              backgroundColor: Colors.indigo[700],
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            ),
    );
  }

  Widget _buildMobileEditButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[100] : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onPressed == null
                ? Colors.grey[200]!
                : color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null ? Colors.grey[400] : color,
        ),
      ),
    );
  }
}
