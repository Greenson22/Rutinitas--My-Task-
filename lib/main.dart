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
      theme: ThemeData(
        primarySwatch:
            Colors.indigo, // Diubah ke Indigo agar sesuai tema sidebar
        useMaterial3: false,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Data dummy kategori
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Task Master'),
        backgroundColor: Colors.indigo[700],
        // Hamburger menu akan otomatis muncul karena kita menambahkan 'drawer'
      ),
      // --- PENAMBAHAN SIDEBAR (DRAWER) DI SINI ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Sidebar
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
            // Menu Items
            _buildDrawerItem(
              Icons.format_list_bulleted,
              'Task Master',
              context,
              isSelected: true,
            ),
            _buildDrawerItem(Icons.wb_sunny_outlined, 'Daily', context),
            _buildDrawerItem(Icons.calendar_today, 'Weekly', context),
            _buildDrawerItem(Icons.calendar_month, 'Monthly', context),
            const Divider(), // Garis pemisah
            _buildDrawerItem(Icons.settings, 'Settings', context),
            const Divider(), // Garis pemisah
            _buildDrawerItem(Icons.info_outline, 'About', context),
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
                    if (item['name'] == 'Work')
                      _showWorkCategoryDialog(context);
                  },
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
                        const Icon(
                          Icons.more_vert,
                          color: Colors.grey,
                          size: 20,
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

  // Widget pendukung untuk item menu di drawer
  Widget _buildDrawerItem(
    IconData icon,
    String title,
    BuildContext context, {
    bool isSelected = false,
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
      onTap: () => Navigator.pop(context), // Menutup drawer saat diklik
    );
  }

  void _showWorkCategoryDialog(BuildContext context) {
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  _buildPopupItem('Career', '+0 / 4 hari ini | Total: 625'),
                  _buildPopupItem('New Tech', '+0 / 1 hari ini | Total: 4'),
                  _buildPopupItem('Coding', 'Total: 203'),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupItem(String title, String subtitle) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.more_vert),
    );
  }
}
