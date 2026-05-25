// lib/features/task_master/presentation/widgets/drawer_menu.dart

import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../../../daily/presentation/screens/daily_screen.dart';

class DrawerMenu extends StatelessWidget {
  final String selectedBaseDir;
  final String fullJsonPath;
  final VoidCallback onOpenSettings;
  final bool isDailyActive;

  const DrawerMenu({
    super.key,
    required this.selectedBaseDir,
    required this.fullJsonPath,
    required this.onOpenSettings,
    this.isDailyActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER DRAWER BARU: SESUAI GAMBAR MENGGUNAKAN "My Tasks"
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
                // Representasi Ikon/Logo gabungan MT & Kalender Checklist
                Stack(
                  alignment:
                      Alignment.bottomRight, // -> Diperbaiki dari Alianment
                  children: [
                    Text(
                      'M',
                      style: TextStyle(
                        color: Colors.indigo[900],
                        fontSize: 44,
                        fontWeight: FontWeight
                            .w900, // -> Diperbaiki dari FontWeight.black
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
                // Teks Nama Utama Aplikasi
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

          // DAFTAR FITUR DI DALAMNYA
          _buildDrawerItem(
            Icons.format_list_bulleted,
            'Task Master',
            isSelected: !isDailyActive,
            onTap: () {
              Navigator.pop(context);
              if (isDailyActive) {
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
            onTap: () => Navigator.pop(context),
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
