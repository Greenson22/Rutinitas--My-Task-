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
    String newId = 'hub_${DateTime.now().millisecondsSinceEpoch}';
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
  ) {
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
          IconButton(
            icon: Icon(
              _isPageEditMode ? Icons.check_circle : Icons.edit_note,
              size: 28,
            ),
            color: _isPageEditMode ? Colors.amberAccent : Colors.white,
            tooltip: 'Mode Edit Susunan Hub',
            onPressed: () => setState(() => _isPageEditMode = !_isPageEditMode),
          ),
        ],
      ),
      drawer: DrawerMenu(
        selectedBaseDir: _selectedBaseDir,
        fullJsonPath: _fullJsonPath,
        onOpenSettings: () {},
        isDailyActive: true,
      ),
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
        childAspectRatio: 1.15,
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
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                // MENAHAN KOTAK (LONG PRESS): memicu masuk/keluar dari mode edit halaman
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
                            color: hub.isHidden ? Colors.grey : Colors.black87,
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
                                (hub.isHidden ? Colors.grey : Colors.teal[800]!)
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

              if (_isPageEditMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.black87,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditHubDialog(hub);
                      } else if (value == 'delete') {
                        _deleteHub(hub);
                      } else if (value == 'toggle_visibility') {
                        _toggleHubVisibility(hub);
                      } else if (value == 'move_left') {
                        _moveHubOrder(hubsList, index, -1);
                      } else if (value == 'move_right') {
                        _moveHubOrder(hubsList, index, 1);
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
                        enabled: index < hubsList.length - 1,
                        child: const ListTile(
                          leading: Icon(Icons.arrow_forward, size: 18),
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
                      PopupMenuItem<String>(
                        value: 'toggle_visibility',
                        child: ListTile(
                          leading: Icon(
                            hub.isHidden
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 18,
                          ),
                          title: Text(
                            hub.isHidden ? 'Tampilkan Hub' : 'Sembunyikan Hub',
                          ),
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
  }
}
