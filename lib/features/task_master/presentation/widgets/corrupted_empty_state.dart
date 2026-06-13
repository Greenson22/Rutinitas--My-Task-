// lib/features/task_master/presentation/widgets/corrupted_empty_state.dart

import 'package:flutter/material.dart';

class CorruptedEmptyState extends StatelessWidget {
  final VoidCallback onRecoveryPressed;

  const CorruptedEmptyState({super.key, required this.onRecoveryPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gpp_maybe_rounded,
                size: 72,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Berkas Penyimpanan Terkunci / Rusak',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Aplikasi gagal memuat data Task Master di direktori lokal Anda.\nFormat teks JSON mungkin rusak atau memerlukan PIN dekripsi enkripsi AES-256 yang valid untuk dibuka kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRecoveryPressed,
              icon: const Icon(
                Icons.lock_open_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Buka Opsi Pemulihan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
