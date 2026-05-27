// lib/features/daily/presentation/screens/daily_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/presentation/widgets/drawer_menu.dart';
import '../../../task_master/presentation/widgets/settings_dialog.dart';
import '../../data/models/daily_model.dart';
import 'checklist_detail_screen.dart'; // Import layar detail baru

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final StorageService _storageService = StorageService();
  List<ChecklistHub> _hubs = []; // Menggunakan List untuk menampung banyak Hub
  String _selectedBaseDir = 'Documents';
  String _fullJsonPath = 'my_checklist/';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHubsData();
  }

  // Fungsi baru: Scan semua file JSON Hub di direktori
  Future<void> _loadHubsData() async {
    setState(() => _isLoading = true);
    try {
      _selectedBaseDir = await _storageService.getBaseDirSetting();
      List<File> hubFiles = await _storageService.getAllChecklistHubs(
        _selectedBaseDir,
      );

      List<ChecklistHub> loadedHubs = [];
      for (var file in hubFiles) {
        String jsonString = await file.readAsString();
        final Map<String, dynamic> parsedMap = jsonDecode(jsonString);
        loadedHubs.add(ChecklistHub.fromJson(parsedMap));
      }

      setState(() {
        _hubs = loadedHubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading hubs: $e");
    }
  }

  Future<void> _createNewHub(String nama, String ikon) async {
    String newId = 'hub_${DateTime.now().millisecondsSinceEpoch}';
    ChecklistHub newHub = ChecklistHub(
      id: newId,
      namaHub: nama,
      ikon: ikon,
      semuaList: [],
    );

    File newFile = await _storageService.getSpecificHubFile(
      _selectedBaseDir,
      newId,
    );
    final String jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(newHub.toJson());
    await _storageService.saveJsonData(newFile, jsonString);

    _loadHubsData(); // Refresh UI
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

  // Taruh fungsi ini di dalam class _DailyScreenState

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
                setState(() {
                  hub.namaHub = _nameController.text.trim();
                  hub.ikon = _iconController.text.trim();
                });

                // Menyimpan perubahan ke file JSON spesifik milik Hub ini
                File hubFile = await _storageService.getSpecificHubFile(
                  _selectedBaseDir,
                  hub.id,
                );
                final String jsonString = const JsonEncoder.withIndent(
                  '  ',
                ).convert(hub.toJson());
                await _storageService.saveJsonData(hubFile, jsonString);

                Navigator.pop(context);
                _loadHubsData(); // Refresh UI
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Taruh fungsi ini di dalam class _DailyScreenState

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
          await hubFile.delete(); // Menghapus file fisik JSON
        }
        _loadHubsData(); // Refresh list Hub setelah dihapus
      } catch (e) {
        debugPrint("Error deleting hub file: $e");
      }
    }
  }

  // Taruh fungsi ini di dalam class _DailyScreenState

  void _moveHubOrder(int currentIndex, int direction) {
    int newIndex = currentIndex + direction;
    if (newIndex < 0 || newIndex >= _hubs.length) return;

    setState(() {
      final temp = _hubs[currentIndex];
      _hubs[currentIndex] = _hubs[newIndex];
      _hubs[newIndex] = temp;
    });
    // Catatan: Jika ingin urutan ini permanen di penyimpanan offline,
    // Anda memerlukan mekanisme file indeks tambahan atau memanipulasi timestamp nama file.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('My Checklist Hubs'),
        backgroundColor: Colors.teal[800],
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _selectedBaseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings: () {},
        isDailyActive: true,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hubs.isEmpty
          ? const Center(
              child: Text('Belum ada Hub. Tekan + untuk membuat baru!'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // SINKRONISASI: Menyamakan hitungan jumlah kolom secara responsif
                int crossAxisCount = 2;
                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 5;
                } else if (constraints.maxWidth >= 900) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12), // Menyamakan padding grid
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    // SINKRONISASI: Menyamakan aspek rasio kotak (1.15) dengan Level 2
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _hubs.length,
                  itemBuilder: (context, index) {
                    final hub = _hubs[index];

                    // MODIFIKASI bagian GridView.builder -> Card -> Stack/Row di daily_screen.dart

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.teal[800]!, width: 3.5),
                      ),
                      color: Colors.white,
                      child: Stack(
                        // Menggunakan Stack agar bisa menaruh tombol menu di pojok kanan atas kartu
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // ... kode Navigator.push lama Anda tetap di sini ...
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    hub.ikon,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    hub.namaHub,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    // ... kode kontainer jumlah Seksi List lama Anda ...
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // === TOMBOL POPUP MENU BARU DI POJOK KANAN ATAS KARTU HUB ===
                          Positioned(
                            top: 4,
                            right: 4,
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditHubDialog(hub);
                                } else if (value == 'delete') {
                                  _deleteHub(hub);
                                } else if (value == 'move_left') {
                                  _moveHubOrder(index, -1);
                                } else if (value == 'move_right') {
                                  _moveHubOrder(index, 1);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'move_left',
                                  enabled: index > 0,
                                  child: const ListTile(
                                    leading: Icon(Icons.arrow_back, size: 18),
                                    title: Text('Pindah Kiri/Atas'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'move_right',
                                  enabled: index < _hubs.length - 1,
                                  child: const ListTile(
                                    leading: Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                    title: Text('Pindah Kanan/Bawah'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit, size: 18),
                                    title: Text('Ubah Nama & Ikon'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    title: Text(
                                      'Hapus Hub',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      // === MENGEMBALIKAN TOMBOL TAMBAH HUBS YANG HILANG ===
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
}
