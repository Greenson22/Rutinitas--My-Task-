// lib/features/notes/presentation/screens/notes_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/presentation/widgets/drawer_menu.dart';
import 'package:rutinitasku/core/presentation/widgets/universal_empty_state.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/utils/atomic_write_helper.dart';
import 'package:rutinitasku/core/utils/crypto_helper.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU
import '../../models/note_model.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final StorageService _storageService = StorageService();
  final Color _themeColor = Colors.indigo;
  bool _isLoading = true;
  bool _isSectionEditMode = false;
  bool _isCardEditMode = false;

  // Variabel untuk menyimpan query pencarian
  String _searchQuery = '';

  // STATE BARU: Kontrol untuk menampilkan atau menyembunyikan kategori/grup tersembunyi
  bool _showHiddenSection = false;
  bool _isGlobalEncryptionEnabled =
      false; // <-- STATE BARU: Mengontrol visibilitas ikon enkripsi sistem di AppBar

  // PERUBAHAN: Mulai dengan list kosong agar inisialisasi seksi dilakukan secara dinamis dari storage
  List<String> _sectionKeys = [];
  final Map<String, List<NoteGroup>> _groupedCategories = {};

  // STATE BARU: Menampung kategori grup tersembunyi terpisah dari grid utama
  final Map<String, List<NoteGroup>> _hiddenGroupedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadNotesData();
  }

  // PERUBAHAN UTAMA: Ditambahkan jeda Future mikro asinkron agar sistem operasi selesai mengamankan file sebelum dibaca
  Future<void> _loadNotesData() async {
    setState(() => _isLoading = true);
    try {
      // BERIKAN JEDA MIKRO: Menjamin penulisan enkripsi massal dari modal dialog selesai sepenuhnya di disk storage
      await Future.delayed(const Duration(milliseconds: 150));

      final baseDir = await _storageService.getBaseDirSetting();
      final files = await _storageService.getAllNoteGroups(baseDir);

      // Ambil status konfigurasi enkripsi saat ini
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();

      // Sinkronisasikan status enkripsi sistem untuk kontrol UI ikon AppBar
      setState(() {
        _isGlobalEncryptionEnabled = isEncrypted;
      });

      List<NoteGroup> loadedGroups = [];

      for (var file in files) {
        if (!await file.exists()) continue;

        String content = await file.readAsString();

        // === LOGIKA DEKRIPSI OTOMATIS PERBAIKAN ===
        final trimmedContent = content.trim();
        bool isRawJson =
            trimmedContent.startsWith('{') || trimmedContent.startsWith('[');

        // Menyiapkan nama file fallback untuk groupName jika file corrupt/terenkripsi
        String fileName = file.path.split('/').last.replaceAll('.json', '');

        try {
          if (isEncrypted && password != null) {
            if (!isRawJson) {
              // Kondisi Normal: File terenkripsi, lakukan dekripsi seperti biasa
              content = CryptoHelper.decrypt(content, password);
            } else {
              // =========================================================================
              // PERBAIKAN UTAMA: BLOK AUTO-ENCRYPT SEPIHAK TELAH DIHAPUS TOTAL
              // Berkas polos/raw JSON dibiarkan apa adanya tanpa dipaksa enkripsi otomatis harian.
              // =========================================================================
              debugPrint(
                "Berkas mentah JSON polos terdeteksi dan dibiarkan tanpa enkripsi paksa: ${file.path}",
              );
            }
          }

          loadedGroups.add(NoteGroup.fromJson(jsonDecode(content)));
        } catch (error) {
          debugPrint(
            "Gagal memuat atau mendekripsi berkas ${file.path}: $error",
          );

          // TETAP TAMPILKAN SEBAGAI CARD: Tambahkan mock NoteGroup dengan penanda ID khusus
          loadedGroups.add(
            NoteGroup(
              id: "CORRUPTED_${DateTime.now().millisecondsSinceEpoch}_$fileName",
              groupName: fileName,
              icon: '⚠️',
              notes: [],
              sectionName:
                  'Berkas Rusak / Terenkripsi', // Seksi otomatis khusus berkas bermasalah
              isHidden: false,
            ),
          );
        }
      }

      // PERBAIKAN: Mengurutkan list berdasarkan orderIndex secara persisten (bukan acak)
      loadedGroups.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      // Bersihkan memory state lama sebelum memasukkan data hasil load
      _sectionKeys.clear();
      _groupedCategories.clear();
      _hiddenGroupedCategories
          .clear(); // Bersihkan data penampung tersembunyi lama

      // Distribusikan note groups ke dalam seksinya masing-masing dengan filter isHidden
      for (var group in loadedGroups) {
        String secName =
            group.sectionName; // Menggunakan properti baru dari model
        if (group.isHidden) {
          if (!_hiddenGroupedCategories.containsKey(secName)) {
            _hiddenGroupedCategories[secName] = [];
          }
          _hiddenGroupedCategories[secName]!.add(group);
        } else {
          if (!_sectionKeys.contains(secName)) {
            _sectionKeys.add(secName);
            _groupedCategories[secName] = [];
          }
          _groupedCategories[secName]!.add(group);
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Gagal memuat catatan: $e");
    }
  }

  // === PENERAPAN SINKRONISASI AKTIF: PROTEKSI ATOMIC WRITE ANTI-KORUP ===
  Future<void> _saveGroupData(NoteGroup group) async {
    // Lewati penyimpanan otomatis jika ini adalah berkas korup buatan/mock
    if (group.id.startsWith("CORRUPTED_")) return;
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      final File targetFile = File('$baseDir/notes/${group.id}.json');

      // Ambil status konfigurasi enkripsi saat ini
      bool isEncrypted = await _storageService.isEncryptionEnabled();
      String? password = await _storageService.getEncryptionPassword();
      String jsonString = _storageService.formatJsonPretty(group.toJson());

      if (isEncrypted && password != null) {
        jsonString = CryptoHelper.encrypt(jsonString, password);
      }

      // PANGGIL HELPER UNTUK ATOMIC WRITE TERPUSAT
      await AtomicWriteHelper.writeSafe(
        targetFile: targetFile,
        content: jsonString,
      );
    } catch (e) {
      debugPrint("Gagal menyimpan grup via Atomic Write Helper: $e");
    }
  }

  // PEMBARUAN PERMANEN: Fungsi untuk menyimpan urutan seksi baru ke local storage
  Future<void> _saveSectionOrderToStorage() async {
    int globalIndex = 0;
    // Iterasi disesuaikan dengan urutan seksi (_sectionKeys) yang baru saja ditukar
    for (String sectionKey in _sectionKeys) {
      final groupsInSection = _groupedCategories[sectionKey] ?? [];
      for (var group in groupsInSection) {
        if (group.id.startsWith("CORRUPTED_")) continue;
        // Atur kembali orderIndex agar grup di seksi atas selalu memiliki bobot lebih kecil
        group.orderIndex = globalIndex;
        globalIndex++;
        // Tulis perubahan ke dalam disk
        await _saveGroupData(group);
      }
    }
  }

  Future<void> _deleteGroupData(NoteGroup group) async {
    try {
      final baseDir = await _storageService.getBaseDirSetting();
      await _storageService.deleteNoteGroup(baseDir, group.id);
      setState(() {
        for (var key in _sectionKeys) {
          _groupedCategories[key]?.removeWhere((g) => g.id == group.id);
        }
        for (var key in _hiddenGroupedCategories.keys) {
          _hiddenGroupedCategories[key]?.removeWhere((g) => g.id == group.id);
        }
      });
    } catch (e) {
      debugPrint("Gagal menghapus grup: $e");
    }
  }

  // --- FITUR BARU: Dialog Input Kata Sandi untuk Dekripsi Manual Berkas Rusak ---
  void _showManualDecryptDialog(NoteGroup corruptedGroup) {
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_open_rounded, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Dekripsi Berkas'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan password yang sesuai untuk membuka file "${corruptedGroup.groupName}.json":',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Password Enkripsi Lama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key_rounded),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Password tidak boleh kosong'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final messenger = ScaffoldMessenger.of(context);
              final String inputPassword = passwordController.text;
              Navigator.pop(context);

              setState(() => _isLoading = true);

              try {
                final baseDir = await _storageService.getBaseDirSetting();
                // Potong prefix mock ID untuk mendapatkan nama file asli yang berada di penyimpanan
                final String originalFileName = corruptedGroup.id.replaceFirst(
                  RegExp(r'CORRUPTED_\d+_'),
                  '',
                );
                final File targetFile = File(
                  '$baseDir/notes/$originalFileName.json',
                );

                if (!await targetFile.exists()) {
                  throw Exception(
                    "Berkas fisik tidak ditemukan di penyimpanan.",
                  );
                }

                String rawContent = await targetFile.readAsString();

                // Langkah 1: Coba dekripsi manual data teks menggunakan input kunci dari pengguna
                String decryptedContent = CryptoHelper.decrypt(
                  rawContent.trim(),
                  inputPassword,
                );

                // Langkah 2: Uji kelayakan parsing JSON untuk memastikan password valid & struktur berkas aman
                final Map<String, dynamic> parsedJson = jsonDecode(
                  decryptedContent,
                );
                NoteGroup decryptedGroup = NoteGroup.fromJson(parsedJson);

                // Langkah 3: Gunakan Atomic Write terproteksi agar proses penulisan ulang aman dari korupsi data
                await _saveGroupData(decryptedGroup);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berkas "${decryptedGroup.groupName}" berhasil didekripsi dan disinkronkan ke sistem!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint("Gagal melakukan dekripsi manual berkas: $e");
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Gagal mendekripsi! Password salah atau struktur biner di dalam JSON memang korup.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } finally {
                _loadNotesData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text(
              'Dekripsi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- FITUR BARU: Dialog Editor Raw JSON Langsung dengan Informasi Galat Enkripsi ---
  void _showEditRawJsonDialog(NoteGroup group) async {
    String targetId = group.id;
    bool isCorrupted = targetId.startsWith("CORRUPTED_");

    if (isCorrupted) {
      targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
    }

    final baseDir = await _storageService.getBaseDirSetting();
    File targetFile = File('$baseDir/notes/$targetId.json');

    if (!await targetFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File fisik tidak ditemukan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String rawContent = await targetFile.readAsString();
    String displayContent = rawContent.trim();
    String? decryptionError; // Menyimpan informasi kesalahan dekripsi jika ada

    // Coba dekripsi jika konten bukan plain JSON (tidak diawali { atau [)
    if (!displayContent.startsWith('{') && !displayContent.startsWith('[')) {
      String? password = await _storageService.getEncryptionPassword();
      if (password != null && password.isNotEmpty) {
        try {
          displayContent = CryptoHelper.decrypt(displayContent, password);
        } catch (e) {
          decryptionError =
              "Gagal mendekripsi otomatis berkas. Kata sandi salah atau data korup.\nDetail: $e";
          debugPrint("Dekripsi gagal untuk preview raw JSON: $e");
        }
      } else {
        decryptionError =
            "Berkas ini terenkripsi, namun tidak ditemukan kata sandi aktif pada sesi sistem.";
      }
    }

    // Rapikan format JSON jika berhasil didekripsi/dibaca secara normal
    try {
      final parsed = jsonDecode(displayContent);
      displayContent = _storageService.formatJsonPretty(parsed);
    } catch (_) {
      // Biarkan string aslinya jika gagal di-parse agar bisa diteliti kerusakannya oleh user
    }

    final TextEditingController jsonController = TextEditingController(
      text: displayContent,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit File .json Langsung'),
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
                          decryptionError!,
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
                'Perhatian: Mengubah isi file secara sembarangan dapat merusak struktur data aplikasi.',
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
                    hintText: 'Struktur JSON...',
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

              // Validasi JSON yang diedit sebelum disimpan
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

                if (!confirm) return; // Batal simpan
              }

              // MODIFIKASI ATOMIC WRITE: Simpan via model agar status enkripsi konsisten dipertahankan di disk storage
              try {
                final parsed = jsonDecode(newContent);
                parsed['id'] = targetId;
                NoteGroup updatedGroup = NoteGroup.fromJson(parsed);
                await _saveGroupData(updatedGroup);

                if (mounted) {
                  Navigator.pop(context); // Tutup dialog editor
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File JSON berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadNotesData(); // Refresh UI
                }
              } catch (e) {
                // ✅ PERBAIKAN: Amankan jalur fallback dengan Atomic Write Helper Terpusat
                await AtomicWriteHelper.writeSafe(
                  targetFile: targetFile,
                  content: newContent,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadNotesData();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Fungsi helper untuk memicu konfirmasi dialog hapus grup
  Future<bool> _showConfirmDeleteDialog(NoteGroup group) async {
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
            content: Text(
              'Apakah Anda yakin ingin menghapus grup "${group.groupName}"? '
              'Semua data catatan di dalam grup ini akan terhapus secara permanen.',
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

  // --- TEMBAHAN BARU: Fungsi Pengubah Status Visibilitas Grup Catatan ---
  Future<void> _toggleGroupVisibility(NoteGroup group) async {
    if (group.id.startsWith("CORRUPTED_")) return;
    setState(() {
      group.isHidden = !group.isHidden; // Balikkan status visibilitas
    });
    await _saveGroupData(group);
    await _loadNotesData(); // Muat ulang pemisahan struktur data grid
  }

  // --- TEMBAHAN BARU: Dialog Pemindahan Grup Note ke Seksi Lain ---
  void _showMoveGroupSectionDialog(NoteGroup group) {
    if (group.id.startsWith("CORRUPTED_")) return;
    List<String> availableSections = List.from(_sectionKeys);
    // Tambahkan seksi dari penampung hidden jika belum terdaftar agar opsinya lengkap
    for (var key in _hiddenGroupedCategories.keys) {
      if (!availableSections.contains(key)) {
        availableSections.add(key);
      }
    }
    if (!availableSections.contains("Catatan Utama")) {
      availableSections.add("Catatan Utama");
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pindahkan "${group.groupName}" ke Seksi...'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableSections.length,
              itemBuilder: (context, index) {
                final sectionName = availableSections[index];
                final bool isCurrentSection = group.sectionName == sectionName;
                return ListTile(
                  title: Text(sectionName),
                  leading: Icon(
                    isCurrentSection ? Icons.folder_special : Icons.folder_open,
                    color: isCurrentSection ? _themeColor : Colors.grey,
                  ),
                  trailing: isCurrentSection
                      ? Icon(Icons.check_circle, color: _themeColor)
                      : null,
                  selected: isCurrentSection,
                  onTap: isCurrentSection
                      ? null
                      : () async {
                          // PERBAIKAN: Dapatkan ScaffoldMessenger sebelum dialog di-pop / tree context tidak stabil
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          setState(() {
                            group.sectionName = sectionName.isEmpty
                                ? "Catatan Utama"
                                : sectionName;
                          });
                          await _saveGroupData(group);
                          await _loadNotesData();
                          // Tampilkan pesan menggunakan referensi messenger yang aman
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Grup "${group.groupName}" berhasil dipindahkan ke seksi "$sectionName"',
                              ),
                              backgroundColor: _themeColor,
                            ),
                          );
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk memfilter list kategori berdasarkan query pencarian
  Map<String, List<NoteGroup>> _getFilteredCategories(
    Map<String, List<NoteGroup>> sourceMap,
    List<String> keys,
  ) {
    if (_searchQuery.isEmpty) return sourceMap;
    Map<String, List<NoteGroup>> filtered = {};
    for (var key in keys) {
      filtered[key] = (sourceMap[key] ?? []).where((group) {
        return group.groupName.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
      }).toList();
    }
    return filtered;
  }

  // METHOD BARU: Alur Sekuensial Berantai Berurutan (Seksi Baru -> Group Catatan) Khusus Kondisi Kosong
  void _showSequentialAddDialog() {
    final sectionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langkah 1: Buat Seksi Catatan'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: sectionController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Seksi Utama',
              hintText: 'Misal: KULIAH, KERJA, ARSIP...',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama seksi tidak boleh kosong'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newSectionName = sectionController.text.trim();
                if (!_sectionKeys.contains(newSectionName)) {
                  setState(() {
                    _sectionKeys.add(newSectionName);
                    _groupedCategories[newSectionName] = [];
                  });
                }
                Navigator.pop(context);
                // Langsung berantai membuka pembuatan grup catatan di dalam seksi ini
                _showAddGroupDialog(newSectionName);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text(
              'Lanjut ke Grup ➔',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog khusus untuk menambah Seksi Baru
  void _showAddSectionDialog() {
    final TextEditingController sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Seksi Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            labelText: 'Nama Seksi',
            hintText: 'Misal: Kerja, Kuliah, Arsip...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSectionName = sectionController.text.trim();
              if (newSectionName.isNotEmpty &&
                  !_sectionKeys.contains(newSectionName)) {
                setState(() {
                  _sectionKeys.add(newSectionName);
                  _groupedCategories[newSectionName] = [];
                });
                Navigator.pop(context);
                // Menampilkan notifikasi Snackbar setelah seksi ditambahkan
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seksi "$newSectionName" berhasil dibuat! Tekan tombol + di kanannya untuk menambah grup.',
                    ),
                    backgroundColor: _themeColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // PERUBAHAN: Memasukkan parameter `sectionName` ke dalam inisialisasi NoteGroup baru
  void _showAddGroupDialog(String sectionName) {
    final TextEditingController groupController = TextEditingController();
    final TextEditingController iconController = TextEditingController(
      text: '📝',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _sectionKeys.length <= 1 && _groupedCategories[sectionName]!.isEmpty
              ? 'Langkah 2: Buat Grup di $sectionName'
              : 'Buat Grup Baru di $sectionName',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: groupController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Grup Catatan',
                  hintText: 'Misal: Ide Bisnis, Kuliah Flutter, Jurnal...',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama grup tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Ikon Emoji'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ikon tidak boleh kosong'
                    : null,
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
              if (formKey.currentState!.validate()) {
                final newName = groupController.text.trim();
                final newIcon = iconController.text.trim();

                final currentSectionLength =
                    _groupedCategories[sectionName]?.length ?? 0;
                final newGroup = NoteGroup(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  groupName: newName,
                  icon: newIcon,
                  notes: [],
                  sectionName: sectionName,
                  isHidden: false,
                  orderIndex: currentSectionLength,
                );

                setState(() => _groupedCategories[sectionName]!.add(newGroup));
                await _saveGroupData(newGroup);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text(
              'Simpan & Selesai',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Mengubah dialog edit agar mendukung perubahan nama sekaligus ikon emoji
  void _showEditGroupDialog(NoteGroup group) {
    if (group.id.startsWith("CORRUPTED_")) return;
    final TextEditingController nameController = TextEditingController(
      text: group.groupName,
    );
    final TextEditingController iconController = TextEditingController(
      text: group.icon,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama & Ikon Grup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Grup Baru'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Ikon Emoji Baru'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedName = nameController.text.trim();
              final updatedIcon = iconController.text.trim();
              if (updatedName.isNotEmpty) {
                setState(() {
                  group.groupName = updatedName;
                  group.icon = updatedIcon.isEmpty ? '📝' : updatedIcon;
                });
                await _saveGroupData(group);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRenameSectionDialog(String oldSectionName) {
    final TextEditingController renameController = TextEditingController(
      text: oldSectionName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Seksi'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSectionName = renameController.text.trim();
              if (newSectionName.isNotEmpty &&
                  newSectionName != oldSectionName) {
                setState(() {
                  int index = _sectionKeys.indexOf(oldSectionName);
                  if (index != -1) {
                    _sectionKeys[index] = newSectionName;
                  }
                  final items = _groupedCategories.remove(oldSectionName) ?? [];
                  _groupedCategories[newSectionName] = items;
                  for (var group in items) {
                    group.sectionName = newSectionName;
                  }
                });

                // Simpan perubahan nama seksi secara massal asinkron ke masing-masing file grup
                final items = _groupedCategories[newSectionName] ?? [];
                for (var group in items) {
                  await _saveGroupData(group);
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSection(String sectionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Hapus Seksi?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus seksi "$sectionName"? '
          'Semua grup dan catatan di dalam seksi ini akan dihapus permanen dari penyimpanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final groupsToDelete = _groupedCategories[sectionName] ?? [];
              for (var group in groupsToDelete) {
                try {
                  final baseDir = await _storageService.getBaseDirSetting();
                  String targetId = group.id;
                  if (targetId.startsWith("CORRUPTED_")) {
                    targetId = targetId.replaceFirst(
                      RegExp(r'CORRUPTED_\d+_'),
                      '',
                    );
                  }
                  await _storageService.deleteNoteGroup(baseDir, targetId);
                } catch (e) {
                  debugPrint("Gagal menghapus grup disk: $e");
                }
              }
              setState(() {
                _sectionKeys.remove(sectionName);
                _groupedCategories.remove(sectionName);
              });
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // NEW METHOD: Pemicu refresh instan halaman notes ketika dipanggil dari appBar lokal (opsional)
  void _openLocalSettings() async {
    final baseDir = await _storageService.getBaseDirSetting();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentBaseDir: baseDir,
        onSave: (newPath) async {
          await _storageService.saveBaseDirSetting(newPath);
          _loadNotesData();
        },
        onEncryptionToggled: () {
          _loadNotesData(); // <--- Paksa refresh instan data grid di sini
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> allRenderedKeys = List.from(_sectionKeys);
    Map<String, List<NoteGroup>> allRenderedItems = _getFilteredCategories(
      _groupedCategories,
      _sectionKeys,
    );

    if (_showHiddenSection && _hiddenGroupedCategories.isNotEmpty) {
      _hiddenGroupedCategories.forEach((sectionKey, groupsList) {
        if (groupsList.isNotEmpty) {
          String hiddenKey = '${sectionKey}_hidden_key';
          allRenderedKeys.add(hiddenKey);
          if (_searchQuery.isEmpty) {
            allRenderedItems[hiddenKey] = groupsList;
          } else {
            allRenderedItems[hiddenKey] = groupsList.where((group) {
              return group.groupName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
            }).toList();
          }
        }
      });
    }

    final int visibleKeysCount = _sectionKeys.length;

    // Dibungkus komponen Scaffold terluar agar properti bottomNavigationBar bisa aktif merender widget iklan banner
    return Scaffold(
      body: GroupedSectionLayout<NoteGroup>(
        title: 'Note Groups',
        forceShowMenu: true,
        drawer: const DrawerMenu(isNotesActive: true),
        isLoading: _isLoading,
        isEmpty: allRenderedKeys.isEmpty,
        emptyStateView: UniversalEmptyState(
          icon: Icons.note_alt_rounded,
          title: 'Folder Catatan Masih Kosong',
          description:
              'Belum ada seksi atau grup penampung catatan yang terdaftar. Yuk, buat Seksi Utama sekaligus Grup Catatan pertama Anda sekarang juga!',
          buttonLabel: 'Buat Seksi & Grup Catatan',
          themeColor: _themeColor,
          onPressed: _showSequentialAddDialog,
        ),
        // === PARAMETER APPBAR TRAILING ACTION ===
        appBarTrailingAction: _isGlobalEncryptionEnabled
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Tooltip(
                  message: 'Enkripsi ...',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.tealAccent,
                      size: 18,
                    ),
                  ),
                ),
              )
            : null,
        sectionKeys: allRenderedKeys,
        groupedItems: allRenderedItems,
        isSelectMode: false,
        selectedItemsCount: 0,
        onClearSelection: () {},
        enableSearch: true,
        enableMultiSelect: false,
        onSearchChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
        onAddPressed: _showAddSectionDialog,
        additionalAction: IconButton(
          icon: Icon(
            _showHiddenSection ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          tooltip: _showHiddenSection
              ? 'Sembunyikan Grup Nonaktif'
              : 'Tampilkan Grup Tersembunyi',
          onPressed: () {
            setState(() {
              _showHiddenSection = !_showHiddenSection;
            });
          },
        ),
        sectionHeaderBuilder: (context, index, sectionName, isLayoutEditMode) {
          if (index >= visibleKeysCount) {
            String originalName = sectionName.replaceAll('_hidden_key', '');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == visibleKeysCount)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Divider(thickness: 2, color: Colors.grey),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '$originalName (Tersembunyi)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            );
          }
          return InteractiveSectionHeader(
            sectionName: sectionName,
            themeColor: _themeColor,
            isEditMode: isLayoutEditMode ? true : _isSectionEditMode,
            isFirst: index == 0,
            isLast: index == _sectionKeys.length - 1,
            onToggleEdit: () =>
                setState(() => _isSectionEditMode = !_isSectionEditMode),
            onEditName: () => _showRenameSectionDialog(sectionName),
            onDelete: () => _confirmDeleteSection(sectionName),
            onAddItem: () => _showAddGroupDialog(sectionName),
            onMoveUp: () async {
              if (index > 0) {
                setState(() {
                  final temp = _sectionKeys[index];
                  _sectionKeys[index] = _sectionKeys[index - 1];
                  _sectionKeys[index - 1] = temp;
                });
                await _saveSectionOrderToStorage();
              }
            },
            onMoveDown: () async {
              if (index < _sectionKeys.length - 1) {
                setState(() {
                  final temp = _sectionKeys[index];
                  _sectionKeys[index] = _sectionKeys[index + 1];
                  _sectionKeys[index + 1] = temp;
                });
                await _saveSectionOrderToStorage();
              }
            },
          );
        },
        gridItemBuilder:
            (context, noteGroup, index, sectionItems, isLayoutEditMode) {
              final bool isCorrupted = noteGroup.id.startsWith("CORRUPTED_");

              if (isCorrupted) {
                return InteractiveGridCard(
                  themeColor: Colors.redAccent,
                  isEditMode: isLayoutEditMode ? true : _isCardEditMode,
                  isHiddenStyle: false,
                  isFirst: index == 0,
                  isLast: index == sectionItems.length - 1,
                  onTap: () {
                    _showManualDecryptDialog(noteGroup);
                  },
                  onLongPress: () =>
                      setState(() => _isCardEditMode = !_isCardEditMode),
                  onMoveLeft: () {},
                  onMoveRight: () {},
                  popupMenuItems: [
                    const PopupMenuItem(
                      value: 'decrypt',
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_open_rounded,
                            size: 18,
                            color: Colors.indigo,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Dekripsi Manual',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit_raw_json',
                      child: Row(
                        children: [
                          Icon(Icons.data_object, size: 18, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            'Edit File .json',
                            style: TextStyle(fontSize: 13),
                          ),
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
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Hapus Berkas Rusak',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onPopupSelected: (value) async {
                    if (value == 'decrypt') {
                      _showManualDecryptDialog(noteGroup);
                    } else if (value == 'edit_raw_json') {
                      _showEditRawJsonDialog(noteGroup);
                    } else if (value == 'delete') {
                      final String originalId = noteGroup.id.replaceFirst(
                        RegExp(r'CORRUPTED_\d+_'),
                        '',
                      );
                      final mockGroupForDelete = NoteGroup(
                        id: originalId,
                        groupName: noteGroup.groupName,
                        icon: '',
                        notes: [],
                      );

                      final bool isConfirmed = await _showConfirmDeleteDialog(
                        mockGroupForDelete,
                      );
                      if (isConfirmed) {
                        await _deleteGroupData(mockGroupForDelete);
                        _loadNotesData();
                      }
                    }
                  },
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        noteGroup.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        noteGroup.groupName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Terbaca Enkripsi / Korup',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return InteractiveGridCard(
                themeColor: _themeColor,
                isEditMode: isLayoutEditMode ? true : _isCardEditMode,
                isHiddenStyle: noteGroup.isHidden,
                isFirst: index == 0,
                isLast: index == sectionItems.length - 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NoteDetailScreen(noteGroup: noteGroup),
                    ),
                  ).then((_) => _loadNotesData());
                },
                onLongPress: () =>
                    setState(() => _isCardEditMode = !_isCardEditMode),
                onMoveLeft: () async {
                  if (index > 0) {
                    setState(() {
                      final list =
                          _groupedCategories[noteGroup.sectionName] ?? [];
                      if (list.isNotEmpty) {
                        final temp = list[index];
                        list[index] = list[index - 1];
                        list[index - 1] = temp;
                      }
                    });
                    final currentList =
                        _groupedCategories[noteGroup.sectionName] ?? [];
                    for (int i = 0; i < currentList.length; i++) {
                      currentList[i].orderIndex = i;
                      await _saveGroupData(currentList[i]);
                    }
                  }
                },
                onMoveRight: () async {
                  if (index < sectionItems.length - 1) {
                    setState(() {
                      final list =
                          _groupedCategories[noteGroup.sectionName] ?? [];
                      if (list.isNotEmpty) {
                        final temp = list[index];
                        list[index] = list[index + 1];
                        list[index + 1] = temp;
                      }
                    });
                    final currentList =
                        _groupedCategories[noteGroup.sectionName] ?? [];
                    for (int i = 0; i < currentList.length; i++) {
                      currentList[i].orderIndex = i;
                      await _saveGroupData(currentList[i]);
                    }
                  }
                },
                popupMenuItems: [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.teal),
                        SizedBox(width: 10),
                        Text(
                          'Ubah Nama & Ikon',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit_raw_json',
                    child: Row(
                      children: [
                        Icon(Icons.data_object, size: 18, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Edit File .json', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'move_section',
                    child: Row(
                      children: [
                        Icon(
                          Icons.drive_file_move_outlined,
                          size: 18,
                          color: Colors.indigo,
                        ),
                        SizedBox(width: 10),
                        Text('Pindahkan Seksi', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_visibility',
                    child: Row(
                      children: [
                        Icon(
                          noteGroup.isHidden
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          noteGroup.isHidden
                              ? 'Tampilkan Grup'
                              : 'Sembunyikan Grup',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text(
                          'Hapus Grup',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                onPopupSelected: (value) async {
                  if (value == 'edit') {
                    _showEditGroupDialog(noteGroup);
                  } else if (value == 'edit_raw_json') {
                    _showEditRawJsonDialog(noteGroup);
                  } else if (value == 'move_section') {
                    _showMoveGroupSectionDialog(noteGroup);
                  } else if (value == 'toggle_visibility') {
                    await _toggleGroupVisibility(noteGroup);
                  } else if (value == 'delete') {
                    final bool isConfirmed = await _showConfirmDeleteDialog(
                      noteGroup,
                    );
                    if (isConfirmed) {
                      _deleteGroupData(noteGroup);
                    }
                  }
                },
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      noteGroup.icon.isEmpty ? '📝' : noteGroup.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      noteGroup.groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${noteGroup.notes.length} Catatan',
                        style: TextStyle(
                          fontSize: 11,
                          color: _themeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
      ),

      // IMPLEMENTASI LAYOUT FOOTER BANNER ADMOB MENGGUNAKAN WIDGET ADAPTIVE YANG BARU
      bottomNavigationBar: const AdaptiveBannerAd(adKey: 'note_hub_banner'),
    );
  }
}
