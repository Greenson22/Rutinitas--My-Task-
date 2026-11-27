// lib/core/presentation/widgets/settings_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutinitasku/core/config/task_master_rollout.dart';
import 'package:rutinitasku/core/services/storage_service.dart';

class SettingsDialog extends StatefulWidget {
  final String currentBaseDir;
  final Function(String) onSave;
  final VoidCallback onEncryptionToggled;

  const SettingsDialog({
    super.key,
    required this.currentBaseDir,
    required this.onSave,
    required this.onEncryptionToggled,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _tempSelection;
  bool _isEncryptionEnabled = false;
  bool _rememberPassword = false;
  bool _enableRandomGenerator = false; // Flag untuk status Random Generator
  bool _enableAdBannerShowcase = false; // Flag untuk status Ad Banner Showcase
  bool _useNewTaskMaster = false; // Flag untuk Task Master New
  bool _showAdNoticeOnStartup = true; // Flag untuk dialog info iklan saat buka aplikasi

  // Settings Tampilan Checklist
  bool _sectionDefaultCollapsed = false;
  bool _checklistGroupsDefaultCollapsed = false;
  bool _sectionRememberCollapseState = true;

  // Settings Tampilan Sections (Notes, Prompt, Dokumen)
  bool _sectionsDefaultCollapsed = false;
  bool _sectionsRememberCollapseState = true;

  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _tempSelection = widget.currentBaseDir;
    _loadEncryptionSettings();
  }

  Future<void> _loadEncryptionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useNewModule = await getTaskMasterUseNewModule(useCache: false);
    setState(() {
      _isEncryptionEnabled = prefs.getBool('is_encrypted') ?? false;
      _rememberPassword = prefs.getBool('remember_password') ?? false;
      // Membaca status fitur eksperimental, defaultnya false
      _enableRandomGenerator =
          prefs.getBool('enable_random_generator') ?? false;
      _enableAdBannerShowcase =
          prefs.getBool('enable_ad_banner_showcase') ?? false;
      _useNewTaskMaster = useNewModule;
      _showAdNoticeOnStartup =
          prefs.getBool('show_ad_notice_on_startup') ?? true;

      // Settings Tampilan Checklist
      _sectionDefaultCollapsed =
          prefs.getBool('section_default_collapsed') ?? false;
      _sectionRememberCollapseState =
          prefs.getBool('section_remember_collapse_state') ?? true;
      _checklistGroupsDefaultCollapsed =
          prefs.getBool('checklist_groups_default_collapsed') ?? false;

      // Settings Tampilan Sections (Notes, Prompt, Dokumen)
      _sectionsDefaultCollapsed =
          prefs.getBool('sections_default_collapsed') ?? false;
      _sectionsRememberCollapseState =
          prefs.getBool('sections_remember_collapse_state') ?? true;
    });
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _tempSelection = selectedDirectory;
      });
    }
  }

  Future<void> _handleRememberPasswordToggle(bool value) async {
    if (!value) {
      setState(() {
        _rememberPassword = false;
      });
      await _storageService.setRememberPassword(false);
      return;
    }

    final passwordController = TextEditingController();
    bool obscurePassword = true;

    bool? validated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Konfirmasi Kata Sandi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan kata sandi enkripsi Anda saat ini untuk mengaktifkan fitur "Ingat Kata Sandi".',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Saat Ini',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed: () {
                        setModalState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final input = passwordController.text.trim();
                  if (input == StorageService.sessionPassword) {
                    Navigator.pop(ctx, true);
                  } else {
                    Navigator.pop(ctx, false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text(
                  'Verifikasi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (validated == true) {
      setState(() {
        _rememberPassword = true;
      });
      await _storageService.setRememberPassword(
        true,
        currentPassword: StorageService.sessionPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur "Ingat Kata Sandi" berhasil diaktifkan.'),
          backgroundColor: Colors.teal,
        ),
      );
    } else {
      setState(() {
        _rememberPassword = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kata sandi salah! Gagal mengaktifkan fitur ingat kata sandi.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEncryptionToggle(bool value) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              value
                  ? 'Aktifkan Pengaturan Enkripsi'
                  : 'Matikan Pengaturan Enkripsi',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value
                      ? 'Masukkan kata sandi induk baru yang akan digunakan untuk mengunci berkas data Anda secara otomatis.'
                      : 'Masukkan kata sandi saat ini untuk menonaktifkan sistem enkripsi global dan mendekripsi kembali data berkas.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed: () {
                        setModalState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final input = passwordController.text.trim();
                  if (input.isNotEmpty) {
                    Navigator.pop(ctx, true);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: Text(
                  value ? 'Setel Sandi' : 'Konfirmasi',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      final inputPassword = passwordController.text.trim();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );

      try {
        await _storageService.migrateFilesEncryption(
          value,
          inputPassword,
          remember: _rememberPassword,
        );

        if (!mounted) return;
        Navigator.pop(context); // Tutup loading spinner

        setState(() {
          _isEncryptionEnabled = value;
          if (!value) _rememberPassword = false;
        });

        widget.onEncryptionToggled();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Seluruh data fitur berhasil dienkripsi secara otomatis!'
                  : 'Sistem otentikasi enkripsi dinonaktifkan. Seluruh data berhasil didekripsi.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Proses gagal. Terjadi kesalahan konfigurasi crypto masal.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRandomGeneratorToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableRandomGenerator = value;
    });
    await prefs.setBool('enable_random_generator', value);
  }

  Future<void> _handleAdBannerShowcaseToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableAdBannerShowcase = value;
    });
    await prefs.setBool('enable_ad_banner_showcase', value);
  }

  Future<void> _handleTaskMasterNewToggle(bool value) async {
    if (value) {
      // Dialog konfirmasi untuk mengaktifkan
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Aktifkan Task Master New?'),
            ],
          ),
          content: const Text(
            'Task Master New adalah penulisan ulang modul pelacak kebiasaan yang sedang diuji.\n\n'
            'Fitur ini mencakup dashboard Hari Ini, riwayat sparse, streak harian, '
            'increment satu klik dengan undo, dan performa tinggi.\n\n'
            'Catatan: Fitur ini berstatus eksperimental. Perubahan modul akan berlaku '
            'setelah aplikasi dimulai ulang.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aktifkan'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _useNewTaskMaster = true;
        });
        await setTaskMasterUseNewModule(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Task Master New akan aktif setelah aplikasi dimulai ulang.',
            ),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    } else {
      // Dialog konfirmasi untuk menonaktifkan
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Kembali ke Modul Lama?'),
            ],
          ),
          content: const Text(
            'Perhatian sebelum menonaktifkan Task Master New:\n\n'
            '• Riwayat baru tersimpan dalam file v2; modul lama dapat membacanya '
            'tetapi tidak menampilkannya.\n'
            '• Detail tertentu (seperti riwayat hari ini) bisa tidak sinkron bila '
            'data diubah dari modul lama.\n\n'
            'Perubahan modul akan berlaku setelah aplikasi dimulai ulang.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Nonaktifkan'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _useNewTaskMaster = false;
        });
        await setTaskMasterUseNewModule(false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Modul lama akan aktif setelah aplikasi dimulai ulang.',
            ),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    }
  }

  Future<void> _handleSectionDefaultCollapsedToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('section_default_collapsed', value);
    setState(() {
      _sectionDefaultCollapsed = value;
    });
  }

  Future<void> _handleSectionRememberCollapseStateToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('section_remember_collapse_state', value);
    setState(() {
      _sectionRememberCollapseState = value;
    });
  }

  Future<void> _handleChecklistGroupsDefaultCollapsedToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checklist_groups_default_collapsed', value);
    setState(() {
      _checklistGroupsDefaultCollapsed = value;
    });
  }

  Future<void> _handleSectionsDefaultCollapsedToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sections_default_collapsed', value);
    setState(() {
      _sectionsDefaultCollapsed = value;
    });
  }

  Future<void> _handleSectionsRememberCollapseStateToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sections_remember_collapse_state', value);
    setState(() {
      _sectionsRememberCollapseState = value;
    });
  }

  Future<void> _handleShowAdNoticeToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_ad_notice_on_startup', value);
    setState(() {
      _showAdNoticeOnStartup = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pengaturan Folder Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Direktori Utama Saat Ini:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _tempSelection,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Platform.isAndroid
                ? const SizedBox.shrink()
                : ElevatedButton.icon(
                    onPressed: _pickDirectory,
                    icon: const Icon(Icons.folder_open, size: 20),
                    label: const Text('Pilih Folder Kustom'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEncryptionEnabled
                      ? Colors.teal.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEncryptionEnabled ? Icons.lock : Icons.lock_open,
                  color: _isEncryptionEnabled ? Colors.teal : Colors.grey[600],
                ),
              ),
              title: const Text(
                'Enkripsi Berkas (.json)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Gunakan AES-256 untuk mengamankan data berkas pilihan.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _isEncryptionEnabled,
                activeThumbColor: Colors.teal,
                onChanged: _handleEncryptionToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEncryptionEnabled
                      ? Colors.amber.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.memory,
                  color: _isEncryptionEnabled
                      ? Colors.amber[800]
                      : Colors.grey[600],
                ),
              ),
              title: const Text(
                'Ingat Kata Sandi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Jangan tanyakan sandi lagi saat aplikasi dibuka ulang.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _rememberPassword,
                activeThumbColor: Colors.amber[800],
                onChanged: _isEncryptionEnabled
                    ? _handleRememberPasswordToggle
                    : null,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // ==================== TAMPILAN CHECKLIST ====================
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  color: Colors.teal[700],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tampilan Checklist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tutup seksi secara default',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Seksi dimulai dalam kondisi terlipat saat halaman detail checklist dibuka.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _sectionDefaultCollapsed,
                activeThumbColor: Colors.teal,
                onChanged: _handleSectionDefaultCollapsedToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ingat status lipatan seksi',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Simpan status terbuka/terlipat masing-masing seksi antar sesi.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _sectionRememberCollapseState,
                activeThumbColor: Colors.teal,
                onChanged: _handleSectionRememberCollapseStateToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Checklist Groups: Tutup seksi secara default',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Seksi dimulai dalam kondisi terlipat saat layar Checklist Groups dibuka (bukan Checklist Detail).',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _checklistGroupsDefaultCollapsed,
                activeThumbColor: Colors.teal,
                onChanged: _handleChecklistGroupsDefaultCollapsedToggle,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // ==================== TAMPILAN SECTIONS ====================
            Row(
              children: [
                Icon(
                  Icons.view_agenda_outlined,
                  color: Colors.teal[700],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tampilan Sections (Notes, Prompt, Dokumen)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tutup seksi secara default',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Seksi dimulai dalam kondisi terlipat saat halaman utama Notes, Prompt, atau Dokumen dibuka.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _sectionsDefaultCollapsed,
                activeThumbColor: Colors.teal,
                onChanged: _handleSectionsDefaultCollapsedToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ingat status lipatan seksi',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Simpan status terbuka/terlipat masing-masing seksi antar sesi.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _sectionsRememberCollapseState,
                activeThumbColor: Colors.teal,
                onChanged: _handleSectionsRememberCollapseStateToggle,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),

            // ==================== FITUR EKSPERIMENTAL ====================
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Colors.deepPurple[700],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Fitur Eksperimental',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[900],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tampilkan Random Generator',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Aktifkan menu pembuatan angka/kategori acak di laci navigasi.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _enableRandomGenerator,
                activeThumbColor: Colors.deepPurple,
                onChanged: _handleRandomGeneratorToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ad Banner Showcase',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Tampilkan semua slot banner iklan sekaligus dalam satu layar.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _enableAdBannerShowcase,
                activeThumbColor: Colors.deepPurple,
                onChanged: _handleAdBannerShowcaseToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Task Master New',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Gunakan modul Task Master baru yang sedang diuji. '
                'Perubahan berlaku setelah aplikasi dimulai ulang.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _useNewTaskMaster,
                activeThumbColor: Colors.deepPurple,
                onChanged: _handleTaskMasterNewToggle,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tampilkan Info Iklan Saat Buka Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              subtitle: const Text(
                'Menampilkan pesan dukungan iklan setiap kali aplikasi baru dibuka.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _showAdNoticeOnStartup,
                activeThumbColor: Colors.deepPurple,
                onChanged: _handleShowAdNoticeToggle,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_tempSelection);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
