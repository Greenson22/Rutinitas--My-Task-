import 'package:flutter/material.dart';

class TaskMasterEmptyState extends StatelessWidget {
  final VoidCallback onAddCategoryPressed;

  const TaskMasterEmptyState({super.key, required this.onAddCategoryPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Utama
            Icon(
              Icons.assignment_turned_in_rounded,
              size: 80,
              color: Colors.indigo[300],
            ),
            const SizedBox(height: 16),
            // Judul Informasi
            Text(
              'Mulai Langkah Produktif Anda!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 8),
            // Deskripsi Kegunaan Task Master
            Text(
              'Task Master membantu Anda melacak repetisi aktivitas, target progress bar, dan terhubung langsung dengan Jurnal Waktu 30 menit Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Tombol Aksi Menarik
            ElevatedButton.icon(
              onPressed: onAddCategoryPressed,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Buat Kategori Pertama',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
