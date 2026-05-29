import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class CategoryCard extends StatelessWidget {
  final TaskCategory category;
  final bool isEditMode; // <-- TAMBAHAN BARU
  final VoidCallback onLongPress; // <-- TAMBAHAN BARU
  final VoidCallback? onTap; // <--- Tambahkan tanda tanya (?) di sini
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isEditMode,
    required this.onLongPress,
    this.onTap, // <--- Sekarang tidak required lagi (bisa menerima null)
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        // Menggunakan Column agar panel tombol bisa berada di bawah
        children: [
          // Area Konten Utama Kategori
          Expanded(
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress, // Ditahan untuk masuk/keluar mode edit
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isEditMode ? 0 : 12),
                bottomRight: Radius.circular(isEditMode ? 0 : 12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo[50],
                      radius: 20,
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: category.isHidden
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${category.tasks.length} tasks',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Keterangan mata coret jika disembunyikan (opsional agar user tahu statusnya)
                    if (category.isHidden)
                      const Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // PANEL TOMBOL KONTROL DI BAWAH (Hanya muncul saat Mode Edit Aktif / Ditahan)
          // PANEL TOMBOL KONTROL DI BAWAH (Hanya muncul saat Mode Edit Aktif / Ditahan)
          if (isEditMode) ...[
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. Tombol Pindah Kiri
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    color: onMoveUp != null ? Colors.indigo : Colors.grey[300],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onMoveUp,
                  ),
                  // 2. Tombol Ubah/Edit
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                  ),
                  // 3. Tombol Sembunyikan/Tampilkan
                  IconButton(
                    icon: Icon(
                      category.isHidden
                          ? Icons.visibility
                          : Icons.visibility_off,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onToggleVisibility,
                  ),
                  // 4. Tombol Pindah Kanan
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    color: onMoveDown != null
                        ? Colors.indigo
                        : Colors.grey[300],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onMoveDown,
                  ),
                  // 5. Tombol Hapus
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
