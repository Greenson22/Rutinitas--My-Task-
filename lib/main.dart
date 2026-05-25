import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  List<dynamic> _categories = [];
  String _selectedBaseDir = 'Documents'; // Default pilihan folder di Ubuntu
  String _fullJsonPath = '';
  bool _isLoading = true;

  // Data JSON asli Anda yang akan otomatis ditulis ke file jika file belum ada
  final String _defaultJsonContent = '''
  {
    "categories": [
      {
        "name": "Primary",
        "icon": "💖",
        "tasks": [
          {"id": "2f40c177-ad12-405c-b891-3e1f7f850180", "name": "Bible", "count": 1006, "date": "2026-05-25", "checked": false, "countToday": 2, "lastUpdated": "2026-05-25", "targetCountToday": 2, "type": 1, "targetCount": 1500}
        ],
        "isHidden": false
      },
      {
        "name": "Secondary",
        "icon": "📊",
        "tasks": [
          {"id": "ca45cea8-5bd3-4416-b530-c4f6b750466a", "name": "Career", "count": 625, "date": "2026-05-24", "checked": true, "countToday": 0, "lastUpdated": "2026-05-24", "targetCountToday": 4, "type": 0, "targetCount": 1},
          {"id": "5ee31522-8cf6-425b-9429-c1559be2e57b", "name": "New Tech", "count": 4, "date": "2026-05-22", "checked": true, "countToday": 0, "lastUpdated": "2026-05-22", "targetCountToday": 1, "type": 0, "targetCount": 1},
          {"id": "a248324a-35e3-48e6-b7b1-bcec077431b9", "name": "Coding", "count": 204, "date": "2026-05-25", "checked": true, "countToday": 1, "lastUpdated": "2026-05-25", "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "82500fc1-4c43-4890-81b3-b0384f0e8d5d", "name": "Game", "count": 69, "date": "2026-05-01", "checked": false, "countToday": 0, "lastUpdated": "2026-05-01", "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "46fa2550-6527-40bf-b3ca-aad42a582f6d", "name": "Extra", "count": 604, "date": "2026-05-22", "checked": false, "countToday": 0, "lastUpdated": "2026-05-22", "targetCountToday": 0, "type": 0, "targetCount": 1}
        ],
        "isHidden": false
      },
      {
        "name": "Exploring",
        "icon": "🏞️",
        "tasks": [
          {"id": "164705ca-317e-4581-a1c2-66dcd8589c5f", "name": "Umum Expl", "count": 158, "date": "2026-01-16", "checked": true, "countToday": 0, "lastUpdated": "2026-01-16", "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "c755c880-ed90-4f6b-8ebf-b4853e42930b", "name": "Career Expl", "count": 53, "date": "2026-02-15", "checked": true, "countToday": 0, "lastUpdated": "2025-11-25", "targetCountToday": 0, "type": 0, "targetCount": 1}
        ],
        "isHidden": true
      },
      {
        "name": "Target",
        "icon": "🎯",
        "tasks": [
          {"id": "14aa5ea8-e0d9-4fb7-985e-991300a2799e", "name": "Soft Skill dan Meta SKill", "count": 189, "date": "2026-05-24", "checked": false, "countToday": 0, "lastUpdated": "2026-05-24", "targetCountToday": 4, "type": 1, "targetCount": 200},
          {"id": "280daa2a-43ed-4e58-8066-386b3685722d", "name": "Memory", "count": 17, "date": "2026-05-19", "checked": false, "countToday": 0, "lastUpdated": "2026-05-19", "targetCountToday": 2, "type": 1, "targetCount": 24},
          {"id": "30ca88e6-6cd2-478c-ad97-d583972d9823", "name": "Uang", "count": 5, "date": "2026-05-10", "checked": false, "countToday": 0, "lastUpdated": "2026-05-10", "targetCountToday": 0, "type": 1, "targetCount": 100},
          {"id": "6c5a5a1a-096e-4465-a60a-602c61a93b94", "name": "Job Search New", "count": 1, "date": "2026-05-13", "checked": false, "countToday": 0, "lastUpdated": "2026-05-13", "targetCountToday": 0, "type": 1, "targetCount": 100},
          {"id": "a02e2b30-07bc-4f03-98f7-485a2b066b17", "name": "Bernyanyi", "count": 6, "date": "2026-05-17", "checked": false, "countToday": 0, "lastUpdated": "2026-05-17", "targetCountToday": 0, "type": 1, "targetCount": 14},
          {"id": "11c3920b-3633-4a60-99e5-c6d059694c3d", "name": "Prompt", "count": 1, "date": "2026-05-19", "checked": false, "countToday": 0, "lastUpdated": "2026-05-19", "targetCountToday": 0, "type": 1, "targetCount": 14}
        ],
        "isHidden": false
      },
      {
        "name": "Habit",
        "icon": "🐢",
        "tasks": [
          {"id": "34103f2c-afd2-4ef3-838f-c80b005a2672", "name": "Weak", "count": 1, "date": "2026-05-25", "checked": false, "countToday": 1, "lastUpdated": "2026-05-25", "targetCountToday": 1, "type": 1, "targetCount": 7},
          {"id": "7c72329e-9430-4fa0-837a-435be40aa018", "name": "Z High", "count": 53, "date": "2026-03-01", "checked": false, "countToday": 0, "lastUpdated": "2025-10-08", "targetCountToday": 0, "type": 0, "targetCount": 1},
          {"id": "8d308183-752f-4c49-9322-596b7dc953fd", "name": "Tidak makan telur, ikan, ayam dan mie", "count": 1, "date": "2026-05-25", "checked": false, "countToday": 1, "lastUpdated": "2026-05-25", "targetCountToday": 1, "type": 1, "targetCount": 7},
          {"id": "36d2e156-f971-45f0-b136-aa3a10a5267c", "name": "Tidak nonton Reels yg lama saat sesi Belajar atau bekerja", "count": 1, "date": "2026-05-25", "checked": false, "countToday": 1, "lastUpdated": "2026-05-25", "targetCountToday": 1, "type": 1, "targetCount": 14}
        ],
        "isHidden": false
      }
    ]
  }
  ''';

  @override
  void initState() {
    super.initState();
    _initStorageAndLoadData();
  }

  // Mengambil konfigurasi penyimpanan Ubuntu & memuat data dari file JSON asli
  Future<void> _initStorageAndLoadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _selectedBaseDir = prefs.getString('ubuntu_base_dir') ?? 'Documents';

    try {
      Directory baseDir;
      // Menentukan direktori dasar Ubuntu menggunakan path_provider
      if (_selectedBaseDir == 'Downloads') {
        baseDir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        baseDir =
            await getApplicationDocumentsDirectory(); // Default ke Documents bawaan sistem Linux
      }

      // OTOMATISASI pembuatan folder /mytask sesuai instruksi Anda
      final Directory myTaskDir = Directory('${baseDir.path}/mytask');
      if (!await myTaskDir.exists()) {
        await myTaskDir.create(recursive: true);
      }

      // Path file JSON target di dalam folder mytask
      final File jsonFile = File('${myTaskDir.path}/my_tasks.json');
      _fullJsonPath = jsonFile.path;

      // Jika file JSON belum ada di folder mytask, tulis data bawaan Anda ke sana
      if (!await jsonFile.exists()) {
        await jsonFile.writeAsString(_defaultJsonContent);
      }

      // Membaca file JSON riil
      final String jsonString = await jsonFile.readAsString();
      final Map<String, dynamic> parsedMap = jsonDecode(jsonString);

      setState(() {
        // Hanya memuat kategori yang isHidden == false
        _categories = parsedMap['categories']
            .where((cat) => cat['isHidden'] == false)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading file: $e");
    }
  }

  // Mengganti lokasi direktori dasar di Ubuntu
  Future<void> _updateUbuntuStorage(String newDir) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ubuntu_base_dir', newDir);
    _initStorageAndLoadData(); // Memuat ulang struktur data di lokasi baru
  }

  // Tampilan Pengaturan khusus Struktur Folder Ubuntu
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSelection = _selectedBaseDir;
        return AlertDialog(
          title: const Text('Pengaturan Folder Ubuntu'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih direktori dasar untuk menyimpan data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    title: const Text('Folder Documents (~/Documents)'),
                    value: 'Documents',
                    groupValue: tempSelection,
                    onChanged: (val) =>
                        setDialogState(() => tempSelection = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Folder Downloads (~/Downloads)'),
                    value: 'Downloads',
                    groupValue: tempSelection,
                    onChanged: (val) =>
                        setDialogState(() => tempSelection = val!),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Catatan: Aplikasi akan otomatis membuat subfolder "/mytask/my_tasks.json" di dalam direktori terpilih.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                _updateUbuntuStorage(tempSelection);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Lokasi dipindahkan ke: $tempSelection/mytask/',
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

  // Dialog list tugas riil berdasarkan kategori dari berkas JSON
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
              child: tasks.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Tidak ada tugas aktif di kategori ini.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
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
            _buildDrawerItem(
              Icons.settings,
              'Settings',
              subtitle: '~/$_selectedBaseDir/mytask/',
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog();
              },
            ),
            const Divider(),
            _buildDrawerItem(
              Icons.info_outline,
              'About',
              subtitle: 'Path: $_fullJsonPath',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
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
                        onTap: () =>
                            _showCategoryTasksDialog(item['name'], tasks),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
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
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            )
          : null,
      onTap: onTap,
    );
  }
}
