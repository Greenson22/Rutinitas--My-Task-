// lib/core/presentation/widgets/settings_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _tempSelection = widget.currentBaseDir;
    _loadEncryptionSettings();
  }

  Future<void> _loadEncryptionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEncryptionEnabled = prefs.getBool('is_encrypted') ?? false;
      _rememberPassword = prefs.getBool('remember_password') ?? false;
      // Membaca status fitur eksperimental, defaultnya false
      _enableRandomGenerator =
          prefs.getBool('enable_random_generator') ?? false;
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
