import 'package:flutter/material.dart';

class TaskMasterLoadingView extends StatelessWidget {
  const TaskMasterLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.indigo),
          SizedBox(height: 16),
          Text(
            'Memuat data Task Master...',
            style: TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

/// Empty state saat belum ada kategori sama sekali.
class TaskMasterEmptyView extends StatelessWidget {
  const TaskMasterEmptyView({
    super.key,
    required this.onRefresh,
    this.onCreateCategory,
  });

  final VoidCallback onRefresh;

  /// Mengarahkan pengguna baru untuk membuat kategori pertama.
  final VoidCallback? onCreateCategory;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.playlist_add_check_circle_outlined,
                size: 62,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum ada kategori',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat kategori pertama untuk mulai mengelompokkan rutinitas '
              'Anda. Setiap kategori bisa diberi nama dan ikon emoji.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (onCreateCategory != null)
                  FilledButton.icon(
                    key: const Key('emptyCreateCategoryButton'),
                    onPressed: onCreateCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Buat kategori pertama'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat Ulang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state ringan ketika kategori sudah ada tetapi belum ada tugas yang
/// perlu dikerjakan hari ini.
class EmptyTodayTasksView extends StatelessWidget {
  const EmptyTodayTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('emptyTodayTasks'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada tugas hari ini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Tugas dengan pengaturan "Selalu", atau "Otomatis" yang memiliki '
            'target harian, target total, atau aktivitas hari ini akan muncul '
            'di sini. Anda dapat mengubah pengaturan Tampil di Hari Ini lewat '
            'form atau menu baris tugas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.blueGrey[700],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ditampilkan ketika semua kategori sedang disembunyikan.
class HiddenCategoriesView extends StatelessWidget {
  const HiddenCategoriesView({super.key, required this.onShowHidden});

  final VoidCallback onShowHidden;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('hiddenCategoriesView'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.visibility_off_outlined, size: 38, color: Colors.blueGrey),
          const SizedBox(height: 10),
          const Text(
            'Semua kategori disembunyikan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Aktifkan "Tampilkan tersembunyi" untuk mengelola kategori ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey[700]),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('showHiddenFromEmptyButton'),
            onPressed: onShowHidden,
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Tampilkan tersembunyi'),
          ),
        ],
      ),
    );
  }
}

/// Empty state saat pencarian atau filter tidak menemukan tugas.
class SearchEmptyView extends StatelessWidget {
  const SearchEmptyView({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('searchEmptyState'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada hasil',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Coba kata kunci lain, atau hapus pencarian dan filter untuk '
            'melihat semua tugas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('clearSearchFiltersButton'),
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
            label: const Text('Hapus pencarian dan filter'),
          ),
        ],
      ),
    );
  }
}

class TaskMasterErrorView extends StatelessWidget {
  const TaskMasterErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onUnlockWithPin,
    this.onRestoreBackup,
    this.onCreateNewFile,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  /// Opsi pemulihan; hanya ditampilkan bila relevan dengan jenis kegagalan.
  final VoidCallback? onUnlockWithPin;
  final VoidCallback? onRestoreBackup;
  final VoidCallback? onCreateNewFile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_maybe_rounded,
                size: 62,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  key: const Key('retryLoadButton'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                if (onUnlockWithPin != null)
                  FilledButton.icon(
                    key: const Key('unlockWithPinButton'),
                    onPressed: onUnlockWithPin,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('Masukkan PIN'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                if (onRestoreBackup != null)
                  OutlinedButton.icon(
                    key: const Key('restoreBackupButton'),
                    onPressed: onRestoreBackup,
                    icon: const Icon(
                      Icons.settings_backup_restore_rounded,
                      size: 18,
                    ),
                    label: const Text('Pulihkan backup'),
                  ),
                if (onCreateNewFile != null)
                  OutlinedButton.icon(
                    key: const Key('createNewFileButton'),
                    onPressed: onCreateNewFile,
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Buat file baru'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
