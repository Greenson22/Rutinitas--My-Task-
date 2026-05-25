import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Master',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: false),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // String JSON riil yang Anda berikan
  final String _rawJsonData = '''
  {
    "categories": [
      {
        "name": "Primary",
        "icon": "💖",
        "tasks": [
          {"id": "2f40c177", "name": "Bible", "count": 1006, "date": "2026-05-25", "checked": false, "countToday": 2, "targetCountToday": 2, "type": 1, "targetCount": 1500}
        ],
        "isHidden": false
      },
      {
        "name": "Secondary",
        "icon": "📊",
        "tasks": [
          {"id": "ca45cea8", "name": "Career", "count": 625, "date": "2026-05-24", "checked": true, "countToday": 0, "targetCountToday": 4, "type": 0, "targetCount": 1},
          {"id": "5ee31522", "name": "New Tech", "count": 4, "date": "2026-05-22", "checked": true, "countToday": 0, "targetCountToday": 1, "type": 0, "targetCount": 1},
          {"id": "a248324a", "name": "Coding", "count": 204, "date": "2026-05-25", "checked": true, "countToday": 1, "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "82500fc1", "name": "Game", "count": 69, "date": "2026-05-01", "checked": false, "countToday": 0, "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "46fa2550", "name": "Extra", "count": 604, "date": "2026-05-22", "checked": false, "countToday": 0, "targetCountToday": 0, "type": 0, "targetCount": 1}
        ],
        "isHidden": false
      },
      {
        "name": "Exploring",
        "icon": "🏞️",
        "tasks": [
          {"id": "164705ca", "name": "Umum Expl", "count": 158, "date": "2026-01-16", "checked": true, "countToday": 0, "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "c755c880", "name": "Career Expl", "count": 53, "date": "2026-02-15", "checked": true, "countToday": 0, "targetCountToday": 0, "type": 0, "targetCount": 1}
        ],
        "isHidden": true
      },
      {
        "name": "Target",
        "icon": "🎯",
        "tasks": [
          {"id": "14aa5ea8", "name": "Soft Skill dan Meta SKill", "count": 189, "date": "2026-05-24", "checked": false, "countToday": 0, "targetCountToday": 4, "type": 1, "targetCount": 200},
          {"id": "280daa2a", "name": "Memory", "count": 17, "date": "2026-05-19", "checked": false, "countToday": 0, "targetCountToday": 2, "type": 1, "targetCount": 24},
          {"id": "30ca88e6", "name": "Uang", "count": 5, "date": "2026-05-10", "checked": false, "countToday": 0, "targetCountToday": 0, "type": 1, "targetCount": 100}
        ],
        "isHidden": false
      },
      {
        "name": "Habit",
        "icon": "🐢",
        "tasks": [
          {"id": "34103f2c", "name": "Weak", "count": 1, "date": "2026-05-25", "checked": false, "countToday": 1, "targetCountToday": 1, "type": 1, "targetCount": 7},
          {"id": "8d308183", "name": "Tidak makan telur", "count": 1, "date": "2026-05-25", "checked": false, "countToday": 1, "targetCountToday": 1, "type": 1, "targetCount": 7}
        ],
        "isHidden": false
      }
    ]
  }
  ''';

  List<dynamic> _categories = [];
  String _storageLocation =
      'Penyimpanan Internal'; // Default value lokasi penyimpanan

  @override
  void initState() {
    super.initState();
    _loadJsonData();
    _loadStorageSettings();
  }

  // Fungsi memuat data riil dari format JSON
  void _loadJsonData() {
    final Map<String, dynamic> parsedMap = jsonDecode(_rawJsonData);
    setState(() {
      // Hanya menampilkan kategori yang tidak disembunyikan (isHidden == false)
      _categories = parsedMap['categories']
          .where((cat) => cat['isHidden'] == false)
          .toList();
    });
  }

  // Fungsi memuat pengaturan lokasi penyimpanan yang tersimpan di sistem
  Future<void> _loadStorageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storageLocation =
          prefs.getString('storage_location') ?? 'Penyimpanan Internal';
    });
  }

  // Fungsi memperbarui lokasi penyimpanan baru
  Future<void> _updateStorageLocation(String newLocation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storage_location', newLocation);
    setState(() {
      _storageLocation = newLocation;
    });
  }

  // Dialog Kategori Pengaturan Penyimpanan
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSelection = _storageLocation;
        return AlertDialog(
          title: const Text('Pengaturan Penyimpanan'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tentukan format/lokasi penyimpanan file JSON data tugas Anda:',
                  ),
                  const SizedBox(height: 15),
                  RadioListTile<String>(
                    title: const Text('Penyimpanan Internal (Aplikasi)'),
                    value: 'Penyimpanan Internal',
                    groupValue: tempSelection,
                    onChanged: (val) =>
                        setDialogState(() => tempSelection = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Eksternal (Dokumen/Download)'),
                    value: 'Penyimpanan Eksternal',
                    groupValue: tempSelection,
                    onChanged: (val) =>
                        setDialogState(() => tempSelection = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Cloud Sync (Format Cloud .json)'),
                    value: 'Cloud Storage',
                    groupValue: tempSelection,
                    onChanged: (val) =>
                        setDialogState(() => tempSelection = val!),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStorageLocation(tempSelection);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Lokasi penyimpanan diatur ke: $tempSelection',
                    ),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog Detail Tugas berbasis data riil di dalam List kategori JSON
  void _showCategoryTasksDialog(String categoryName, List<dynamic> tasks) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Text(
                '$categoryName Category',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  // Menyusun visual teks subtitle sesuai format data riil Anda
                  String subtitleText =
                      '+${task['countToday']} / ${task['targetCountToday']} hari ini | Total: ${task['count']}';
                  if (task['date'] != null)
                    subtitleText += ' | Due: ${task['date']}';

                  return ListTile(
                    dense: true,
                    leading: Icon(
                      task['checked'] == true
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Colors.blue,
                    ),
                    title: Text(
                      task['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      subtitleText,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(Icons.more_vert),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
                TextButton(onPressed: () {}, child: const Text('Tambah Tugas')),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Task Master'),
        backgroundColor: Colors.indigo[700],
      ),
      // --- INTEGRASI SIDEBAR (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: const [
                  Icon(
                    Icons.format_list_bulleted,
                    color: Colors.indigo,
                    size: 30,
                  ),
                  SizedBox(width: 20),
                  Text(
                    'Task Master',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              Icons.format_list_bulleted,
              'Task Master',
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              Icons.wb_sunny_outlined,
              'Daily',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              Icons.calendar_today,
              'Weekly',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              Icons.calendar_month,
              'Monthly',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            // Menu Pengaturan untuk mengganti lokasi file penyimpanan JSON
            _buildDrawerItem(
              Icons.settings,
              'Settings',
              subtitle:
                  _storageLocation, // Menampilkan indikasi lokasi aktif saat ini
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog();
              },
            ),
            const Divider(),
            _buildDrawerItem(
              Icons.info_outline,
              'About',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          if (constraints.maxWidth >= 1200) {
            crossAxisCount = 5;
          } else if (constraints.maxWidth >= 900) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 3;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final item = _categories[index];
              final List<dynamic> tasks = item['tasks'] ?? [];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () => _showCategoryTasksDialog(item['name'], tasks),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Menampilkan icon teks emoji bawaan dari JSON (e.g., 💖, 📊)
                        CircleAvatar(
                          backgroundColor: Colors.indigo[50],
                          radius: 24,
                          child: Text(
                            item['icon'] ?? '📝',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tasks.length} tasks',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    String? subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.indigo : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      onTap: onTap,
    );
  }
}
