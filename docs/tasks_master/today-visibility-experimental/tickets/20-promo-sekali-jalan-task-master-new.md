# 20: Tawaran sekali-jalan mengaktifkan Task Master New

**What to build:** Pengguna yang pernah memakai Task Master New dan kini memakai modul lama ditawari sekali untuk mengaktifkannya kembali saat membuka Task Master. Tawaran tidak mengganggu pengguna baru dan tidak muncul lagi setelah dijawab.

**Blocked by:** 19 — Saklar eksperimental Task Master New dan satu penulis.

**Status:** done

- [x] Dialog tawaran muncul hanya bila ketiga syarat terpenuhi bersamaan: saklar `task_master_use_new_module` mati, file data sudah berformat v2, dan `seen_task_master_new_promo` belum `true`.
- [x] Dialog muncul saat Task Master dibuka, bukan saat aplikasi pertama diluncurkan.
- [x] Dialog berisi penjelasan singkat dan dua aksi: **Aktifkan Sekarang** dan **Nanti**.
- [x] **Aktifkan Sekarang** menulis saklar `task_master_use_new_module = true` dan menampilkan instruksi restart.
- [x] **Nanti** tidak mengubah saklar.
- [x] Kedua aksi menulis `seen_task_master_new_promo = true`, sehingga dialog tidak muncul lagi.
- [x] Dialog tidak muncul untuk pengguna baru yang belum punya file v2.
- [x] Dialog tidak muncul saat saklar sudah hidup.
- [x] Preferensi tawaran bertahan setelah restart.
- [x] Widget test: dialog muncul pada kondisi yang tepat, tidak muncul pada tiga kondisi yang tidak tepat, dan tidak muncul lagi setelah salah satu aksi dipilih.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

- **Build Time:** 2026-11-23T03:12:29+08:00
- **Konfigurasi Rollout & Preferences:**
  - Ditambahkan key `seenTaskMasterNewPromoPrefKey = 'seen_task_master_new_promo'` di [task_master_rollout.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/lib/core/config/task_master_rollout.dart).
  - Ditambahkan helper `getSeenTaskMasterNewPromo({bool useCache = true})` dan `setSeenTaskMasterNewPromo(bool value)` dengan in-memory caching serta dukungan `resetTaskMasterRolloutCacheForTesting(cachedSeenPromo: ...)`.
- **Integrasi Promo di Entry Point:**
  - Ditambahkan evaluasi promo pada [task_master_entry.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/lib/core/presentation/widgets/task_master_entry.dart) saat saklar `_useNewModule == false` melalui frame callback (`addPostFrameCallback`).
  - Dialog muncul HANYA jika ketiga syarat terpenuhi:
    1. `task_master_use_new_module == false`
    2. `seen_task_master_new_promo != true`
    3. File data `<baseDir>/mytask/my_tasks.json` ada dan berformat `schemaVersion == 2` (termasuk dukungan dekripsi jika storage terenkripsi).
  - Disediakan callback opsional `isSchemaV2Checker` dan `onPromoDecision` untuk memfasilitasi pengujian deterministik dan decoupling dependensi I/O storage.
  - Aksi dialog:
    - **Nanti**: Menyimpan `seen_task_master_new_promo = true` dan menutup dialog tanpa mengubah saklar.
    - **Aktifkan Sekarang**: Menyimpan `seen_task_master_new_promo = true`, menyalakan saklar `task_master_use_new_module = true`, dan memunculkan `SnackBar` berisi notifikasi perlunya memulai ulang aplikasi.
- **Pengujian:**
  - Menambahkan kelompok widget test `promo sekali-jalan Task Master New` pada [navigation_switch_test.dart](file:///home/lemon-manis-22/Projects/Flutter/rutinitasku/test/features/task_master_new/presentation/navigation_switch_test.dart) yang mencakup:
    1. Dialog muncul bila saklar mati, file v2 ada, dan promo belum pernah muncul.
    2. Dialog TIDAK muncul bila saklar sudah hidup.
    3. Dialog TIDAK muncul untuk pengguna baru (file v2 belum ada).
    4. Dialog TIDAK muncul bila `seen_task_master_new_promo == true`.
    5. Aksi "Nanti" menyimpan status terlihat dan mempertahankan status saklar mati.
    6. Aksi "Aktifkan Sekarang" menyalakan saklar, menyimpan status terlihat, dan menampilkan instruksi restart.
    7. Status tersimpan di SharedPreferences bertahan setelah restart (simulasi in-memory cache reset).
  - Validasi: `flutter analyze` bersih (0 issues) dan seluruh 285 pengujian Task Master New lulus 100%.
