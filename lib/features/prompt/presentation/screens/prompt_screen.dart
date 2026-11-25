// lib/features/prompt/presentation/screens/prompt_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rutinitasku/core/services/storage_service.dart';
import 'package:rutinitasku/core/presentation/widgets/adaptive_banner_ad.dart'; // <--- IMPORT WIDGET ADMOB BARU DARI CORE[cite: 2]
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/utils/atomic_write_helper.dart'; // <--- TAMBAHKAN IMPORT HELPER ATOMIC WRITE
import '../../data/models/prompt_model.dart';
import '../controllers/prompt_controller.dart';
import 'prompt_detail_screen.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  late final PromptController _controller;
  final StorageService _storageService = StorageService();

  // STATE BARU: Kontrol untuk menampilkan atau menyembunyikan kategori/grup tersembunyi
  bool _showHiddenSection = false;
  bool _isGlobalEncryptionEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = PromptController();
    _checkEncryptionStatus();

    // PERBAIKAN 1: Berikan jeda mikro asinkron (150ms) setelah frame utama dirender.
    // Menghilangkan lag saat pertama kali masuk halaman karena memisahkan beban rendering transisi dengan dekripsi I/O.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _controller.loadAllPrompts(context);
        }
      });
    });
  }

  // METHOD BARU: Mengambil konfigurasi status enkripsi master sistem dari storage
  Future<void> _checkEncryptionStatus() async {
    bool isEncrypted = await _storageService.isEncryptionEnabled();
    if (mounted) {
      setState(() {
        _isGlobalEncryptionEnabled = isEncrypted;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FITUR BARU: Dialog Input Kata Sandi untuk Dekripsi Manual Berkas Prompt Rusak ---
  void _showManualDecryptDialog(PromptGroup corruptedGroup) {
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
            Text('Dekripsi Berkas Prompt'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan password yang sesuai untuk membuka file "${corruptedGroup.title}.json":',
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

              try {
                // Potong prefix mock ID untuk mendapatkan nama file asli
                final String originalFileName = corruptedGroup.id.replaceFirst(
                  RegExp(r'CORRUPTED_\d+_'),
                  '',
                );

                // PERBAIKAN UTAMA 1: Menggunakan getSpecificPromptFile untuk mencari di folder 'prompts'
                final File targetFile = await _storageService
                    .getSpecificPromptFile(
                      await _storageService.getBaseDirSetting(),
                      originalFileName,
                    );

                if (!await targetFile.exists()) {
                  throw Exception(
                    "Berkas fisik tidak ditemukan di penyimpanan.\nPath: ${targetFile.path}",
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
                PromptGroup decryptedGroup = PromptGroup.fromJson(parsedJson);

                // Langkah 3: Tulis ulang konten menggunakan fungsi terenkripsi internal controller
                await _controller.saveGroupDataToFile(decryptedGroup);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berkas "${decryptedGroup.title}" berhasil didekripsi and disinkronkan ke sistem!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint("Gagal melakukan dekripsi manual berkas prompt: $e");
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Gagal mendekripsi! Password salah atau struktur file korup/tidak ditemukan.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } finally {
                // PERBAIKAN UTAMA 2: Eksekusi pemuatan di luar setState (Aman dari Exception Future)
                if (mounted) {
                  _controller.loadAllPrompts(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
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
  void _showEditRawJsonDialog(PromptGroup group) async {
    String targetId = group.id;
    bool isCorrupted = targetId.startsWith("CORRUPTED_");

    if (isCorrupted) {
      targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
    }

    final baseDir = await _storageService.getBaseDirSetting();
    File targetFile = await _storageService.getSpecificPromptFile(
      baseDir,
      targetId,
    );

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
          debugPrint("Dekripsi gagal untuk preview raw JSON prompt: $e");
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

              // === PERBAIKAN: PENERAPAN STRUKTUR ATOMIC WRITE PADA PENYIMPANAN RAW EDIT JSON ===[cite: 3]
              try {
                bool isEncrypted = await _storageService.isEncryptionEnabled();
                String? password = await _storageService
                    .getEncryptionPassword();
                String finalContent = newContent;

                if (isEncrypted && password != null) {
                  final trimmed = newContent.trim();
                  // Jika data merupakan format plain JSON baru yang polos, enkripsi kembali sebelum ditulis[cite: 3]
                  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
                    finalContent = CryptoHelper.encrypt(newContent, password);
                  }
                }

                // Gunakan helper atomic write terpusat agar penulisan file fisik aman dari korupsi data[cite: 3]
                await AtomicWriteHelper.writeSafe(
                  targetFile: targetFile,
                  content: finalContent,
                );

                if (mounted) {
                  Navigator.pop(context); // Tutup dialog editor
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'File JSON berhasil diperbarui secara aman!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _controller.loadAllPrompts(context); // Refresh UI
                }
              } catch (err) {
                debugPrint(
                  "Gagal mengamankan penyimpanan kustom raw JSON via Atomic Write: $err",
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menyimpan perubahan berkas! Detail: $err',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
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

  void _showSequentialAddDialog() {
    final sectionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langkah 1: Buat Seksi Kategori'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: sectionController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama Seksi Utama',
              hintText: 'Misal: CODING, COPYWRITING, ARSIP...',
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
                final newSectionName = sectionController.text
                    .trim()
                    .toUpperCase();

                if (!_controller.localEmptySections.contains(newSectionName)) {
                  _controller.addSection(newSectionName, context);
                }

                Navigator.pop(context);
                _showAddGroupDialog(defaultSection: newSectionName);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text(
              'Lanjut ke Grup ➔',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSectionDialog() {
    final sectionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Kategori Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            hintText: 'Nama Seksi Utama (Misal: CODING, COPYWRITING)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (sectionController.text.trim().isNotEmpty) {
                _controller.addSection(sectionController.text, context);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditSectionNameDialog(String oldName) {
    final textController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Nama Seksi "$oldName"'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.editSectionName(
                oldName,
                textController.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(String sectionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Seksi "$sectionName"?'),
        content: Text(
          'Tindakan ini akan menghapus seluruh grup prompt yang ada di dalam seksi "$sectionName". Perubahan ini permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _controller.deleteSection(sectionName, context);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog({String? defaultSection}) {
    final titleController = TextEditingController();
    final iconController = TextEditingController(text: '🤖');
    final sectionController = TextEditingController(text: defaultSection ?? '');

    final bool isSequentialStep =
        defaultSection != null && _controller.promptGroups.isEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isSequentialStep
              ? 'Langkah 2: Buat Grup di $defaultSection'
              : 'Tambah Group Prompt',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Group (e.g. Copywriting, Coding)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Icon Emoji'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Nama Seksi / Kategori',
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
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              _controller.addPromptGroup(
                title: titleController.text,
                icon: iconController.text,
                section: sectionController.text,
                context: context,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: Text(isSequentialStep ? 'Simpan & Selesai' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(PromptGroup group) {
    final titleController = TextEditingController(text: group.title);
    final iconController = TextEditingController(text: group.icon);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama & Ikon Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Group'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Ikon Emoji'),
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
              if (titleController.text.trim().isEmpty) return;
              _controller.editGroup(
                group,
                titleController.text,
                iconController.text,
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showMoveSectionDialog(PromptGroup group) {
    final Map<String, List<PromptGroup>> sectionsMap = {};
    for (var g in _controller.promptGroups) {
      final name = g.sectionName.isEmpty
          ? 'GENERAL'
          : g.sectionName.toUpperCase();
      sectionsMap.putIfAbsent(name, () => []);
    }
    for (var sec in _controller.localEmptySections) {
      sectionsMap.putIfAbsent(sec, () => []);
    }
    final List<String> availableSections = sectionsMap.keys.toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pindahkan Group ke Seksi Lain'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSections.length,
            itemBuilder: (context, index) {
              final secName = availableSections[index];
              return ListTile(
                title: Text(secName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _controller.moveGroupToSection(group, secName, context);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteGroupItemDialog(PromptGroup group) {
    final bool isCorrupted = group.id.startsWith("CORRUPTED_");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isCorrupted
              ? 'Hapus Berkas Rusak "${group.title}"?'
              : 'Hapus Group "${group.title}"?',
        ),
        content: Text(
          isCorrupted
              ? 'Apakah Anda yakin ingin menghapus file biner yang rusak ini secara permanen dari penyimpanan lokal?'
              : 'Tindakan ini akan menghapus group ini secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _controller.deleteGroupItem(group, context);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final Map<String, List<PromptGroup>> sectionsMap = {};
        final Map<String, List<PromptGroup>> hiddenSectionsMap = {};
        final bool isSearching = _controller.searchQuery.isNotEmpty;

        for (var group in _controller.filteredPromptGroups) {
          final secName = group.sectionName.isEmpty
              ? 'GENERAL'
              : group.sectionName.toUpperCase();

          if (group.isHidden) {
            if (!hiddenSectionsMap.containsKey(secName)) {
              hiddenSectionsMap[secName] = [];
            }
            hiddenSectionsMap[secName]!.add(group);
          } else {
            if (!sectionsMap.containsKey(secName)) {
              sectionsMap[secName] = [];
            }
            sectionsMap[secName]!.add(group);
          }
        }

        if (!isSearching) {
          for (var sec in _controller.localEmptySections) {
            sectionsMap.putIfAbsent(sec, () => []);
          }
        }

        final sectionKeys = sectionsMap.keys.toList();
        if (sectionKeys.contains('GENERAL')) {
          sectionKeys.remove('GENERAL');
          sectionKeys.insert(0, 'GENERAL');
        }

        if (!_showHiddenSection) {
          sectionKeys.removeWhere((k) => _controller.isSectionHidden(k));
        }

        final int visibleKeysCount = sectionKeys.length;

        if (_showHiddenSection && hiddenSectionsMap.isNotEmpty) {
          hiddenSectionsMap.forEach((key, groupsList) {
            if (groupsList.isNotEmpty) {
              String hiddenKey = '${key}_hidden_key';
              sectionKeys.add(hiddenKey);

              if (_controller.searchQuery.isEmpty) {
                sectionsMap[hiddenKey] = groupsList;
              } else {
                sectionsMap[hiddenKey] = groupsList.where((group) {
                  return group.title.toLowerCase().contains(
                    _controller.searchQuery,
                  );
                }).toList();
              }
            }
          });
        }

        return Scaffold(
          body: GroupedSectionLayout<PromptGroup>(
            title: 'Prompt Groups',
            forceShowMenu: true,
            drawer: const DrawerMenu(isPromptActive: true),
            floatingActionButton: null,
            isLoading: _controller.isLoading,
            isEmpty: sectionKeys.isEmpty,
            emptyStateView: UniversalEmptyState(
              icon: Icons.psychology_alt_rounded,
              title: 'Kategori Prompt Masih Kosong',
              description: isSearching
                  ? 'Tidak ada kategori atau grup seksi prompt yang cocok dengan kata kunci "${_controller.searchQuery}" Anda.'
                  : 'Belum ada seksi kategori atau grup penampung instruksi AI yang terdaftar. Yuk, buat Seksi Utama sekaligus Grup Prompt pertama Anda sekarang juga!',
              buttonLabel: isSearching
                  ? 'Reset Pencarian'
                  : 'Buat Seksi & Grup Prompt',
              themeColor: Colors.indigo,
              onPressed: () {
                if (isSearching) {
                  _controller.updateSearchQuery('');
                } else {
                  _showSequentialAddDialog();
                }
              },
            ),
            appBarTrailingAction: _isGlobalEncryptionEnabled
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Tooltip(
                      message: 'Enkripsi Aktif',
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
            isSelectMode: false,
            selectedItemsCount: 0,
            onClearSelection: () {},
            enableSearch: true,
            enableMultiSelect: false,
            onSearchChanged: (query) {
              _controller.updateSearchQuery(query);
            },
            onAddPressed: () {
              _showAddSectionDialog();
            },
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
            sectionKeys: sectionKeys,
            groupedItems: sectionsMap,
            isSectionCollapsed: (key) => _controller.isSectionCollapsed(key),
            sectionHeaderBuilder:
                (context, sIndex, sectionName, isLayoutEditMode) {
                  if (sIndex >= visibleKeysCount) {
                    String originalName = sectionName.replaceAll(
                      '_hidden_key',
                      '',
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sIndex == visibleKeysCount)
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

                  if (sIndex >= sectionKeys.length)
                    return const SizedBox.shrink();

                  return InteractiveSectionHeader(
                    sectionName: sectionName,
                    themeColor: Colors.indigo[900]!,
                    isEditMode: isLayoutEditMode
                        ? true
                        : _controller.isSectionEditMode,
                    isCollapsed: _controller.isSectionCollapsed(sectionName),
                    onToggleCollapse: () =>
                        _controller.toggleSectionCollapse(sectionName),
                    isHidden: _controller.isSectionHidden(sectionName),
                    onToggleVisibility: () =>
                        _controller.toggleSectionHidden(sectionName),
                    isUpperCase: false,
                    isFirst: isSearching ? true : (sIndex == 0),
                    isLast: isSearching
                        ? true
                        : (sIndex == sectionKeys.length - 1),
                    onToggleEdit: () {
                      if (isSearching) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Matikan pencarian untuk mengubah struktur seksi!',
                            ),
                          ),
                        );
                        return;
                      }
                      _controller.toggleSectionEditMode();
                    },
                    onMoveUp: isSearching
                        ? () {}
                        : () =>
                              _controller.moveSectionOrder(sIndex, -1, context),
                    onMoveDown: isSearching
                        ? () {}
                        : () =>
                              _controller.moveSectionOrder(sIndex, 1, context),
                    onEditName: () => _showEditSectionNameDialog(sectionName),
                    onDelete: () => _showDeleteSectionDialog(sectionName),
                    onAddItem: () =>
                        _showAddGroupDialog(defaultSection: sectionName),
                  );
                },
            gridItemBuilder:
                (context, promptGroup, index, items, isLayoutEditMode) {
                  if (index >= items.length) return const SizedBox.shrink();

                  final bool isCorrupted = promptGroup.id.startsWith(
                    "CORRUPTED_",
                  );

                  if (isCorrupted) {
                    return InteractiveGridCard(
                      themeColor: Colors.redAccent,
                      isEditMode: isLayoutEditMode
                          ? true
                          : _controller.isCardEditMode,
                      isHiddenStyle: false,
                      isFirst: isSearching ? true : (index == 0),
                      isLast: isSearching ? true : (index == items.length - 1),
                      onTap: () => _showManualDecryptDialog(promptGroup),
                      onLongPress: () {
                        _controller.toggleCardEditMode();
                      },
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
                              Icon(
                                Icons.data_object,
                                size: 18,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Edit File .json',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete_corrupted',
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
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onPopupSelected: (value) async {
                        if (value == 'decrypt') {
                          _showManualDecryptDialog(promptGroup);
                        } else if (value == 'edit_raw_json') {
                          _showEditRawJsonDialog(promptGroup);
                        } else if (value == 'delete_corrupted') {
                          _showDeleteGroupItemDialog(promptGroup);
                        }
                      },
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            promptGroup.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            promptGroup.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
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
                    themeColor: Colors.indigo,
                    isEditMode: isLayoutEditMode
                        ? true
                        : _controller.isCardEditMode,
                    isHiddenStyle: promptGroup.isHidden,
                    isFirst: isSearching ? true : (index == 0),
                    isLast: isSearching ? true : (index == items.length - 1),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PromptDetailScreen(promptGroup: promptGroup),
                        ),
                      ).then((_) {
                        Future.delayed(const Duration(milliseconds: 150), () {
                          if (mounted) {
                            _controller.loadAllPrompts(context);
                          }
                        });
                      });
                    },
                    onLongPress: () {
                      _controller.toggleCardEditMode();
                    },
                    onMoveLeft: () {
                      if (index > 0) {
                        _controller.moveGroupOrderHorizontal(items, index, -1);
                      }
                    },
                    onMoveRight: () {
                      if (index < items.length - 1) {
                        _controller.moveGroupOrderHorizontal(items, index, 1);
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
                            Icon(
                              Icons.data_object,
                              size: 18,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Edit File .json',
                              style: TextStyle(fontSize: 13),
                            ),
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
                            Text(
                              'Pindahkan Seksi',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_visibility',
                        child: Row(
                          children: [
                            Icon(
                              promptGroup.isHidden
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              promptGroup.isHidden
                                  ? 'Tampilkan Group'
                                  : 'Sembunyikan Group',
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
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Hapus Group',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onPopupSelected: (value) async {
                      if (value == 'edit') {
                        _showEditGroupDialog(promptGroup);
                      } else if (value == 'edit_raw_json') {
                        _showEditRawJsonDialog(promptGroup);
                      } else if (value == 'move_section') {
                        _showMoveSectionDialog(promptGroup);
                      } else if (value == 'toggle_visibility') {
                        await _controller.toggleGroupVisibility(
                          promptGroup,
                          context,
                        );
                      } else if (value == 'delete') {
                        _showDeleteGroupItemDialog(promptGroup);
                      }
                    },
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          promptGroup.icon,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          promptGroup.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${promptGroup.prompts.length} Item',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
          ),
          // MENGGUNAKAN WIDGET KUSTOM ADMOB YANG BARU DAN MODULAR PADA FOOTER LAYOUT[cite: 2]
          bottomNavigationBar: const AdaptiveBannerAd(
            adKey: 'prompt_hub_banner',
          ),
        );
      },
    );
  }
}

class ListBehaviorBuilder extends StatelessWidget {
  final PromptController controller;
  final WidgetBuilder builder;

  const ListBehaviorBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) => builder(context),
    );
  }
}
