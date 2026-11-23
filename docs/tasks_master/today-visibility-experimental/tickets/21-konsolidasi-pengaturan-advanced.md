# 21: Satu pintu pengaturan di Advanced Task Master New

**What to build:** Entri “Pengaturan folder & enkripsi” dihapus dari sheet Advanced `task_master_new`. Settings hanya dibuka dari sidebar/drawer, sehingga tidak ada dua jalur pengaturan.

**Blocked by:** None (can start immediately).

**Status:** done

- [x] `TaskMasterAdvancedSheet` hanya berisi item “Editor JSON mentah”.
- [x] Callback `onOpenSettings` dihapus dari sheet dan pemanggilnya.
- [x] Aksi `settings` pada alur Advanced dan fungsi pembuka Settings di layar baru dihapus.
- [x] Dependensi layanan penyimpanan pada layar Task Master New dihapus bila tidak lagi dipakai jalur lain.
- [x] Settings tetap dapat dibuka dari `DrawerMenu` dan tetap menampilkan opsi folder serta enkripsi.
- [x] Dialog Settings modul lama tidak diubah dan tetap berfungsi saat modul lama aktif.
- [x] Tidak ada jalur Settings kedua di layar Task Master New, baik di mobile maupun desktop.
- [x] Widget test: sheet Advanced hanya memiliki satu tile, dan tidak ada aksi yang membuka Settings dari layar Task Master New.
- [x] Tidak ada import dialog Settings yang tersisa di modul baru bila tidak lagi dibutuhkan.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

- **Waktu pengerjaan & build:** 2026-11-23T08:02:17+08:00
- **Perubahan kode:**
  - `TaskMasterAdvancedSheet` (`task_master_advanced_sheet.dart`): Menghapus callback `onOpenSettings` dan tile `openSettingsTile` ("Pengaturan folder & enkripsi"). Hanya menyisakan tile "Editor JSON mentah".
  - `TaskMasterNewScreen` (`task_master_screen.dart`):
    - Menghapus import `settings_dialog.dart` dan `storage_service.dart`.
    - Menghapus field `storageService` dari constructor dan State widget.
    - Menghapus method `_openSettings()` dan enum value `_AdvancedAction.settings`.
    - Memastikan sheet Advanced hanya memanggil `_openRawJsonEditor()`.
  - Tests (`recovery_test.dart`):
    - Memperbarui pengujian `editor JSON Advanced memvalidasi sebelum menyimpan` untuk memastikan `openSettingsTile` tidak lagi ada di sheet.
    - Menambahkan widget test eksplisit: `sheet Advanced hanya memiliki satu tile (Editor JSON mentah) dan tidak ada jalur Settings di Task Master New`.
- **Hasil Verifikasi:**
  - `flutter analyze lib/features/task_master_new test/features/task_master_new`: Lulus (0 issues).
  - `flutter test test/features/task_master_new/`: Lulus (285 passing tests).
  - `flutter test test/features/task_master/`: Lulus (9 passing tests).
