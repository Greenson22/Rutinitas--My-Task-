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
                    return Card(
                      elevation: 3, // Menyamakan tingkat elevasi bayangan
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        // Memberikan aksen border teal penanda Hub agar senada dengan dekorasi Level 2
                        side: BorderSide(color: Colors.teal[800]!, width: 3.5),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
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
                        child: Padding(
                          padding: const EdgeInsets.all(
                            12.0,
                          ), // Menyamakan padding dalam card
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                hub.ikon,
                                style: const TextStyle(
                                  fontSize: 28,
                                ), // Ukuran ikon yang proporsional
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hub.namaHub,
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
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal[800]!.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${hub.semuaList.length} Seksi List',
                                  style: TextStyle(
                                    color: Colors.teal[800],
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
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
