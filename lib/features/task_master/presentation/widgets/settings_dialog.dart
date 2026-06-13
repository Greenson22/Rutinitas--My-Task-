// lib/features/task_master/presentation/widgets/settings_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Pastikan path import StorageService ini sudah sesuai dengan struktur proyek Anda
import '../../../../core/services/storage_service.dart';

class SettingsDialog extends StatefulWidget {
  final String currentBaseDir;
  final Function(String) onSave;

  const SettingsDialog({
    super.key,
    required this.currentBaseDir,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _tempSelection;
  bool _isEncryptionEnabled = false;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _tempSelection = widget.currentBaseDir;
    _loadEncryptionSettings();
  }

  /// Memuat status enkripsi saat ini dari SharedPreferences
  Future<void> _loadEncryptionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEncryptionEnabled = prefs.getBool('is_encrypted') ?? false;
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

  /// Menangani aksi ketika toggle switch enkripsi diubah (aktif/nonaktif)
  Future<void> _handleEncryptionToggle(bool value) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    // Tampilkan modal dialog untuk meminta konfirmasi kata sandi dari pengguna
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
                      ? 'Masukkan kata sandi untuk mengamankan data berkas catatan (.json) Anda. Jangan sampai lupa!'
                      : 'Masukkan kata sandi Anda saat ini untuk mengembalikan berkas terenkripsi menjadi teks .json biasa.',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    labelStyle: const TextStyle(fontSize: 14),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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

    // Jika pengguna menekan tombol konfirmasi/setuju
    if (confirmed == true) {
      final inputPassword = passwordController.text.trim();

      if (!mounted) return;
      // Tampilkan indikator loading (CircularProgressIndicator) selama proses enkripsi/dekripsi massal berlangsung
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Eksekusi migrasi data pada StorageService
        await _storageService.migrateFilesEncryption(value, inputPassword);

        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog loading

        setState(() {
          _isEncryptionEnabled = value;
        });

        // Berikan feedback sukses kepada pengguna
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Semua berkas berhasil dienkripsi!'
                  : 'Enkripsi dinonaktifkan, berkas kembali normal.',
            ),
            backgroundColor: Colors.teal,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog loading jika gagal

        // Berikan feedback error (misal password salah saat proses dekripsi)
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

            // =================================================================
            // === KOMPONEN BARU: SWITCH TOGGLE UTK FITUR ENKRIPSI DATA ===
            // =================================================================
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isEncryptionEnabled
                      ? Colors.teal.withAlpha(30)
                      : Colors.grey.withAlpha(30),
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
                'Gunakan AES-256 untuk mengamankan data catatan.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              trailing: Switch(
                value: _isEncryptionEnabled,
                activeColor: Colors.teal,
                onChanged: _handleEncryptionToggle,
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

  // Helper Widget untuk membuat list informasi folder yang rapi
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
