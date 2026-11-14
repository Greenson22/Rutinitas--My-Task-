// lib/core/presentation/widgets/drawer_menu.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT SHAREDPREFERENCES
import '../../../features/task_master/presentation/screens/task_master_screen.dart';
import '../../../features/task_master_new/task_master_new.dart';
import '../../../features/checklist/presentation/checklist_screen/checklist_screen.dart';
import '../../../features/notes/presentation/screens/note_screen.dart';
import '../../../features/jurnal_aktivitas/presentation/screens/jurnal_aktivitas_screen.dart';
import '../../../features/prompt/presentation/screens/prompt_screen.dart';
import '../../../features/data_center/presentation/data_center_screen.dart';
import '../../../features/about/presentation/pages/about_page.dart';
import 'package:rutinitasku/core/presentation/widgets/settings_dialog.dart';
import '../../../features/random/presentation/screens/random_screen.dart'; // IMPORT SCREEN BARU
import '../../../features/documents/presentation/screens/document_screen.dart'; // IMPORT SKRIN MYDOCUMENTS BARU
import '../../services/storage_service.dart';

class DrawerMenu extends StatefulWidget {
  final bool isDailyActive;
  final bool isJurnalActive;
  final bool isDataCenterActive;
  final bool isPromptActive;
  final bool isNotesActive;
  final bool isRandomActive; // TAMBAHKAN PROPERTI INI
  final bool isDocumentsActive; // TAMBAHKAN PROPERTI UNTUK DOCUMENTS
  final bool isTaskMasterNewActive;

  const DrawerMenu({
    super.key,
    this.isDailyActive = false,
    this.isJurnalActive = false,
    this.isDataCenterActive = false,
    this.isPromptActive = false,
    this.isNotesActive = false,
    this.isRandomActive = false, // BERI DEFAULT VALUE FALSE
    this.isDocumentsActive = false, // BERI DEFAULT VALUE FALSE UNTUK DOCUMENTS
    this.isTaskMasterNewActive = false,
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final StorageService _storageService = StorageService();
  String _selectedBaseDir = 'Documents';
  bool _showRandomGeneratorMenu = false; // State visibilitas Random Generator

  @override
  void initState() {
    super.initState();
    _loadBaseDir();
    _checkRandomMenuVisibility(); // Jalankan pengecekan visibilitas menu
  }

  Future<void> _loadBaseDir() async {
    String baseDir = await _storageService.getBaseDirSetting();
    if (mounted) setState(() => _selectedBaseDir = baseDir);
  }

  // Fungsi pengecekan visibilitas menu berdasarkan Shared Preferences (default: false)
  Future<void> _checkRandomMenuVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final isAllowed = prefs.getBool('enable_random_generator') ?? false;
    if (mounted) {
      setState(() {
        _showRandomGeneratorMenu = isAllowed;
      });
    }
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
            _reloadActiveScreen();
          }
        },
        onEncryptionToggled: () {
          if (mounted) {
            _reloadActiveScreen();
          }
        },
      ),
    ).then((_) {
      // Refresh visibilitas menu setelah dialog pengaturan ditutup
      _checkRandomMenuVisibility();
    });
  }

  // Helper untuk navigasi ulang setelah pengaturan berubah
  void _reloadActiveScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => widget.isTaskMasterNewActive
            ? const TaskMasterNewScreen()
            : widget.isDailyActive
            ? const DailyScreen()
            : widget.isJurnalActive
            ? const JurnalAktivitasScreen()
            : widget.isDataCenterActive
            ? const DataCenterScreen()
            : widget.isPromptActive
            ? const PromptScreen()
            : widget.isNotesActive
            ? const NotesScreen()
            : widget.isRandomActive
            ? const RandomScreen() // DUKUNG REFRESH DI RANDOM SCREEN
            : widget.isDocumentsActive
            ? const MyDocumentsScreen() // DUKUNG REFRESH DI DOCUMENTS SCREEN
            : const HomeScreen(),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[800]!, Colors.indigo[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.assignment_turned_in,
                        color: Colors.indigo[900],
                        size: 28,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                const Text(
                  'My Tasks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // 1. Menu Task Master (Utama)
          _buildMenuTile(
            icon: Icons.format_list_bulleted,
            title: 'Task Master',
            isActive:
                !widget.isDailyActive &&
                !widget.isJurnalActive &&
                !widget.isDataCenterActive &&
                !widget.isPromptActive &&
                !widget.isNotesActive &&
                !widget.isRandomActive &&
                !widget.isDocumentsActive &&
                !widget
                    .isTaskMasterNewActive, // PASTIKAN MATI JIKA DOCUMENTS AKTIF
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),

          // 1b. Menu Task Master New (beta, tampilan baca-saja)
          _buildMenuTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Task Master New',
            isActive: widget.isTaskMasterNewActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isTaskMasterNewActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskMasterNewScreen(),
                  ),
                );
              }
            },
          ),

          // 2. Menu My Checklist
          _buildMenuTile(
            icon: Icons.checklist_rtl,
            title: 'MyChecklist',
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

          // 3. Menu Catatan
          _buildMenuTile(
            icon: Icons.note_alt_outlined,
            title: 'MyNote',
            isActive: widget.isNotesActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isNotesActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NotesScreen()),
                );
              }
            },
          ),

          // 4. Menu Jurnal Aktivitas
          _buildMenuTile(
            icon: Icons.menu_book,
            title: 'Activity Jurnal',
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

          // 5. Menu Prompt
          _buildMenuTile(
            icon: Icons.psychology_alt,
            title: 'MyPrompt',
            isActive: widget.isPromptActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isPromptActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PromptScreen()),
                );
              }
            },
          ),

          // 6. BARU: Menu My Documents (Pindah ke posisi ini)
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: 'My Documents',
            isActive: widget.isDocumentsActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isDocumentsActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyDocumentsScreen(),
                  ),
                );
              }
            },
          ),

          // 7. Menu Random Generator (Dikondisikan berdasarkan pengaturan Fitur Eksperimental)
          if (_showRandomGeneratorMenu)
            _buildMenuTile(
              icon: Icons.casino_outlined,
              title: 'Random Generator',
              isActive: widget.isRandomActive,
              onTap: () {
                Navigator.pop(context);
                if (!widget.isRandomActive) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RandomScreen(),
                    ),
                  );
                }
              },
            ),

          // 8. Menu Data Center (Utilitas Penyimpanan)
          _buildMenuTile(
            icon: Icons.storage,
            title: 'Data Center',
            isActive: widget.isDataCenterActive,
            onTap: () {
              Navigator.pop(context);
              if (!widget.isDataCenterActive) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataCenterScreen(),
                  ),
                );
              }
            },
          ),

          const Divider(),

          // 9. Settings
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.blueGrey[700]),
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _selectedBaseDir,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey[400]),
            ),
            onTap: () {
              Navigator.pop(context);
              _showSettingsDialog();
            },
          ),

          const Divider(),

          // 10. About
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.orangeAccent),
            title: const Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isActive,
        selectedTileColor: Colors.indigo.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: isActive ? Colors.indigo[700] : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.indigo[900] : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
