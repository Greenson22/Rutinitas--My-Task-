// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../data/models/daily_model.dart';
import 'checklist_detail_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final StorageService _storageService = StorageService();
  List<ChecklistGroup> _allGroupRaw = [];
  List<ChecklistGroup> _hiddenGroup = [];

  String _selectedBaseDir = 'Documents';
  bool _isLoading = true;

  bool _isPageEditMode = false;
  bool _showHiddenSection = false;

  final Map<String, List<ChecklistGroup>> _groupedVisibleGroup = {};
  final Map<String, List<ChecklistGroup>> _groupedHiddenGroup = {};
  bool _isSectionEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadGroupsData();
  }

  Future<void> _loadGroupsData() async {
    setState(() => _isLoading = true);
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      List<File> groupFiles = await _storageService.getAllChecklistGroups(
        _selectedBaseDir,
      );

      // SOLUSI PERMANEN LINUX: Urutkan file berdasarkan nama file secara alfabetis/numerik.
      // Dengan cara ini, prefix angka seperti 0_, 1_, 2_ akan memaksa Linux membaca sesuai urutan kustom kita.
      groupFiles.sort((a, b) {
        String nameA = a.path.split('/').last;
        String nameB = b.path.split('/').last;
        return nameA.compareTo(nameB);
      });

      List<ChecklistGroup> loadedGroups = [];
      for (var file in groupFiles) {
        String jsonString = await file.readAsString();
        final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
        loadedGroups.add(ChecklistGroup.fromJson(parsedMap));
      }

      _allGroupRaw = loadedGroups;
      _processGroupsDisplay();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading groups: $e");
    }
  }

  void _processGroupsDisplay() {
    setState(() {
      // 1. Saring data mentah group menjadi list terlihat dan tersembunyi
      final visibleList = _allGroupRaw
          .where((group) => !group.isHidden)
          .toList();
      final hiddenList = _allGroupRaw.where((group) => group.isHidden).toList();

      // 2. Bersihkan penampung grup lama
      _groupedVisibleGroup.clear();
      _groupedHiddenGroup.clear();

      // 3. Kelompokkan Hub Terlihat berdasarkan Kategori Seksi Utama
      for (var group in visibleList) {
        String kategori = group.kategoriSeksi.trim().isEmpty
            ? "Lainnya"
            : group.kategoriSeksi;
        _groupedVisibleGroup.putIfAbsent(kategori, () => []);
        _groupedVisibleGroup[kategori]!.add(group);
      }

      // 4. Kelompokkan Group Tersembunyi berdasarkan Kategori Seksi Utama
      for (var group in hiddenList) {
        String kategori = group.kategoriSeksi.trim().isEmpty
            ? "Lainnya"
            : group.kategoriSeksi;
        _groupedHiddenGroup.putIfAbsent(kategori, () => []);
        _groupedHiddenGroup[kategori]!.add(group);
      }

      _hiddenGroup = hiddenList;
      _isLoading = false;
    });
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
                setState(() {
                  // Menambahkan seksi kosong baru ke dalam map tampilan produktif produktif
                  _groupedVisibleGroup.putIfAbsent(namaSeksiBaru, () => []);
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Seksi "$namaSeksiBaru" berhasil dibuat! Tekan tombol + di kanannya untuk menambah group.',
                    ),
                    backgroundColor: Colors.teal[800],
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

  // MODIFIKASI: Menerima parameter target seksi utama agar group langsung masuk ke kategori yang benar
  void _showAddGroupDialogAtSection(String targetMainSection) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📁');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buat Group Baru di $targetMainSection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Group (Misal: Pekerjaan)',
              ),
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
                int nextIndex = _allGroupRaw.length;
                String newId =
                    '${nextIndex}_hub_${DateTime.now().millisecondsSinceEpoch}';

                ChecklistGroup newGroup = ChecklistGroup(
                  id: newId,
                  groupName: nameController.text.trim(),
                  icon: iconController.text.trim(),
                  kategoriSeksi:
                      targetMainSection, // <--- Menyimpan relasi seksi utama
                  isHidden: false,
                  semuaList: [],
                );

                await _saveGroupDataToFile(newGroup);
                Navigator.pop(context);
                _loadGroupsData();
              }
            },
            child: const Text('Buat Group'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGroupDataToFile(ChecklistGroup group) async {
    File groupFile = await _storageService.getSpecificGroupFile(
      _selectedBaseDir,
      group.id,
    );
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(group.toJson());
    await _storageService.saveJsonData(groupFile, jsonString);
  }

  Future<void> _toggleGroupVisibility(ChecklistGroup group) async {
    setState(() {
      group.isHidden = !group.isHidden;
    });
    await _saveGroupDataToFile(group);
    _processGroupsDisplay();
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
                group.groupName = nameController.text.trim();
                group.icon = iconController.text.trim();

                await _saveGroupDataToFile(group);
                Navigator.pop(context);
                _loadGroupsData();
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
            title: const Text('Hapus Checklist Group?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus Group "${group.groupName}" secara permanen beserta seluruh isinya?',
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
      try {
        File groupFile = await _storageService.getSpecificGroupFile(
          _selectedBaseDir,
          group.id,
        );
        if (await groupFile.exists()) {
          await groupFile.delete();
        }
        _loadGroupsData();
      } catch (e) {
        debugPrint("Error deleting group file: $e");
      }
    }
  }

  void _moveGroupOrder(
    List<ChecklistGroup> targetList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= targetList.length) return;

    final itemA = targetList[currentIndex];
    final itemB = targetList[newIndex];

    int rawIdxA = _allGroupRaw.indexWhere((h) => h.id == itemA.id);
    int rawIdxB = _allGroupRaw.indexWhere((h) => h.id == itemB.id);

    if (rawIdxA != -1 && rawIdxB != -1) {
      setState(() {
        final temp = _allGroupRaw[rawIdxA];
        _allGroupRaw[rawIdxA] = _allGroupRaw[rawIdxB];
        _allGroupRaw[rawIdxB] = temp;
      });

      // PROSES RENAME FISIK BERKAS DI LINUX AGAR URUTAN TERKUNCI:
      try {
        for (int i = 0; i < _allGroupRaw.length; i++) {
          final currentGroup = _allGroupRaw[i];

          // Cari file yang lama terlebih dahulu
          File oldFile = await _storageService.getSpecificGroupFile(
            _selectedBaseDir,
            currentGroup.id,
          );

          // Jika id belum mengandung nomor urut, atau nomor urutnya berubah, kita perbarui id dan nama filenya
          String cleanId = currentGroup.id;
          if (cleanId.contains('_hub_')) {
            // Ambil id asli tanpa prefix urutan lama (misal dari "0_hub_123" diambil "hub_123")
            cleanId = cleanId.substring(cleanId.indexOf('hub_'));
          }

          String newId = "${i}_$cleanId";
          File newFile = await _storageService.getSpecificGroupFile(
            _selectedBaseDir,
            newId,
          );

          // Set id baru ke objek runtime agar sinkron
          currentGroup.id = newId;

          if (await oldFile.exists()) {
            // Tulis data terbaru dengan struktur ID yang baru
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentGroup.toJson());
            await newFile.writeAsString(jsonString);

            // Hapus file lama jika namanya berbeda dengan file baru
            if (oldFile.path != newFile.path) {
              await oldFile.delete();
            }
          } else {
            // Jika file lama tidak terdeteksi (karena perubahan state), langsung buat file baru
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentGroup.toJson());
            await newFile.writeAsString(jsonString);
          }
        }
      } catch (e) {
        debugPrint("Gagal mengatur ulang urutan file di Linux: $e");
      }

      _processGroupsDisplay();
    }
  }

  // =========================================================================
  // FITUR MANAJEMEN SEKSI UTAMA (RENAME, HAPUS, & PINDAH SEKSI)
  // =========================================================================

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
                setState(() {
                  // 1. Update data di map lokal yang sedang aktif
                  if (_groupedVisibleGroup.containsKey(oldSectionName)) {
                    final groups =
                        _groupedVisibleGroup.remove(oldSectionName) ?? [];
                    // Update field kategoriSeksi pada setiap objek hub di dalamnya
                    for (var group in groups) {
                      group.kategoriSeksi = newSectionName;
                    }
                    _groupedVisibleGroup[newSectionName] = groups;
                  }

                  // 2. Samakan perubahan ke list master raw data agar saat save file sinkron
                  for (var group in _allGroupRaw) {
                    if (group.kategoriSeksi == oldSectionName) {
                      group.kategoriSeksi = newSectionName;
                    }
                  }
                });

                // 3. Simpan perubahan fisik ke seluruh file JSON hub terkait
                for (var group in _allGroupRaw) {
                  if (group.kategoriSeksi == newSectionName) {
                    await _saveGroupDataToFile(group);
                  }
                }

                Navigator.pop(context);
                _loadGroupsData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteMainSection(String sectionName) async {
    final listGroupDiSeksiIni = _groupedVisibleGroup[sectionName] ?? [];

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
      try {
        // Hapus fisik semua berkas file JSON hub yang berada di seksi ini
        for (var group in listGroupDiSeksiIni) {
          File groupFile = await _storageService.getSpecificGroupFile(
            _selectedBaseDir,
            group.id,
          );
          if (await groupFile.exists()) {
            await groupFile.delete();
          }
        }

        setState(() {
          _groupedVisibleGroup.remove(sectionName);
          _allGroupRaw.removeWhere(
            (group) => group.kategoriSeksi == sectionName,
          );
        });

        _loadGroupsData();
      } catch (e) {
        debugPrint("Gagal menghapus seksi kategori beserta filenya: $e");
      }
    }
  }

  void _moveMainSectionOrder(String sectionName, int direction) {
    final keys = _groupedVisibleGroup.keys.toList();
    int currentIndex = keys.indexOf(sectionName);
    int newIndex = currentIndex + direction;

    if (newIndex < 0 || newIndex >= keys.length) return;

    // Logika reorder map keys manual untuk UI, sedangkan untuk penyimpanan permanen di Linux
    // akan mengandalkan pembaruan prefix nama file saat group di-reorder di fungsi bawaan Anda.
    setState(() {
      final tempMap = Map<String, List<ChecklistGroup>>.from(
        _groupedVisibleGroup,
      );
      _groupedVisibleGroup.clear();

      // Tukar posisi key
      final tempKey = keys[currentIndex];
      keys[currentIndex] = keys[newIndex];
      keys[newIndex] = tempKey;

      // Isi kembali map sesuai urutan key baru
      for (var key in keys) {
        _groupedVisibleGroup[key] = tempMap[key] ?? [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Checklist Groups'),
        backgroundColor: Colors.teal[800],
        actions: [
          IconButton(
            icon: Icon(
              _showHiddenSection ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _showHiddenSection = !_showHiddenSection),
          ),
        ],
      ),
      drawer: const DrawerMenu(isDailyActive: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allGroupRaw.isEmpty && _groupedVisibleGroup.isEmpty
          ? const Center(
              child: Text(
                'Belum ada Seksi Kategori. Tekan + di bawah untuk membuat baru!',
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Mengambil semua kunci seksi aktif ditambah seksi kosong yang baru dibuat
                final semuaKunciSeksi = _groupedVisibleGroup.keys.toList();

                return ListView(
                  children: [
                    ...semuaKunciSeksi.map((namaSeksiUtama) {
                      final listGroupDiSeksiIni =
                          _groupedVisibleGroup[namaSeksiUtama] ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onLongPress: () {
                                    setState(() {
                                      _isSectionEditMode = !_isSectionEditMode;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedPadding(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    padding: _isSectionEditMode
                                        ? const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                            horizontal: 8.0,
                                          )
                                        : const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                            horizontal: 4.0,
                                          ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          namaSeksiUtama.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal[900],
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        // KUMPULAN TOMBOL AKSI MANAJEMEN SEKSI UTAMA HUB
                                        if (_isSectionEditMode) ...[
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Tombol Pindah Naik
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_upward,
                                                  size: 18,
                                                  color: Colors.blueGrey,
                                                ),
                                                onPressed:
                                                    semuaKunciSeksi.indexOf(
                                                          namaSeksiUtama,
                                                        ) >
                                                        0
                                                    ? () =>
                                                          _moveMainSectionOrder(
                                                            namaSeksiUtama,
                                                            -1,
                                                          )
                                                    : null,
                                              ),
                                              // Tombol Pindah Turun
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_downward,
                                                  size: 18,
                                                  color: Colors.blueGrey,
                                                ),
                                                onPressed:
                                                    semuaKunciSeksi.indexOf(
                                                          namaSeksiUtama,
                                                        ) <
                                                        semuaKunciSeksi.length -
                                                            1
                                                    ? () =>
                                                          _moveMainSectionOrder(
                                                            namaSeksiUtama,
                                                            1,
                                                          )
                                                    : null,
                                              ),
                                              // Tombol Ubah Nama (Rename)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: Colors.teal,
                                                ),
                                                onPressed: () =>
                                                    _editMainSectionName(
                                                      namaSeksiUtama,
                                                    ),
                                              ),
                                              // Tombol Hapus Seksi Utama beserta Isinya
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                  color: Colors.redAccent,
                                                ),
                                                onPressed: () =>
                                                    _deleteMainSection(
                                                      namaSeksiUtama,
                                                    ),
                                              ),
                                              // Tombol Tambah Hub bawaan Anda
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.teal,
                                                  size: 18,
                                                ),
                                                tooltip:
                                                    'Tambah Group ke Seksi Ini',
                                                onPressed: () =>
                                                    _showAddGroupDialogAtSection(
                                                      namaSeksiUtama,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          const SizedBox.shrink(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 8, thickness: 1),
                              ],
                            ),
                          ),
                          listGroupDiSeksiIni.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.only(
                                    left: 24,
                                    top: 12,
                                    bottom: 12,
                                  ),
                                  child: Text(
                                    'Belum ada group di seksi ini.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : _buildGroupGrid(
                                  listGroupDiSeksiIni,
                                  constraints,
                                ),
                        ],
                      );
                    }),
                    // === KATEGORI Group TERSEMBUNYI ===
                    if (_hiddenGroup.isNotEmpty && _showHiddenSection) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Divider(thickness: 2, color: Colors.grey),
                      ),
                      ..._groupedHiddenGroup.entries.map((grup) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${grup.key} (Tersembunyi)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildGroupGrid(grup.value, constraints),
                          ],
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
      // REVISI FAB: Diubah fungsinya menjadi pembuat Kategori Seksi Utama Baru dan ikon diganti
      floatingActionButton: FloatingActionButton(
        onPressed:
            _showAddMainSectionDialog, // <--- Memanggil dialog tambah seksi utama
        backgroundColor: Colors.teal[800],
        tooltip: 'Tambah Seksi Kategori Baru',
        child: const Icon(
          Icons
              .create_new_folder_outlined, // <--- Penggantian Icon Sesuai Perintah
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildGroupGrid(
    List<ChecklistGroup> groupList,
    BoxConstraints constraints,
  ) {
    int crossAxisCount = 2;
    if (constraints.maxWidth >= 1200) {
      crossAxisCount = 5;
    } else if (constraints.maxWidth >= 900) {
      crossAxisCount = 4;
    } else if (constraints.maxWidth >= 600) {
      crossAxisCount = 3;
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        // Rasio aspek disesuaikan agar pas saat memanjang ke bawah ketika mode edit aktif
        childAspectRatio: _isPageEditMode ? 0.90 : 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: groupList.length,
      itemBuilder: (context, index) {
        final group = groupList[index];

        // Menghitung total seluruh item dari semua seksi di dalam hub ini
        int totalItems = 0;
        for (var section in group.semuaList) {
          totalItems += section.items.length;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: group.isHidden ? Colors.grey : Colors.teal[800]!,
              width: 3.5,
            ),
          ),
          color: Colors.white,
          child: Column(
            children: [
              // Area Utama Konten Hub
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(_isPageEditMode ? 0 : 16),
                    bottomRight: Radius.circular(_isPageEditMode ? 0 : 16),
                  ),
                  onLongPress: () {
                    setState(() {
                      _isPageEditMode = !_isPageEditMode;
                    });
                  },
                  onTap: _isPageEditMode
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChecklistDetailScreen(
                                group: group,
                                baseDir: _selectedBaseDir,
                              ),
                            ),
                          ).then((_) => _loadGroupsData());
                        },
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            group.icon,
                            style: TextStyle(
                              fontSize: 28,
                              color: group.isHidden
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            group.groupName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: group.isHidden
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 6),
                          // Baris Informasi Statistik Hub
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              // Kotak Jumlah Seksi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (group.isHidden
                                              ? Colors.grey
                                              : Colors.teal[800]!)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${group.semuaList.length} Seksi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: group.isHidden
                                        ? Colors.grey[700]
                                        : Colors.teal[900]!,
                                  ),
                                ),
                              ),
                              // Kotak Jumlah Item
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (group.isHidden
                                              ? Colors.grey
                                              : Colors.indigo[800]!)
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
                    ),
                  ),
                ),
              ),
              // PANEL KONTROL RINGKAS (Tampil saat Mode Edit Aktif)
              if (_isPageEditMode) ...[
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Tombol Pindah Kiri / Atas
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        color: index > 0 ? Colors.teal[800] : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index > 0
                            ? () => _moveGroupOrder(groupList, index, -1)
                            : null,
                      ),

                      // 2. MODIFIKASI BARU: Menu Titik Tiga (Ubah, Sembunyikan, Hapus)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.blueGrey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditGroupDialog(group);
                          } else if (value == 'toggle_visibility') {
                            _toggleGroupVisibility(group);
                          } else if (value == 'delete') {
                            _deleteGroup(group);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: const [
                                Icon(Icons.edit, size: 18, color: Colors.teal),
                                SizedBox(width: 10),
                                Text(
                                  'Ubah Nama & Ikon',
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
                                  group.isHidden
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 18,
                                  color: Colors.blueGrey[700],
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  group.isHidden
                                      ? 'Tampilkan Group'
                                      : 'Sembunyikan Group',
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
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 3. Tombol Pindah Kanan / Bawah
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        color: index < groupList.length - 1
                            ? Colors.teal[800]
                            : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index < groupList.length - 1
                            ? () => _moveGroupOrder(groupList, index, 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
