// lib/features/prompt/presentation/screens/prompt_screen.dart
import 'dart:convert';
import 'dart:io'; // Ditambahkan untuk mengecek platform
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob
import 'package:rutinitasku/core/services/storage_service.dart'; // <--- TAMBAHKAN IMPORT INI
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart';
import '../../../../core/utils/crypto_helper.dart'; // <--- TAMBAHKAN IMPORT CRYPTO HELPER
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
  final StorageService _storageService =
      StorageService(); // <--- TAMBAHKAN INSTANCE INI

  // STATE BARU: Kontrol untuk menampilkan atau menyembunyikan kategori/grup tersembunyi
  bool _showHiddenSection = false;
  bool _isGlobalEncryptionEnabled =
      false; // <--- TAMBAHKAN VARIABEL STATE BARU INI

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
        return 'ca-app-pub-5320800343545863/7705140325';
      }
    }
    return ''; // Kosongkan jika berjalan di Desktop (Windows/Linux/macOS) agar tidak crash
  }

  @override
  void initState() {
    super.initState();
    _controller = PromptController();
    _checkEncryptionStatus(); // <--- PANGGIL METHOD PENGECEKAN DI SINI

    // PERBAIKAN 1: Berikan jeda mikro asinkron (150ms) setelah frame utama dirender.
    // Menghilangkan lag saat pertama kali masuk halaman karena memisahkan beban rendering transisi dengan dekripsi I/O.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _controller.loadAllPrompts(context);
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
          debugPrint('Iklan Banner Prompt gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
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
    _bannerAd
        ?.dispose(); // Hancurkan objek iklan dari memori saat halaman ditutup untuk mencegah kebocoran memori
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

              setState(
                () => _controller.loadAllPrompts(context),
              ); // Membuka status loading awal

              try {
                // Potong prefix mock ID untuk mendapatkan nama file asli
                final String originalFileName = corruptedGroup.id.replaceFirst(
                  RegExp(r'CORRUPTED_\d+_'),
                  '',
                );

                // Dapatkan jalur (path) akurat file melalui StorageService
                final File targetFile = await _storageService
                    .getSpecificGroupFile(
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
                      'Berkas "${decryptedGroup.title}" berhasil didekripsi dan disinkronkan ke sistem!',
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

  // --- (Semua sisa fungsi dialog operasional internal seperti _showSequentialAddDialog, _showAddSectionDialog,
  // _showEditSectionNameDialog, _showDeleteSectionDialog, _showAddGroupDialog, _showEditGroupDialog,
  // _showMoveSectionDialog, dan _showDeleteGroupItemDialog dibiarkan utuh tanpa modifikasi) ---
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

        // Dibungkus Scaffold terluar agar properti bottomNavigationBar bisa merender layout iklan
        return Scaffold(
          body: GroupedSectionLayout<PromptGroup>(
            title: 'Prompt Groups',
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

                  // --- FIX: AKTIFKAN MODUL DIALOG DEKRIPSI UNTUK CARD MERAH ---
                  if (isCorrupted) {
                    return InteractiveGridCard(
                      themeColor: Colors.redAccent,
                      isEditMode: isLayoutEditMode
                          ? true
                          : _controller.isCardEditMode,
                      isHiddenStyle: false,
                      isFirst: isSearching ? true : (index == 0),
                      isLast: isSearching ? true : (index == items.length - 1),
                      onTap: () => _showManualDecryptDialog(
                        promptGroup,
                      ), // <--- SEJAJAR DENGAN DAILY
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
