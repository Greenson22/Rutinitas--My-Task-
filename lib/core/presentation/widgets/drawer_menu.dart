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
          ListTile(
            leading: Icon(
              Icons.format_list_bulleted,
              color: !widget.isDailyActive && !widget.isJurnalActive
                  ? Colors.indigo
                  : Colors.grey[700],
            ),
            title: const Text('Task Master'),
            onTap: () {
              Navigator.pop(context);
              if (widget.isDailyActive || widget.isJurnalActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.checklist_rtl,
              color: widget.isDailyActive ? Colors.indigo : Colors.grey[700],
            ),
            title: const Text('My Checklist'),
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
          ListTile(
            leading: Icon(
              Icons.menu_book,
              color: widget.isJurnalActive ? Colors.indigo : Colors.grey[700],
            ),
            title: const Text('Jurnal Aktivitas'),
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
          ListTile(
            leading: Icon(
              Icons.storage,
              color: Colors
                  .grey[700], // Sesuaikan logika warna aktif jika memakai parameter
            ),
            title: const Text('Data Center'),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
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
}
