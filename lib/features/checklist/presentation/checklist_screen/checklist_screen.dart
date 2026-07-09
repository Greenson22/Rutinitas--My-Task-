// lib/features/daily/presentation/screens/daily_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Ditambahkan untuk mendeteksi kDebugMode
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Ditambahkan untuk SDK AdMob

import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../../core/presentation/widgets/grouped_section_layout.dart';
import '../../../../core/presentation/widgets/interactive_grid_card.dart';
import '../../../../core/presentation/widgets/interactive_section_header.dart';
import '../../../../core/presentation/widgets/universal_empty_state.dart'; // Using Universal Widget from Core
import '../../../../core/utils/crypto_helper.dart'; // Import CryptoHelper untuk Dekripsi Manual
import '../../../../core/services/storage_service.dart'; // <--- IMPORT BARU KUNCI PENYIMPANAN
import '../../data/models/daily_model.dart';
import 'controllers/daily_controller.dart';
import '../checklist_detail_screen/checklist_detail_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  late DailyController _controller;
  final Color _themeColor = Colors.indigo; // Definisi warna tema dasar indigo

  // Variabel untuk manajemen Banner AdMob
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Getter adaptif untuk menentukan Ad Unit ID Iklan Banner
  String get adUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/6300978111';
      } else {
        return 'ca-app-pub-5320800343545863/2005101404';
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _controller = DailyController();
    _controller.addListener(_onControllerNotify);
    _controller.loadGroupsData();

    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (adUnitId.isEmpty) return;
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
          debugPrint('Iklan Banner Checklist gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  void _onControllerNotify() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerNotify);
    _controller.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _showManualDecryptDialog(ChecklistGroup corruptedGroup) {
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
            Text('Dekripsi Berkas Checklist'),
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
              setState(() => _controller.isLoading = true);

              try {
                final String originalFileName = corruptedGroup.id.replaceFirst(
                  RegExp(r'CORRUPTED_\d+_'),
                  '',
                );

                final StorageService storageService = StorageService();
                final File targetFile = await storageService
                    .getSpecificGroupFile(
                      _controller.selectedBaseDir,
                      originalFileName,
                    );

                if (!await targetFile.exists()) {
                  throw Exception(
                    "Berkas fisik tidak ditemukan di penyimpanan.\nPath: ${targetFile.path}",
                  );
                }

                String rawContent = await targetFile.readAsString();

                String decryptedContent = CryptoHelper.decrypt(
                  rawContent.trim(),
                  inputPassword,
                );

                final Map<String, dynamic> parsedJson = jsonDecode(
                  decryptedContent,
                );

                ChecklistGroup decryptedGroup = ChecklistGroup.fromJson(
                  parsedJson,
                );

                // === PERBAIKAN: Secara logis jika dia sengaja didekripsi manual, itu berarti isEncrypted sebelumnya ===
                decryptedGroup.isEncrypted = true;

                await _controller.saveGroupDataToFile(decryptedGroup);

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Berkas "${decryptedGroup.groupName}" berhasil didekripsi!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint(
                  "Gagal melakukan dekripsi manual berkas checklist: $e",
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Gagal mendekripsi! Password salah atau struktur file korup.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } finally {
                _controller.loadGroupsData();
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

  void _showEditRawJsonDialog(ChecklistGroup group) async {
    final storageService = StorageService();
    String targetId = group.id;
    bool isCorrupted = targetId.startsWith("CORRUPTED_");

    if (isCorrupted) {
      targetId = targetId.replaceFirst(RegExp(r'CORRUPTED_\d+_'), '');
    }

    File targetFile = await storageService.getSpecificGroupFile(
      _controller.selectedBaseDir,
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
    String? decryptionError;

    if (!displayContent.startsWith('{') && !displayContent.startsWith('[')) {
      String? password = await storageService.getEncryptionPassword();
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

              // MODIFIKASI: Simpan via _controller agar status enkripsi konsisten dipertahankan
              try {
                final parsed = jsonDecode(newContent);
                parsed['id'] = targetId;
                ChecklistGroup updatedGroup = ChecklistGroup.fromJson(parsed);
                updatedGroup.isEncrypted = group.isEncrypted || isCorrupted;
                await _controller.saveGroupDataToFile(updatedGroup);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File JSON berhasil diperbarui!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _controller.loadGroupsData();
                }
              } catch (e) {
                // Fallback to raw text writing for completely broken syntax save override
                await storageService.saveJsonData(targetFile, newContent);
                if (mounted) {
                  Navigator.pop(context);
                  _controller.loadGroupsData();
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
              hintText: 'Contoh: PRIORITAS, HARIAN, KULIAH...',
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
                final String namaSeksiBaru = sectionController.text.trim();
                _controller.addLocalMainSection(namaSeksiBaru);

                Navigator.pop(context);
                _showAddGroupDialogAtSection(namaSeksiBaru);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text(
              'Lanjut ke Group >',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMainSectionDialog() {
    final sectionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Seksi Kategori Baru'),
        content: TextField(
          controller: sectionController,
          decoration: const InputDecoration(
            hintText: 'Nama Seksi Utama (Misal: PRIORITAS)...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final String namaSeksiBaru = sectionController.text.trim();
              if (namaSeksiBaru.isNotEmpty) {
                _controller.addLocalMainSection(namaSeksiBaru);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seksi "$namaSeksiBaru" berhasil dibuat! Tekan tombol + di kanannya untuk menambah group.',
                    ),
                    backgroundColor: _themeColor,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialogAtSection(String targetMainSection) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📁');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _controller.allGroupRaw.isEmpty
              ? 'Langkah 2: Buat Group Baru di $targetMainSection'
              : 'Buat Group Baru di $targetMainSection',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Group Checklist',
                  hintText: 'Contoh: Pekerjaan, Olahraga, Belajar...',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama group tidak boleh kosong'
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
                await _controller.createGroupAtSection(
                  nameController.text.trim(),
                  iconController.text.trim(),
                  targetMainSection,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            child: const Text(
              'Buat Group & Selesai',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(ChecklistGroup group) {
    final nameController = TextEditingController(text: group.groupName);
    final iconController = TextEditingController(text: group.icon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Checklist Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Group'),
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
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _controller.updateGroup(
                  group,
                  nameController.text.trim(),
                  iconController.text.trim(),
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteGroup(ChecklistGroup group) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              group.id.startsWith("CORRUPTED_")
                  ? 'Hapus Berkas Rusak?'
                  : 'Hapus Checklist Group?',
            ),
            content: Text(
              group.id.startsWith("CORRUPTED_")
                  ? 'Apakah Anda yakin ingin menghapus berkas rusak "${group.groupName}" secara permanen?'
                  : 'Apakah Anda yakin ingin menghapus Group "${group.groupName}" secara permanen beserta seluruh isinya?',
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
        ) ??
        false;

    if (confirm) {
      await _controller.deleteGroup(group);
    }
  }

  void _showMoveSectionDialog(ChecklistGroup group) {
    List<String> availableSections = _controller.groupedVisibleGroup.keys
        .toList();

    // FITUR ADAPTASI DARI NOTES: Tambahkan seksi dari penampung hidden jika belum terdaftar
    for (var key in _controller.groupedHiddenGroup.keys) {
      if (!availableSections.contains(key)) {
        availableSections.add(key);
      }
    }

    if (!availableSections.contains("Lainnya")) {
      availableSections.add("Lainnya");
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
                final bool isCurrentSection =
                    group.sectionCategory == sectionName;

                return ListTile(
                  title: Text(sectionName.toUpperCase()),
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
                          // PERBAIKAN SEPERTI NOTES: Dapatkan referensi messenger sebelum pop
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);

                          await _controller.moveGroupToAnotherSection(
                            group,
                            sectionName,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Group "${group.groupName}" berhasil dipindahkan ke seksi "$sectionName"',
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

  void _editMainSectionName(String oldSectionName) {
    final editController = TextEditingController(text: oldSectionName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Seksi Kategori'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(labelText: 'Nama Seksi Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final String newSectionName = editController.text.trim();
              if (newSectionName.isNotEmpty &&
                  newSectionName != oldSectionName) {
                await _controller.updateMainSectionName(
                  oldSectionName,
                  newSectionName,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteMainSection(String sectionName) async {
    final listGroupDiSeksiIni =
        _controller.groupedVisibleGroup[sectionName] ?? [];

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Seksi Kategori?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus seksi "$sectionName"?\n\n'
              'Peringatan: Tindakan ini juga akan menghapus ${listGroupDiSeksiIni.length} Hub di dalamnya secara permanen!',
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
        ) ??
        false;

    if (confirm) {
      await _controller.deleteMainSection(sectionName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allKeys = _controller.groupedVisibleGroup.keys.toList();
    final Map<String, List<ChecklistGroup>> allItems = Map.from(
      _controller.groupedVisibleGroup,
    );
    final int visibleKeysCount = allKeys.length;

    if (_controller.hiddenGroup.isNotEmpty && _controller.showHiddenSection) {
      for (var entry in _controller.groupedHiddenGroup.entries) {
        final hiddenKey = '${entry.key}_hidden_key';
        allKeys.add(hiddenKey);
        allItems[hiddenKey] = entry.value;
      }
    }

    return Scaffold(
      body: GroupedSectionLayout<ChecklistGroup>(
        title: 'Checklist Groups',
        drawer: const DrawerMenu(isDailyActive: true),
        isLoading: _controller.isLoading,
        isEmpty: _controller.allGroupRaw.isEmpty && allKeys.isEmpty,
        emptyStateView: UniversalEmptyState(
          icon: Icons.dashboard_customize_rounded,
          title: 'Checklist Groups Masih Kosong',
          description:
              'Belum ada grup tugas harian yang terdaftar. Yuk, buat Seksi Utama sekaligus Group Checklist pertama Anda sekarang juga!',
          buttonLabel: 'Buat Seksi & Group Checklist',
          themeColor: _themeColor,
          onPressed: _showSequentialAddDialog,
        ),
        sectionKeys: allKeys,
        groupedItems: allItems,
        isSelectMode: false,
        selectedItemsCount: 0,
        onClearSelection: () {},
        enableSearch: true,
        enableMultiSelect: false,
        onSearchChanged: _controller.updateSearchQuery,
        onAddPressed: _showAddMainSectionDialog,
        appBarTrailingAction: _controller.isGlobalEncryptionEnabled
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Tooltip(
                  message: 'Enkripsi Tersedia (Kata Sandi Diatur)',
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
        additionalAction: IconButton(
          icon: Icon(
            _controller.showHiddenSection
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.white,
          ),
          tooltip: _controller.showHiddenSection
              ? 'Sembunyikan Group Nonaktif'
              : 'Tampilkan Group Tersembunyi',
          onPressed: _controller.toggleShowHiddenSection,
        ),
        sectionHeaderBuilder: (context, index, sectionKey, isLayoutEditMode) {
          if (index >= visibleKeysCount) {
            String originalName = sectionKey.replaceAll('_hidden_key', '');
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
            sectionName: sectionKey,
            themeColor: Colors.indigo[900]!,
            isEditMode: isLayoutEditMode ? true : _controller.isSectionEditMode,
            isUpperCase: false,
            isFirst: index == 0,
            isLast: index == visibleKeysCount - 1,
            onToggleEdit: _controller.toggleSectionEditMode,

            // --- PERBAIKAN: Hubungkan tombol aksi panah dengan Controller ---
            onMoveUp: () => _controller.moveMainSectionOrder(index, -1),
            onMoveDown: () => _controller.moveMainSectionOrder(index, 1),

            // ----------------------------------------------------------------
            onEditName: () => _editMainSectionName(sectionKey),
            onDelete: () => _deleteMainSection(sectionKey),
            onAddItem: () => _showAddGroupDialogAtSection(sectionKey),
          );
        },
        gridItemBuilder: (context, group, index, sectionItems, isLayoutEditMode) {
          final bool isCorrupted = group.id.startsWith("CORRUPTED_");

          if (isCorrupted) {
            return InteractiveGridCard(
              themeColor: Colors.redAccent,
              isEditMode: isLayoutEditMode ? true : _controller.isPageEditMode,
              isHiddenStyle: false,
              isFirst: index == 0,
              isLast: index == sectionItems.length - 1,
              onTap: () => _showManualDecryptDialog(group),
              onLongPress: _controller.togglePageEditMode,
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
                      Text('Dekripsi Manual', style: TextStyle(fontSize: 13)),
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
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
                  _showManualDecryptDialog(group);
                } else if (value == 'edit_raw_json') {
                  _showEditRawJsonDialog(group);
                } else if (value == 'delete') {
                  _deleteGroup(group);
                }
              },
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(group.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    group.groupName,
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
                      'Terkunci / Korup',
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

          int totalItems = 0;
          for (var section in group.allList) {
            totalItems += section.items.length;
          }

          return InteractiveGridCard(
            themeColor: _themeColor, // Indigo
            isEditMode: isLayoutEditMode ? true : _controller.isPageEditMode,
            isHiddenStyle: group.isHidden,
            isFirst: index == 0,
            isLast: index == sectionItems.length - 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChecklistDetailScreen(
                    group: group,
                    baseDir: _controller.selectedBaseDir,
                    allAvailableGroups: _controller.allGroupRaw,
                  ),
                ),
              ).then((_) => _controller.loadGroupsData());
            },
            onLongPress: _controller.togglePageEditMode,
            onMoveLeft: () =>
                _controller.moveGroupOrder(sectionItems, index, -1),
            onMoveRight: () =>
                _controller.moveGroupOrder(sectionItems, index, 1),
            popupMenuItems: [
              // --- ITEM MENU BARU: ENKRIPSI ---
              PopupMenuItem(
                value: 'toggle_encryption',
                child: Row(
                  children: [
                    Icon(
                      group.isEncrypted
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      size: 18,
                      color: group.isEncrypted ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.isEncrypted ? 'Buka Enkripsi' : 'Enkripsi Group',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [
                    Icon(Icons.edit, size: 18, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Ubah Nama & Ikon', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit_raw_json',
                child: Row(
                  children: const [
                    Icon(Icons.data_object, size: 18, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Edit File .json', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'move_section',
                child: Row(
                  children: const [
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
                      group.isHidden ? Icons.visibility : Icons.visibility_off,
                      size: 18,
                      color: Colors.blueGrey[700],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.isHidden ? 'Tampilkan Group' : 'Sembunyikan Group',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Hapus Group',
                      style: TextStyle(fontSize: 13, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
            onPopupSelected: (value) async {
              if (value == 'toggle_encryption') {
                try {
                  await _controller.toggleGroupEncryption(group);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          group.isEncrypted
                              ? 'Group berhasil dienkripsi!'
                              : 'Enkripsi group dilepas!',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Setel kata sandi di Pengaturan Data Center terlebih dahulu!',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              } else if (value == 'edit') {
                _showEditGroupDialog(group);
              } else if (value == 'edit_raw_json') {
                _showEditRawJsonDialog(group);
              } else if (value == 'move_section') {
                _showMoveSectionDialog(group);
              } else if (value == 'toggle_visibility') {
                await _controller.toggleGroupVisibility(group);
              } else if (value == 'delete') {
                _deleteGroup(group);
              }
            },
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  group.icon,
                  style: TextStyle(
                    fontSize: 28,
                    color: group.isHidden ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.groupName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: group.isHidden ? Colors.grey : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    // --- INDIKATOR GEMBOK ENKRIPSI ---
                    if (group.isEncrypted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 12,
                          color: Colors.green,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (group.isHidden ? Colors.grey : _themeColor)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${group.allList.length} Seksi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: group.isHidden
                              ? Colors.grey[700]
                              : Colors.indigo[900]!,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (group.isHidden ? Colors.grey : Colors.indigo[800]!)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$totalItems Item',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: group.isHidden
                              ? Colors.grey[700]
                              : Colors.indigo[900]!,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
