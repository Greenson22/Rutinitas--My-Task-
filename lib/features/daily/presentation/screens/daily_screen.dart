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
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _hubs.length,
              itemBuilder: (context, index) {
                final hub = _hubs[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Pindah ke layar detail checklist lama Anda (Tahap 4)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChecklistDetailScreen(
                            hub: hub,
                            baseDir: _selectedBaseDir,
                          ),
                        ),
                      ).then((_) => _loadHubsData()); // Refresh saat kembali
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(hub.ikon, style: const TextStyle(fontSize: 50)),
                        const SizedBox(height: 12),
                        Text(
                          hub.namaHub,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hub.semuaList.length} Seksi List',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHubDialog,
        backgroundColor: Colors.teal[800],
        child: const Icon(
          Icons.create_new_folder,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}
