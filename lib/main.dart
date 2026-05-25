import 'package:flutter/material.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Data dummy yang sudah ditambah sesuai gambar tablet Anda
  final List<Map<String, dynamic>> categories = const [
    {
      'name': 'Work',
      'tasks': 8,
      'icon': Icons.card_travel,
      'color': Colors.indigo,
    },
    {'name': 'Personal', 'tasks': 3, 'icon': Icons.home, 'color': Colors.brown},
    {
      'name': 'Shopping',
      'tasks': 5,
      'icon': Icons.shopping_cart,
      'color': Colors.pink,
    },
    {
      'name': 'Finance',
      'tasks': 4,
      'icon': Icons.credit_card,
      'color': Colors.green,
    },
    {
      'name': 'Gandom',
      'tasks': 8,
      'icon': Icons.notifications_active,
      'color': Colors.red,
    },
    {
      'name': 'Niacking',
      'tasks': 8,
      'icon': Icons.phone,
      'color': Colors.green,
    },
    {
      'name': 'Problems',
      'tasks': 8,
      'icon': Icons.business_center,
      'color': Colors.teal,
    },
    {
      'name': 'Learning',
      'tasks': 6,
      'icon': Icons.school,
      'color': Colors.purple,
    },
    {
      'name': 'Caries',
      'tasks': 8,
      'icon': Icons.directions_car,
      'color': Colors.purple,
    },
    {
      'name': 'Willdity',
      'tasks': 8,
      'icon': Icons.public,
      'color': Colors.teal,
    },
    {'name': 'Travel', 'tasks': 2, 'icon': Icons.flight, 'color': Colors.cyan},
    {
      'name': 'Home',
      'tasks': 7,
      'icon': Icons.home,
      'color': Colors.blueAccent,
    },
    {
      'name': 'Problems',
      'tasks': 8,
      'icon': Icons.business_center,
      'color': Colors.tealAccent,
    },
    {
      'name': 'Program',
      'tasks': 8,
      'icon': Icons.favorite,
      'color': Colors.brown,
    },
    {
      'name': 'Hobbies',
      'tasks': 3,
      'icon': Icons.palette,
      'color': Colors.orange,
    },
    {
      'name': 'Health',
      'tasks': 3,
      'icon': Icons.people,
      'color': Colors.orange,
    },
    {
      'name': 'People',
      'tasks': 3,
      'icon': Icons.description,
      'color': Colors.pink,
    },
  ];

  void _showWorkCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                child: const Text(
                  'Work Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                child: Column(
                  children: [
                    _buildPopupItem(
                      'Career',
                      '+0 / 4 hari ini | Total: 625 | Due: 2026-05-24',
                    ),
                    _buildPopupItem(
                      'New Tech',
                      '+0 / 1 hari ini | Total: 4 | Due: 2026-05-22',
                    ),
                    _buildPopupItem('Coding', 'Total: 203 | Due: 2026-05-24'),
                    _buildPopupItem('Game', 'Total: 69 | Due: 2026-05-01'),
                    _buildPopupItem('Extra', 'Total: 604 | Due: 2026-05-22'),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Tambah Tugas',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopupItem(String title, String subtitle) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 0.0,
      ),
      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
      ),
      trailing: const Icon(Icons.more_vert, color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Task Master'),
        backgroundColor: Colors.indigo[700],
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
      ),
      // MENGGUNAKAN LAYOUTBUILDER AGAR RESPONSIF
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Menentukan jumlah kolom berdasarkan lebar layar
          int crossAxisCount = 2; // Default untuk HP biasa

          if (constraints.maxWidth >= 1200) {
            crossAxisCount =
                5; // Layar monitor besar / tablet landscape sangat lebar
          } else if (constraints.maxWidth >= 900) {
            crossAxisCount =
                4; // Tablet Landscape (Sesuai dengan gambar Anda yang memiliki 4 kolom)
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 3; // Tablet Portrait
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, // Kolom berubah dinamis di sini
              childAspectRatio:
                  1.8, // Menyesuaikan proporsi kotak agar tidak terlalu tinggi saat melebar
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () {
                    if (item['name'] == 'Work') {
                      _showWorkCategoryDialog(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: item['color'],
                          radius: 24,
                          child: Icon(
                            item['icon'],
                            color: Colors.white,
                            size: 24,
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
                                '${item['tasks']} tasks',
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
}
