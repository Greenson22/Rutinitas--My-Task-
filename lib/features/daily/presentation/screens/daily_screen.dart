// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../task_master/presentation/widgets/settings_dialog.dart';
import '../../data/models/daily_model.dart';
import 'checklist_detail_screen.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final StorageService _storageService = StorageService();
  List<ChecklistHub> _allHubsRaw = [];
  List<ChecklistHub> _visibleHubs = [];
  List<ChecklistHub> _hiddenHubs = [];

  String _selectedBaseDir = 'Documents';
  String _fullJsonPath = 'my_checklist/';
  bool _isLoading = true;

  bool _isPageEditMode = false;
  bool _showHiddenSection = false;

  @override
  void initState() {
    super.initState();
    _loadHubsData();
  }

  Future<void> _loadHubsData() async {
    setState(() => _isLoading = true);
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      List<File> hubFiles = await _storageService.getAllChecklistHubs(
        _selectedBaseDir,
      );

      // SOLUSI PERMANEN LINUX: Urutkan file berdasarkan nama file secara alfabetis/numerik.
      // Dengan cara ini, prefix angka seperti 0_, 1_, 2_ akan memaksa Linux membaca sesuai urutan kustom kita.
      hubFiles.sort((a, b) {
        String nameA = a.path.split('/').last;
        String nameB = b.path.split('/').last;
        return nameA.compareTo(nameB);
      });

      List<ChecklistHub> loadedHubs = [];
      for (var file in hubFiles) {
        String jsonString = await file.readAsString();
        final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
        loadedHubs.add(ChecklistHub.fromJson(parsedMap));
      }

      _allHubsRaw = loadedHubs;
      _processHubsDisplay();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading hubs: $e");
    }
  }

  void _processHubsDisplay() {
    setState(() {
      _visibleHubs = _allHubsRaw.where((hub) => !hub.isHidden).toList();
      _hiddenHubs = _allHubsRaw.where((hub) => hub.isHidden).toList();
      _isLoading = false;
    });
  }

  Future<void> _saveHubDataToFile(ChecklistHub hub) async {
    File hubFile = await _storageService.getSpecificHubFile(
      _selectedBaseDir,
      hub.id,
    );
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(hub.toJson());
    await _storageService.saveJsonData(hubFile, jsonString);
  }

  Future<void> _createNewHub(String nama, String ikon) async {
    // Memberikan urutan indeks terakhir berdasarkan jumlah data saat ini
    int nextIndex = _allHubsRaw.length;
    String newId = '${nextIndex}_hub_${DateTime.now().millisecondsSinceEpoch}';

    ChecklistHub newHub = ChecklistHub(
      id: newId,
      namaHub: nama,
      ikon: ikon,
      isHidden: false,
      semuaList: [],
    );

    await _saveHubDataToFile(newHub);
    _loadHubsData();
  }

  Future<void> _toggleHubVisibility(ChecklistHub hub) async {
    setState(() {
      hub.isHidden = !hub.isHidden;
    });
    await _saveHubDataToFile(hub);
    _processHubsDisplay();
  }

  void _showAddHubDialog() {
    final _nameController = TextEditingController();
    final _iconController = TextEditingController(text: '📁');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Checklist Hub Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Hub (Misal: Pekerjaan)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _iconController,
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
              if (_nameController.text.isNotEmpty) {
                _createNewHub(_nameController.text, _iconController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Buat Hub'),
          ),
        ],
      ),
    );
  }

  void _showEditHubDialog(ChecklistHub hub) {
    final _nameController = TextEditingController(text: hub.namaHub);
    final _iconController = TextEditingController(text: hub.ikon);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Checklist Hub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Hub'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _iconController,
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
              if (_nameController.text.isNotEmpty) {
                hub.namaHub = _nameController.text.trim();
                hub.ikon = _iconController.text.trim();

                await _saveHubDataToFile(hub);
                Navigator.pop(context);
                _loadHubsData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteHub(ChecklistHub hub) async {
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Checklist Hub?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus Hub "${hub.namaHub}" secara permanen beserta seluruh isinya?',
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
        File hubFile = await _storageService.getSpecificHubFile(
          _selectedBaseDir,
          hub.id,
        );
        if (await hubFile.exists()) {
          await hubFile.delete();
        }
        _loadHubsData();
      } catch (e) {
        debugPrint("Error deleting hub file: $e");
      }
    }
  }

  void _moveHubOrder(
    List<ChecklistHub> targetList,
    int currentIndex,
    int direction,
  ) async {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= targetList.length) return;

    final itemA = targetList[currentIndex];
    final itemB = targetList[newIndex];

    int rawIdxA = _allHubsRaw.indexWhere((h) => h.id == itemA.id);
    int rawIdxB = _allHubsRaw.indexWhere((h) => h.id == itemB.id);

    if (rawIdxA != -1 && rawIdxB != -1) {
      setState(() {
        final temp = _allHubsRaw[rawIdxA];
        _allHubsRaw[rawIdxA] = _allHubsRaw[rawIdxB];
        _allHubsRaw[rawIdxB] = temp;
      });

      // PROSES RENAME FISIK BERKAS DI LINUX AGAR URUTAN TERKUNCI:
      try {
        for (int i = 0; i < _allHubsRaw.length; i++) {
          final currentHub = _allHubsRaw[i];

          // Cari file yang lama terlebih dahulu
          File oldFile = await _storageService.getSpecificHubFile(
            _selectedBaseDir,
            currentHub.id,
          );

          // Jika id belum mengandung nomor urut, atau nomor urutnya berubah, kita perbarui id dan nama filenya
          String cleanId = currentHub.id;
          if (cleanId.contains('_hub_')) {
            // Ambil id asli tanpa prefix urutan lama (misal dari "0_hub_123" diambil "hub_123")
            cleanId = cleanId.substring(cleanId.indexOf('hub_'));
          }

          String newId = "${i}_$cleanId";
          File newFile = await _storageService.getSpecificHubFile(
            _selectedBaseDir,
            newId,
          );

          // Set id baru ke objek runtime agar sinkron
          currentHub.id = newId;

          if (await oldFile.exists()) {
            // Tulis data terbaru dengan struktur ID yang baru
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentHub.toJson());
            await newFile.writeAsString(jsonString);

            // Hapus file lama jika namanya berbeda dengan file baru
            if (oldFile.path != newFile.path) {
              await oldFile.delete();
            }
          } else {
            // Jika file lama tidak terdeteksi (karena perubahan state), langsung buat file baru
            final String jsonString = const JsonEncoder.withIndent(
              '  ',
            ).convert(currentHub.toJson());
            await newFile.writeAsString(jsonString);
          }
        }
      } catch (e) {
        debugPrint("Gagal mengatur ulang urutan file di Linux: $e");
      }

      _processHubsDisplay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Checklist Hubs'),
        backgroundColor: Colors.teal[800],
        actions: [
          IconButton(
            icon: Icon(
              _showHiddenSection ? Icons.visibility : Icons.visibility_off,
            ),
            tooltip: _showHiddenSection
                ? 'Sembunyikan Sesi Tersembunyi'
                : 'Tampilkan Sesi Tersembunyi',
            onPressed: () =>
                setState(() => _showHiddenSection = !_showHiddenSection),
          ),
        ],
      ),
      drawer: const DrawerMenu(isDailyActive: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allHubsRaw.isEmpty
          ? const Center(
              child: Text('Belum ada Hub. Tekan + untuk membuat baru!'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    if (_visibleHubs.isNotEmpty)
                      _buildHubGrid(_visibleHubs, constraints),

                    if (_visibleHubs.isEmpty && _hiddenHubs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('Tidak ada Hub.')),
                      ),

                    if (_hiddenHubs.isNotEmpty && _showHiddenSection) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Divider(thickness: 2, color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.blueGrey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hub yang disembunyikan (${_hiddenHubs.length})',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildHubGrid(_hiddenHubs, constraints),
                    ],
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHubDialog,
        backgroundColor: Colors.teal[800],
        tooltip: 'Buat Hub Baru',
        child: const Icon(
          Icons.create_new_folder,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHubGrid(
    List<ChecklistHub> hubsList,
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
        // Rasio aspek disesuaikan secara dinamis agar kotak memanjang ke bawah saat panel kontrol aktif
        childAspectRatio: _isPageEditMode ? 0.90 : 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: hubsList.length,
      itemBuilder: (context, index) {
        final hub = hubsList[index];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: hub.isHidden ? Colors.grey : Colors.teal[800]!,
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
                  // Mengaktifkan atau mengembalikan mode edit dengan cara menahan kotak
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
                                hub: hub,
                                baseDir: _selectedBaseDir,
                              ),
                            ),
                          ).then((_) => _loadHubsData());
                        },
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            hub.ikon,
                            style: TextStyle(
                              fontSize: 28,
                              color: hub.isHidden ? Colors.grey : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hub.namaHub,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: hub.isHidden
                                  ? Colors.grey
                                  : Colors.black87,
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
                              color:
                                  (hub.isHidden
                                          ? Colors.grey
                                          : Colors.teal[800]!)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${hub.semuaList.length} Seksi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hub.isHidden
                                    ? Colors.grey[700]
                                    : Colors.teal[900]!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // PANEL KONTROL BARU SEPERTI GAMBAR (Hanya tampil saat Mode Edit Aktif)
              if (_isPageEditMode) ...[
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
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
                            ? () => _moveHubOrder(hubsList, index, -1)
                            : null,
                      ),
                      // 2. Tombol Sembunyikan / Tampilkan (Mata)
                      IconButton(
                        icon: Icon(
                          hub.isHidden
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 18,
                          color: Colors.blueGrey[700],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: hub.isHidden
                            ? 'Tampilkan Hub'
                            : 'Sembunyikan Hub',
                        onPressed: () => _toggleHubVisibility(hub),
                      ),
                      // 3. Tombol Pindah Kanan / Bawah
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        color: index < hubsList.length - 1
                            ? Colors.teal[800]
                            : Colors.grey[300],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: index < hubsList.length - 1
                            ? () => _moveHubOrder(hubsList, index, 1)
                            : null,
                      ),
                      // 4. Tombol Hapus (Merah)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _deleteHub(hub),
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
