# 18: Visibilitas Hari Ini per tugas

**What to build:** Setiap tugas memiliki pengaturan **Tampil di Hari Ini** bertipe tri-state (`auto`, `always`, `never`). Daftar Hari Ini menghormati pengaturan ini tanpa mengubah perilaku default pengguna lama. Pengaturan dapat diubah dari form tugas, menu baris, dan aksi massal, lalu bertahan setelah restart dan export/import.

**Blocked by:** 17 — Passthrough field tak dikenal di model legacy (field baru harus aman saat file ditulis modul lama).

**Status:** done

- [x] `TodayVisibility` enum dengan `auto` sebagai default dan parser aman untuk nilai tidak dikenal; nilai rusak menjadi `auto` dan dicatat lewat debug, bukan error.
- [x] `Task.todayVisibility` ditambahkan, termasuk `copyWith` dan kesetaraan entity.
- [x] Mapper membaca `todayVisibility`, fallback ke `showInToday` (`true` → `always`, `false` → `never`), lalu `auto`.
- [x] Mapper menulis `todayVisibility` dan cermin `showInToday` hanya untuk `always` dan `never`; `auto` tidak menulis cermin.
- [x] `collectTodayTasks` menerapkan aturan: `never` selalu dilewati, `always` selalu disertakan selama tugas aktif dan kategori tidak tersembunyi, `auto` memakai aturan lama (target harian, target total untuk progress, atau ada hitungan hari ini).
- [x] Tugas nonaktif dan kategori tersembunyi tetap dikecualikan pada semua nilai.
- [x] Ringkasan dashboard tidak berubah karena perubahan visibilitas; tugas `always` tanpa target menyumbang nol pada hitungan target tercapai.
- [x] Urutan hasil tetap mengikuti `sortOrder` kategori lalu tugas.
- [x] Form tugas memiliki kontrol tiga opsi “Tampil di Hari Ini” dengan teks bantuan per opsi dan default `Otomatis` untuk tugas baru.
- [x] Menu baris di daftar Hari Ini dan detail kategori memiliki submenu tiga opsi dengan tanda centang pada nilai aktif.
- [x] Aksi massal “Visibilitas Hari Ini” menerapkan nilai terpilih ke semua tugas terpilih tanpa menyentuh status aktif.
- [x] Perubahan visibilitas langsung terlihat tanpa reload file; jumlah tugas di header Hari Ini ikut berubah.
- [x] Tugas `always` tanpa target tetap menampilkan status “Tanpa target” dan tombol increment.
- [x] Empty state Hari Ini menjelaskan cara memunculkan tugas lewat pengaturan ini.
- [x] Visibilitas bertahan setelah restart dan setelah export/import Data Center.
- [x] Unit test matriks: 3 visibilitas × (target harian, tanpa target, ada aktivitas, progress dengan target total) × aktif/nonaktif × kategori terlihat/tersembunyi.
- [x] Widget test: form menyimpan tiga opsi, menu baris mengubah dan daftar langsung bereaksi, aksi massal, ringkasan tetap sama, empty state menampilkan bantuan.
- [x] Gate performa: dashboard 1.000 tugas tetap di bawah ambang 500 ms.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

**Mulai:** 2026-11-22 22:15 WITA
**Selesai:** 2026-11-22 22:38 WITA
**Durasi:** ±23 menit

### Perubahan Kode

1. **Domain & Data**:
   - `TodayVisibility` enum (`auto`, `always`, `never`) dengan default `auto` dan parser aman fallback debug.
   - Entitas `Task` dengan field `todayVisibility`, `copyWith`, dan kesetaraan `operator ==` / `hashCode`.
   - `TaskMasterMapper`: membaca `todayVisibility`, fallback ke `showInToday` (`true` -> `always`, `false` -> `never`), default `auto`. Menulis `todayVisibility` dan menulis mirror `showInToday` hanya untuk `always` (`true`) dan `never` (`false`).
   - `collectTodayTasks`: filter tri-state `auto` / `always` / `never` dengan guard tugas aktif dan kategori tidak tersembunyi.
   - Operasi `setTaskVisibility` dan `setTasksVisibility` pada domain operasi, repository contract, repository implementation, controller, dan test fakes.

2. **Presentasi**:
   - `TaskFormDialog`: kontrol dropdown 3 opsi "Tampil di Hari Ini" dengan teks bantuan per opsi dan default `Otomatis`.
   - `TaskTile`: submenu popup menu 3 opsi "Tampil di Hari Ini" dengan ikon centang aktif.
   - `TodayTaskTile`: menu popup 3 opsi "Tampil di Hari Ini" dengan tanda centang aktif.
   - `CategoryDetailScreen`: aksi massal `bulkVisibilityButton` untuk mengubah visibilitas semua tugas terpilih sekaligus tanpa mengubah status aktif.
   - `EmptyTodayTasksView`: panduan dan penjelasan cara memunculkan tugas via pengaturan "Tampil di Hari Ini".

3. **Pengujian**:
   - Unit test matriks: `test/features/task_master_new/domain/today_visibility_matrix_test.dart` (48 kombinasi matriks lengkap + verifikasi ringkasan & urutan `sortOrder`).
   - Widget test: `test/features/task_master_new/presentation/today_visibility_widget_test.dart` (form opsi, menu baris kategori, menu baris Hari Ini, aksi massal, empty state).
   - Performa: `large_dataset_performance_test.dart` 1.000 tugas lulus (load ~236-250 ms, dashboard summary ~3 ms, jauh di bawah ambang batas 500 ms).
   - Verifikasi: `flutter analyze` 0 issue pada `task_master_new` dan seluruh 277+ unit/widget test lulus.
