# 19: Saklar eksperimental Task Master New dan satu penulis

**What to build:** `task_master_new` diaktifkan lewat saklar runtime di Settings → Fitur Eksperimental, dengan default mati sehingga modul lama dipakai. Saat saklar hidup, modul baru menjadi satu-satunya penulis `my_tasks.json`; saat mati, modul lama yang menulis. Pergantian modul tidak boleh menghilangkan riwayat dan tidak boleh membuat dua modul menulis bersamaan.

**Blocked by:** 18 — Visibilitas Hari Ini per tugas (field baru harus sudah tersimpan sebelum penulis berganti).

**Status:** done

- [x] `taskMasterUseNewModule` tidak lagi konstanta compile-time; nilainya dibaca dari SharedPreferences `task_master_use_new_module` (default `false`).
- [x] Status “modul lama boleh menulis” diturunkan dari preferensi yang sama, bukan dari konstanta atau salinan statis.
- [x] `TaskMasterEntry` membaca preferensi saat dibangun, menampilkan indikator loading ringan, dan meng-cache hasilnya selama proses aplikasi berjalan agar navigasi berulang tidak berkedip.
- [x] Saat saklar mati: modul lama menjadi penulis; modul baru tidak menulis file.
- [x] Saat saklar hidup: modul baru menjadi penulis; seluruh jalur tulis modul lama ditolak, termasuk reset file, penyimpanan kategori, increment, penulisan Jurnal, dan editor JSON mentah.
- [x] Guard berada di lapisan logika dan membaca preferensi pada saat operasi, bukan hanya menyembunyikan tombol.
- [x] Guard tetap berlaku saat file gagal dibaca; tidak ada modul yang menulis setengah jalan.
- [x] Settings → Fitur Eksperimental memiliki item **Task Master New** dengan ikon dan warna section yang sama.
- [x] Mengaktifkan memunculkan dialog konfirmasi berisi ringkasan fitur dan catatan eksperimental.
- [x] Menonaktifkan memunculkan dialog berbeda yang menyebut: riwayat baru ada di file v2, modul lama dapat membaca tetapi tidak menampilkan, dan detail tertentu bisa tidak sinkron bila diubah dari modul lama.
- [x] Preferensi ditulis segera saat switch diubah, bukan saat tombol Simpan ditekan.
- [x] Setelah salah satu alur selesai, muncul pemberitahuan bahwa restart diperlukan; dialog Settings tetap dapat ditutup seperti biasa.
- [x] File terenkripsi tetap terbaca dan dapat ditulis setelah berganti modul.
- [x] `docs/tasks_master/ROLLBACK.md` diperbarui: rollback lewat Settings, bukan build ulang, beserta status penulis dan langkah verifikasi.
- [x] `docs/tasks_master/PARITY_QA.md` mendapat skenario ganti modul.
- [x] Unit test pembacaan preferensi dan penurunan status penulis.
- [x] Widget test: fresh install memakai modul lama, saklar hidup memakai modul baru, dialog konfirmasi aktif/nonaktif, preferensi tersimpan, notice restart tampil.
- [x] Test regresi “satu penulis”: tidak ada dua modul menulis file pada satu waktu, termasuk saat file gagal dibaca.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

- **Waktu implementasi & verifikasi build:** 2026-11-22T23:16:30+08:00
- **Modul Rollout Terpusat:** Di `lib/core/config/task_master_rollout.dart`:
  - `taskMasterUseNewModulePrefKey = 'task_master_use_new_module'`
  - `getTaskMasterUseNewModule({bool useCache = true})` membaca preferensi SharedPreferences (default `false`) dan menyediakannya melalui cache in-memory agar navigasi berulang instan.
  - `setTaskMasterUseNewModule(bool value)` menulis ke SharedPreferences segera saat saklar diubah.
  - `isTaskMasterLegacyWritesEnabled()` mengevaluasi kondisi satu penulis secara dinamis (`!useNewModule`) pada lapisan logika.
- **Guard Lapisan Logika Modul Lama:**
  - `TaskMasterController`: pemeriksaan dinamis `await isTaskMasterLegacyWritesEnabled()` diterapkan pada `initStorageAndLoadData` (`createDirectory`), `forceResetNewFile`, `incrementTaskCount`, `_addTimeToJurnal`, dan `saveAllCategoriesToFile`. Guard tetap aktif dan melindungi penulisan bahkan saat file korup / gagal dibaca.
  - `HomeScreen`: pemeriksaan dinamis `await isTaskMasterLegacyWritesEnabled()` diterapkan pada `_showEditRawJsonDialog`.
- **Titik Masuk `TaskMasterEntry`:**
  - Diubah menjadi `StatefulWidget` yang membaca `getTaskMasterUseNewModule(useCache: true)` secara asinkron dengan loading indicator ringan (`CircularProgressIndicator`), lalu merender `TaskMasterNewScreen` jika `true` atau `HomeScreen` jika `false`.
- **UI Settings (Fitur Eksperimental):**
  - Di `lib/core/presentation/widgets/settings_dialog.dart`, ditambahkan tile **Task Master New** di section Fitur Eksperimental dengan ikon `Icons.science_outlined` dan warna deep purple.
  - Toggle mengaktifkan menampilkan dialog konfirmasi ringkasan fitur baru dan catatan eksperimental.
  - Toggle menonaktifkan menampilkan dialog peringatan mengenai file v2 dan sinkronisasi modul lama.
  - Preferensi langsung ditulis saat konfirmasi tanpa menunggu tombol Simpan Settings, dan SnackBar pemberitahuan restart ditampilkan.
- **Dokumentasi Rollback & Parity:**
  - `docs/tasks_master/ROLLBACK.md` diperbarui dengan alur rollback runtime melalui menu Settings tanpa perlu kompilasi ulang kode.
  - `docs/tasks_master/PARITY_QA.md` diperbarui dengan skenario manual ganti modul serta catatan aturan satu penulis.
- **Pengujian Otomatis:**
  - Unit test pembacaan preferensi dan penurunan status penulis di `test/features/task_master_new/presentation/navigation_switch_test.dart`.
  - Widget test fresh install (`HomeScreen`), saklar hidup (`TaskMasterNewScreen`), tile Settings, dialog konfirmasi aktif/nonaktif, penyimpanan preferensi, dan pemberitahuan restart.
  - Test regresi satu penulis: modul lama dilarang menulis saat saklar hidup (termasuk saat file korup), dan diizinkan menulis saat saklar mati.
  - Semua 286 unit/widget test di repositori lulus 100% dan `flutter analyze` tidak menghasilkan issue baru pada file yang diubah.
