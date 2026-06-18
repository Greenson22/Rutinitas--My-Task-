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
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isEncrypted = prefs.getBool('is_encrypted') ?? false;
    bool rememberPassword = prefs.getBool('remember_password') ?? false;

    // Kunci aplikasi jika enkripsi aktif tetapi RAM kosong & opsi ingat password mati
    if (isEncrypted &&
        !rememberPassword &&
        StorageService.sessionPassword == null) {
      setState(() {
        _needsPassword = true;
        _isChecking = false;
      });
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _unlockApplication() {
    final textInput = _passwordController.text.trim();
    if (textInput.isNotEmpty) {
      // Masukkan ke memori RAM global agar modul json penulisan/pembacaan dapat menggunakannya
      StorageService.sessionPassword = textInput;
      setState(() {
        _needsPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    // Jika membutuhkan sandi, tampilkan Form Kunci Fullscreen
    if (_needsPassword) {
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Kata Sandi Enkripsi',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                      isDense: true,
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
