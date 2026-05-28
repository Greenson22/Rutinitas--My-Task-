// lib/core/presentation/widgets/drawer_menu.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../features/task_master/presentation/screens/home_screen.dart';
import '../../../features/daily/presentation/screens/daily_screen.dart';
import '../../../features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart';
import '../../../features/about/presentation/pages/about_page.dart';
import '../../../features/task_master/presentation/widgets/settings_dialog.dart';
import '../../services/storage_service.dart';
import '../../../features/data_center/presentation/screens/data_center_screen.dart';

class DrawerMenu extends StatefulWidget {
  final bool isDailyActive;
  final bool isJurnalActive;
  final bool isDataCenterActive;

  const DrawerMenu({
    super.key,
    this.isDailyActive = false,
    this.isJurnalActive = false,
    this.isDataCenterActive =
        false, // Default-nya false agar halaman lain tidak error
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final StorageService _storageService = StorageService();
  String _selectedBaseDir = 'Documents';

  @override
  void initState() {
    super.initState();
    _loadBaseDir();
  }

  Future<void> _loadBaseDir() async {
    String baseDir = await _storageService.getBaseDirSetting();
    if (mounted) setState(() => _selectedBaseDir = baseDir);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        currentBaseDir: _selectedBaseDir,
        onSave: (newDir) async {
          await _storageService.saveBaseDirSetting(newDir);
          if (mounted) {
            setState(() => _selectedBaseDir = newDir);
            // Me-refresh halaman yang sedang aktif agar data dari folder baru dimuat
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => widget.isDailyActive
                    ? const DailyScreen()
                    : widget.isJurnalActive
                    ? const JurnalAktivitasScreen()
                    : const HomeScreen(),
              ),
            );
          }
        },
      ),
    );
  }

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
              children: [
                Text(
                  'M',
                  style: TextStyle(
                    color: Colors.indigo[900],
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
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
          // DI DALAM WIDGET BUILD (CHILDREN LISTVIEW):

          // 1. Menu Task Master
          _buildMenuTile(
            icon: Icons.format_list_bulleted,
            title: 'Task Master',
            isActive:
                !widget.isDailyActive &&
                !widget.isJurnalActive &&
                !widget.isDataCenterActive,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),

          // 2. Menu My Checklist
          _buildMenuTile(
            icon: Icons.checklist_rtl,
            title: 'My Checklist',
            isActive: widget.isDailyActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isDailyActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DailyScreen()),
                );
              }
            },
          ),

          // 3. Menu Jurnal Aktivitas
          _buildMenuTile(
            icon: Icons.menu_book,
            title: 'Jurnal Aktivitas',
            isActive: widget.isJurnalActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isJurnalActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JurnalAktivitasScreen(),
                  ),
                );
              }
            },
          ),

          // 4. Menu Data Center
          _buildMenuTile(
            icon: Icons.storage,
            title: 'Data Center',
            isActive: widget.isDataCenterActive,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataCenterScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.grey[700]),
            title: const Text('Settings'),
            subtitle: Text(
              _selectedBaseDir,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
            onTap: () {
              Navigator.pop(context);
              _showSettingsDialog(); // Tombol Settings sekarang memanggil dialog secara mandiri
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey[700]),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const Dialog(
                  child: SizedBox(width: 500, height: 650, child: AboutPage()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // FUNGSI HELPER UNTUK MEMBUAT MENU TILE SECARA OTOMATIS
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: isActive,
      selectedTileColor: Colors.indigo.withOpacity(
        0.15,
      ), // Efek highlight mengelilingi
      selectedColor: Colors.indigo[900], // Warna ikon & teks saat aktif
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ), // Membuat sudut melengkung/capsule
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
