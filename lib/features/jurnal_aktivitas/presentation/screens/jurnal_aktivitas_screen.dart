// lib/features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart

import 'dart:convert'; // DIperlukan untuk melakukan jsonDecode & jsonEncode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/services/storage_service.dart'; // DIperlukan untuk akses konfigurasi penyimpanan berkas
import 'package:rutinitasku/core/utils/crypto_helper.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart'; // <--- IMPORT BARU UNTUK ATOMIC WRITE
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE
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
    super.dispose();
  }

  // --- MODIFIKASI FITUR: Dialog Editor Raw JSON dengan Pilihan File Terlebih Dahulu ---
  void _showEditRawJsonDialog() async {
    final StorageService storageService = StorageService();
    final String baseDir = _controller.baseDir;
    final Directory jurnalDir = Directory('$baseDir/jurnal_aktivitas');

    if (!await jurnalDir.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Direktori jurnal tidak ditemukan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ambil daftar semua berkas JSON di dalam folder jurnal_aktivitas
    List<File> jsonFiles = [];
    try {
      jsonFiles = jurnalDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      // Urutkan nama file dari yang paling baru
      jsonFiles.sort((a, b) => b.path.compareTo(a.path));
    } catch (e) {
      debugPrint("Gagal mendaftar file JSON jurnal: $e");
    }

    if (jsonFiles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada file JSON jurnal yang dapat diedit.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    File? selectedFile = jsonFiles.first;

    if (!mounted) return;

    // Tahap 1: Memunculkan Pilihan Berkas Terlebih Dahulu
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Berkas Jurnal (JSON)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Silakan pilih berkas bulanan atau berkas riwayat backup yang ingin diubah langsung strukturnya.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<File>(
                        isExpanded: true,
                        value: selectedFile,
                        items: jsonFiles.map((File file) {
                          String fileName = file.path.split('/').last;
                          return DropdownMenuItem<File>(
                            value: file,
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (File? val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedFile = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (selectedFile != null) {
                      _openJsonEditorForFile(selectedFile!, storageService);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  child: const Text(
                    'Buka Editor',
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

  // Fungsi Pembantu Terpisah untuk Membuka Editor dari Berkas yang Dipilih
  void _openJsonEditorForFile(
    File targetFile,
    StorageService storageService,
  ) async {
    String rawContent = await targetFile.readAsString();
    String displayContent = rawContent.trim();
    String? decryptionError;

    // Coba dekripsi jika konten terenkripsi (tidak diawali [ atau {)
    if (!displayContent.startsWith('{') && !displayContent.startsWith('[')) {
      String? password = await storageService.getEncryptionPassword();
      if (password != null && password.isNotEmpty) {
        try {
          displayContent = CryptoHelper.decrypt(displayContent, password);
        } catch (e) {
          decryptionError =
              "Gagal mendekripsi otomatis berkas. Kata sandi salah atau data korup.\nDetail: $e";
          debugPrint("Dekripsi gagal untuk preview raw JSON jurnal: $e");
        }
      } else {
        decryptionError =
            "Berkas ini terenkripsi, namun tidak ditemukan kata sandi aktif pada sesi sistem.";
      }
    }

    // Rapikan format JSON jika berhasil didekripsi/dibaca secara normal
    try {
      final parsed = jsonDecode(displayContent);
      displayContent = const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {}

    final TextEditingController jsonController = TextEditingController(
      text: displayContent,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit: ${targetFile.path.split('/').last}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (decryptionError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          decryptionError,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Text(
                'Perhatian: Mengubah isi file secara sembarangan dapat merusak seluruh struktur riwayat log waktu jurnal.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: TextField(
                  controller: jsonController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Struktur JSON Jurnal...',
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = jsonController.text;
              // Validasi sintaks JSON sebelum disimpan
              try {
                jsonDecode(newContent);
              } catch (e) {
                final bool confirm =
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('JSON Tidak Valid'),
                        content: Text(
                          'Terdapat kesalahan format JSON:\n$e\n\nApakah Anda yakin ingin tetap menyimpannya?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Tetap Simpan'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!confirm) return;
              }

              try {
                final parsed = jsonDecode(newContent);
                if (parsed is List) {
                  // === PERBAIKAN: Sinkronisasi Enkripsi Sebelum Atomic Write ===
                  String finalContent = jsonEncode(parsed);
                  bool isEncrypted = await storageService.isEncryptionEnabled();
                  String? password = await storageService
                      .getEncryptionPassword();

                  if (isEncrypted && password != null && password.isNotEmpty) {
                    finalContent = CryptoHelper.encrypt(finalContent, password);
                  }

                  await AtomicWriteHelper.writeSafe(
                    targetFile: targetFile,
                    content: finalContent,
                  );
                } else {
                  throw const FormatException();
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'File ${targetFile.path.split('/').last} berhasil diperbarui!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _triggerLoadData(); // Muat ulang status ke memori RAM harian
                }
              } catch (e) {
                // Fallback ke penyimpanan teks mentah menggunakan ATOMIC WRITE jika syntax error sengaja dilewati
                await AtomicWriteHelper.writeSafe(
                  targetFile: targetFile,
                  content: newContent,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _triggerLoadData(); // Muat ulang data ke UI secara instan
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FITUR BARU: Dialog Input Kata Sandi untuk Dekripsi Manual Berkas Rusak ---
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
                  if (await _controller.handleManualUnlock(decrypted)) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
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
          // MODIFIKASI/TAMBAHAN: Tombol Akses Editor JSON Langsung berada di posisi pertama actions
          IconButton(
            icon: const Icon(Icons.data_object, color: Colors.white),
            tooltip: 'Edit File JSON Jurnal Langsung',
            onPressed: _showEditRawJsonDialog,
          ),
          // TOMBOL BARU: Mengonfigurasi limit penambahan default menit
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.white),
            tooltip: 'Atur Default Waktu',
            onPressed: _showSettingsDefaultTimeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            onPressed: () async {
              if (_controller.logs.isEmpty) return;

              // Tampilkan indikator loading kecil agar UX mulus saat membaca multi-file disk[cite: 5]
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Colors.amberAccent),
                ),
              );

              // Definisikan rentang maksimal pembacaan berkas (contoh: 1 tahun ke belakang s.d hari ini)[cite: 5]
              final DateTime now = DateTime.now();
              final DateTime oneYearAgo = DateTime(
                now.year - 1,
                now.month,
                now.day,
              );

              // Panggil helper pemuat multi-file bulanan yang baru dibuat[cite: 5]
              List<TimeLogEntry> allPeriodLogs = await _controller
                  .loadAllLogsForRange(oneYearAgo, now);

              if (context.mounted) {
                Navigator.pop(context); // Tutup loading indicator[cite: 5]

                showDialog(
                  context: context,
                  builder: (context) => JurnalStatistikDialog(
                    logs: allPeriodLogs,
                  ), // Suplai dengan seluruh data[cite: 5]
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: _showDialogHistory,
          ),
          // TAMBAHAN TOMBOL BARU: Tambah Tugas/Aktivitas di PALING KANAN!
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Tambah Aktivitas Hari Ini',
            onPressed: _showAddActivityDialog,
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
      // MENGGUNAKAN WIDGET KUSTOM ADMOB YANG BARU DAN MODULAR PADA FOOTER LAYOUT
      bottomNavigationBar: const AdaptiveBannerAd(
        adKey: 'jurnal_activity_banner',
      ),
    );
  }
}
