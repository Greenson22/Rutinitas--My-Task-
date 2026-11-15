# 05: Increment satu klik dan undo lokal

**What to build:** Pengguna menaikkan hitungan tugas dengan satu klik. UI berubah seketika, hitungan total, hitungan hari ini, dan riwayat hari ini ikut bertambah, lalu data disimpan tanpa memblokir tampilan. Setelah increment, SnackBar menampilkan Undo selama 5 detik untuk mengembalikan perubahan.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target

**Status:** done

- [x] Increment memperbarui total, hitungan hari ini, dan riwayat hari ini dalam satu aksi.
- [x] UI berubah seketika tanpa menunggu penulisan file.
- [x] Tidak ada dialog konfirmasi setiap kali increment.
- [x] SnackBar Undo tampil selama 5 detik setelah increment.
- [x] Undo mengembalikan total, hitungan hari ini, dan riwayat hari ini.
- [x] Hanya increment terakhir yang dapat di-undo.
- [x] Tombol increment aman dari double tap yang tidak disengaja.
- [x] Perubahan tetap tersimpan setelah aplikasi ditutup dan dibuka kembali.
- [x] Unit test increment/undo dan widget test SnackBar Undo lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

### Ringkasan

Increment satu klik tersedia pada setiap baris tugas di halaman detail kategori. State di memori diperbarui lebih dulu lewat operasi domain murni, lalu penyimpanan dijadwalkan dengan debounce 300 ms tanpa menahan pembaruan UI. SnackBar Undo berdurasi 5 detik membatalkan increment terakhir, termasuk total, hitungan hari ini, dan entri riwayat hari ini.

### Perubahan utama

- **Domain** — `incrementTaskIn` dan `undoIncrementIn` di `domain/operations/task_operations.dart` memperbarui total, `history[YYYY-MM-DD]`, dan `updatedAt` dalam satu langkah. `TaskIncrement` menyimpan kategori, tugas, dan tanggal yang diperlukan untuk undo. Penulisan hitungan harian disatukan lewat helper `_applyDailyCount`.
- **Controller** — `TaskMasterNewController.incrementTask` menerapkan perubahan optimistis seketika, menyimpan `lastIncrement` pada state, dan menjadwalkan `save` dengan debounce 300 ms. `undoLastIncrement` mengembalikan state dan menjadwalkan penyimpanan ulang. State hanya menyimpan satu `TaskIncrement`, sehingga increment sebelumnya otomatis tidak bisa di-undo.
- **Ketahanan penyimpanan** — `flushPendingSave` menulis segera perubahan yang masih menunggu debounce. Flush dipanggil saat refresh/load, sebelum aksi CRUD lain (agar data yang dibaca ulang tidak menimpa increment), dan saat `dispose` (aplikasi ditutup). Kegagalan simpan memakai banner retry yang sudah ada.
- **Presentasi** — `TaskTile` mendapat tombol increment berlabel aksesibilitas dan target sentuh 48 dp. `CategoryDetailScreen` menampilkan SnackBar `Undo` 5 detik tanpa dialog konfirmasi. SnackBar lama diganti seketika agar Undo selalu merujuk increment terakhir.
- **Test** — unit test domain/controller untuk increment, undo, hanya increment terakhir, double tap per tugas, dan retry simpan; widget test untuk perubahan UI seketika, durasi SnackBar, Undo, double tap, hanya increment terakhir, persistensi setelah buka ulang, serta penutupan sebelum debounce; contract test file nyata untuk increment/undo.

### Keputusan penting

- **Double tap dijaga per tugas**, bukan global, dengan jendela 400 ms. Mengetuk tugas berbeda secara cepat tetap dihitung; hanya ketukan berulang pada tugas yang sama dalam jendela singkat yang diabaikan.
- **Debounce 300 ms** mengikuti keputusan arsitektur. Penulisan tetap diserialisasi oleh antrean `TaskLocalDataSource`, dan `flushPendingSave` memastikan increment tidak hilang saat refresh, aksi CRUD berikutnya, atau penutupan layar.
- **Undo bersifat eksak.** Bila entri riwayat tanggal tersebut sudah tidak ada, total tidak dikurangi agar total dan riwayat tidak saling menyimpang.
- **Increment/undo dijalankan sebagai operasi domain + `TaskRepository.save`**, bukan method repository baru. Controller memegang state optimistis sebagai sumber tampilan, sedangkan repository tetap menjadi satu-satunya jalur tulis. Ini menjaga UI tetap di bawah 100 ms dan menghindari baca-ulang file yang bisa menimpa increment cepat. Integrasi Jurnal menyusul di tiket 06.
- **Pantauan batas:** proses aplikasi yang dibunuh OS dalam jendela debounce sebelum `dispose` tidak dapat dijamin; ini batas yang sama dengan strategi debounce pada spesifikasi.

### Pengujian

- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **94 test lulus**.
- Test baru:
  - `domain/task_operations_test.dart` — increment menambah total/harian/riwayat, membuat entri baru, undo mengembalikan ketiganya, undo menghapus entri nol, dan undo tanpa riwayat tidak mengubah total.
  - `presentation/increment_undo_controller_test.dart` — state berubah sebelum simpan, simpan setelah flush, undo + simpan, hanya increment terakhir, double tap per tugas, increment tugas berbeda tetap dihitung, jendela double tap kedaluwarsa, dan banner retry saat simpan gagal.
  - `presentation/increment_undo_test.dart` — UI seketika tanpa dialog, SnackBar Undo 5 detik, undo mengembalikan tampilan dan data, double tap, hanya increment terakhir, simpan saat tutup sebelum debounce, dan persistensi setelah buka ulang.
  - `data/task_repository_task_contract_test.dart` — increment dan undo bertahan pada file nyata di direktori sementara.

### Catatan review

Review dua sumbu (standards + spec) dilakukan. Temuan yang sudah ditindaklanjuti:

- Mengganti guard double tap global menjadi per tugas agar increment cepat pada tugas berbeda tidak hilang.
- Membuat undo tidak menurunkan total saat entri riwayat sudah tidak ada, supaya total dan riwayat tetap konsisten.
- Menyeragamkan mutasi hitungan harian lewat satu helper domain.
- Mengembalikan status keberhasilan `flushPendingSave`; load dan aksi CRUD berhenti bila flush gagal agar data layar tidak tertimpa data lama.
- Menambah test penutupan aplikasi sebelum debounce, increment dua tugas berbeda, dan kedaluwarsa jendela double tap.
- Mereset clock test dan mempertajam matcher widget.

Temuan yang sengaja ditunda:

- Integrasi durasi Jurnal saat increment/undo adalah cakupan tiket 06.
- Method `increment`/`undo` eksplisit pada kontrak repository tidak ditambahkan karena jalur optimistis memakai operasi domain + `save`; kontrak tetap menjadi seam tulis tunggal. Akan ditinjau ulang bila dashboard (tiket 08) membutuhkan jalur yang sama.
