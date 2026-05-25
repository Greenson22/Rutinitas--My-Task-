// lib/features/task_master/presentation/widgets/drawer_menu.dart

import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../../../daily/presentation/screens/daily_screen.dart';
import '../../../jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart';
import '../../../about/presentation/pages/about_page.dart'; // <--- IMPORT SEUSAI PATH ABOUT PAGE

class DrawerMenu extends StatelessWidget {
  final String selectedBaseDir;
  final String fullJsonPath;
  final VoidCallback onOpenSettings;
  final bool isDailyActive;
  final bool isJurnalActive;

  const DrawerMenu({
    super.key,
    required this.selectedBaseDir,
    required this.fullJsonPath,
    required this.onOpenSettings,
    this.isDailyActive = false,
    this.isJurnalActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Text(
                      'M',
                      style: TextStyle(
                        color: Colors.indigo[900],
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 0,
                      child: Icon(
                        Icons.edit_calendar_outlined,
                        color: Colors.indigo[700],
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.indigo[900],
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          _buildDrawerItem(
            Icons.format_list_bulleted,
            'Task Master',
            isSelected: !isDailyActive && !isJurnalActive,
            onTap: () {
              Navigator.pop(context);
              if (isDailyActive || isJurnalActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
          ),
          _buildDrawerItem(
            Icons.wb_sunny_outlined,
            'Daily',
            isSelected: isDailyActive,
            onTap: () {
              Navigator.pop(context);
              if (!isDailyActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DailyScreen()),
                );
              }
            },
          ),
          _buildDrawerItem(
            Icons.menu_book,
            'Jurnal Aktivitas',
            isSelected: isJurnalActive,
            onTap: () {
              Navigator.pop(context);
              if (!isJurnalActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JurnalAktivitasScreen(),
                  ),
                );
              }
            },
          ),

          // PERBAIKAN: Item Weekly dan Monthly telah dihapus dari sini
          const Divider(),
          _buildDrawerItem(
            Icons.settings,
            'Settings',
            subtitle: '~/mytask/',
            onTap: () {
              Navigator.pop(context);
              onOpenSettings();
            },
          ),
          const Divider(),
          _buildDrawerItem(
            Icons.info_outline,
            'About',
            subtitle: 'Path: $fullJsonPath',
            onTap: () {
              Navigator.pop(context); // Tutup drawer menu terlebih dahulu

              // Membuka AboutPage sebagai sebuah Dialog Box
              showDialog(
                context: context,
                builder: (context) => const Dialog(
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    child: SizedBox(
                      width:
                          500, // Batasan lebar agar proporsional di tablet/desktop
                      height:
                          650, // Batasan tinggi wajib agar TabBarView tidak meluber (unbounded height)
                      child: AboutPage(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
