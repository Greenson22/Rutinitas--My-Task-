// lib/features/task_master/presentation/widgets/settings_dialog.dart

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
  bool _rememberPassword = false; // --- TAMBAHAN STATE BARU ---
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
      _rememberPassword =
          prefs.getBool('remember_password') ?? false; // Default false
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
              value ? 'Aktifkan Enkripsi AES-256' : 'Matikan Enkripsi',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value
                      ? 'Masukkan kata sandi untuk mengamankan seluruh data berkas (.json) Anda sekarang juga. Jangan sampai lupa!'
                      : 'Masukkan kata sandi saat ini untuk mendekripsi kembali semua berkas ke format teks biasa.',
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
                  if (passwordController.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, true);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: Text(
                  value ? 'Enkripsi Data' : 'Dekripsi Data',
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
        // MODIFIKASI: Meneruskan state _rememberPassword saat migrasi dijalankan
        await _storageService.migrateFilesEncryption(
          value,
          inputPassword,
          remember: _rememberPassword,
        );

        if (!mounted) return;
        Navigator.pop(context);

        setState(() {
          _isEncryptionEnabled = value;
          if (!value)
            _rememberPassword = false; // Ikut mati jika enkripsi dimatikan
        });

        widget.onEncryptionToggled();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Semua berkas data aplikasi berhasil dienkripsi!'
                  : 'Enkripsi dinonaktifkan, berkas kembali normal.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proses gagal. Kata sandi salah atau berkas rusak.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      ? Colors.teal.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
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
                'Gunakan AES-256 untuk mengamankan seluruh data berkas.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _isEncryptionEnabled,
                activeColor: Colors.teal,
                onChanged: _handleEncryptionToggle,
              ),
            ),

            // --- TAMBAHAN BARU: Switch Mengingat Kata Sandi (Selalu Ditampilkan) ---
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEncryptionEnabled
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
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
                activeColor: Colors.amber[800],
                // Hanya bisa diubah jika enkripsi berkas dalam kondisi aktif
                onChanged: _isEncryptionEnabled
                    ? (value) async {
                        setState(() {
                          _rememberPassword = value;
                        });
                        await _storageService.setRememberPassword(
                          value,
                          currentPassword: StorageService.sessionPassword,
                        );
                      }
                    : null,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.indigo[700], size: 18),
                const SizedBox(width: 6),
                Text(
                  'Informasi Penyimpanan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi akan otomatis membuat 3 subfolder berikut di dalam direktori terpilih untuk menyimpan data secara lokal:',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildFolderInfoItem('📁 /mytask', 'Data manajemen tugas utama'),
            _buildFolderInfoItem(
              '📁 /my_checklist',
              'Data pengaturan checklist hub',
            ),
            _buildFolderInfoItem(
              '📁 /jurnal_aktivitas',
              'Data log waktu produktif harian',
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

  Widget _buildFolderInfoItem(String folderName, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              folderName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            flex: 6,
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
