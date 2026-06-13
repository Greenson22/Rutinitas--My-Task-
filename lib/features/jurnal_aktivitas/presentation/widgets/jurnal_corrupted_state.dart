// lib/features/jurnal_aktivitas/presentation/widgets/jurnal_corrupted_state.dart
import 'package:flutter/material.dart';

class JurnalCorruptedState extends StatelessWidget {
  final VoidCallback onActionPressed;

  const JurnalCorruptedState({super.key, required this.onActionPressed});

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
              'Berkas Jurnal Terkunci / Rusak',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Aplikasi gagal memuat data Jurnal Aktivitas dari disk lokal Anda.\nStruktur penyimpanan teks JSON bermasalah atau memerlukan PIN dekripsi enkripsi AES-256 yang tepat untuk membukanya kembali.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(
                Icons.lock_open_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Buka Opsi Pemulihan Jurnal',
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
