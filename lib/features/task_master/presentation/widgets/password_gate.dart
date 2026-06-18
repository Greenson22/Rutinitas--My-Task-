// lib/features/task_master/presentation/widgets/password_gate.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/storage_service.dart';

class PasswordGate extends StatefulWidget {
  final Widget child;
  const PasswordGate({super.key, required this.child});

  @override
  State<PasswordGate> createState() => _PasswordGateState();
}

class _PasswordGateState extends State<PasswordGate> {
  bool _isChecking = true;
  bool _needsPassword = false;
  bool _obscurePassword = true;
  int _selectedTimeout = 5; // Default 5 menit
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
    // Daftarkan listener untuk mendengarkan perubahan status timeout dari timer StorageService
    StorageService.sessionExpiredNotifier.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    StorageService.sessionExpiredNotifier.removeListener(_onSessionExpired);
    _passwordController.dispose();
    super.dispose();
  }

  void _onSessionExpired() {
    if (StorageService.sessionExpiredNotifier.value != null) {
      // PERBAIKAN: Hapus atau komentari baris Navigator.of(context).popUntil karena
      // PasswordGate berada di atas Navigator global, sehingga tidak memiliki akses Navigator context.
      // Navigator.of(context).popUntil((route) => route.isFirst);

      // Cukup ubah state untuk menampilkan form kata sandi secara global
      setState(() {
        _needsPassword = true;
        _isChecking = false;
        _passwordController.clear();
      });
    }
  }

  Future<void> _checkSecurityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isEncrypted = prefs.getBool('is_encrypted') ?? false;
    bool rememberPassword = prefs.getBool('remember_password') ?? false;

    // Memuat preferensi batas waktu sesi yang disimpan sebelumnya
    setState(() {
      _selectedTimeout = prefs.getInt('session_timeout_minutes') ?? 5;
    });

    if (isEncrypted &&
        !rememberPassword &&
        StorageService.sessionPassword == null) {
      setState(() {
        _needsPassword = true;
        _isChecking = false;
        _passwordController.clear();
      });
    } else if (isEncrypted) {
      // Jika lolos, restart timer
      await StorageService().restartSessionTimer();
      setState(() {
        _isChecking = false;
      });
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _unlockApplication() async {
    final textInput = _passwordController.text.trim();

    // Hapus peringatan kedaluwarsa setelah mencoba membuka lagi
    StorageService.sessionExpiredNotifier.value = null;

    if (textInput.isEmpty) {
      setState(() {
        _needsPassword = false;
      });
      return;
    }

    // Simpan penentuan batas waktu sesi baru ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_timeout_minutes', _selectedTimeout);

    StorageService.sessionPassword = textInput;
    // Nyalakan ulang perhitungan timer menggunakan konfigurasi waktu yang baru
    StorageService().restartSessionTimer();

    setState(() {
      _needsPassword = false;
      // Bersihkan input setelah berhasil masuk agar tidak tersimpan di memori controller
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    if (_needsPassword) {
      final String? expiredMsg = StorageService.sessionExpiredNotifier.value;

      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_person_outlined,
                    size: 60,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dekripsi Berkas Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fitur keamanan aktif. Masukkan kata sandi berkas Anda untuk masuk ke aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // --- BANNER PERINGATAN KEDALUWARSA WAKTU ---
                  if (expiredMsg != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_off,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              expiredMsg,
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- DROPDOWN BATAS WAKTU SESI ---
                  DropdownButtonFormField<int>(
                    value: _selectedTimeout,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Batas Waktu Sesi Aktif',
                      prefixIcon: Icon(Icons.timer_outlined),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 Menit')),
                      DropdownMenuItem(value: 5, child: Text('5 Menit')),
                      DropdownMenuItem(value: 15, child: Text('15 Menit')),
                      DropdownMenuItem(value: 30, child: Text('30 Menit')),
                      DropdownMenuItem(value: 60, child: Text('1 Jam')),
                      DropdownMenuItem(
                        value: 0,
                        child: Text('Tanpa Batas Waktu'),
                      ), // Perubahan di sini
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTimeout = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Kata Sandi Enkripsi',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) => _unlockApplication(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _unlockApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text(
                        'Buka Aplikasi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
