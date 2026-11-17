# 13: Kompatibilitas Data Center dan migrasi saat import

**What to build:** Data Task Master New dapat diekspor dan diimpor melalui Data Center. Import file legacy tetap masuk dan dimigrasi saat dibuka, import file v2 memulihkan data dengan benar, dan hasil export/import round-trip tidak kehilangan data.

**Blocked by:** 02 — Fondasi Task Master New dengan migrasi dan tampilan baca-saja

**Status:** done

- [x] Export Task Master New menghasilkan file yang dapat dibaca kembali.
- [x] Import file legacy berhasil dan data dimigrasi saat dibuka.
- [x] Import file v2 memulihkan kategori, tugas, target, status aktif, dan riwayat.
- [x] Round-trip export lalu import menghasilkan data yang setara.
- [x] Import tidak merusak data lama jika file yang diimpor tidak valid.
- [x] Tidak ada perubahan perilaku Data Center di luar kompatibilitas file Task Master.
- [x] Contract test round-trip dan migrasi hasil import lulus.

## Catatan implementasi

**Tanggal:** 17 November 2026

**Durasi build agent:** ±25 menit (23:13–23:38 WITA) untuk analisis Data Center, implementasi jalur ekspor/impor Task Master, validasi sebelum tulis, backup, dukungan konten terenkripsi, penguatan import ZIP, test kontrak, format, analyze, dan test penuh.

### Ringkasan

Data Center sekarang memakai jalur Task Master New untuk file `my_tasks.json`, bukan menyalin atau menimpa file mentah secara langsung. Ekspor tetap mengambil konten file asli sehingga status enkripsi terjaga. Impor mendekripsi bila perlu, memvalidasi JSON dan versi skema, memetakan seluruh kategori/tugas, membuat backup file lama, lalu menulis melalui `TaskLocalDataSource` yang sudah memakai antrean tulis, enkripsi, dan atomic write. File legacy ditulis apa adanya dan tetap dimigrasikan saat Task Master dibuka. File tidak valid ditolak sebelum backup atau penulisan, sehingga data lama tidak berubah.

### Perubahan utama

- **Kontrak repository** — `TaskRepository` mendapat `exportJson()`, `validateImportJson()`, dan `importJson()`. Ekspor hanya membaca. Validasi tidak menulis. Import memvalidasi lebih dulu, lalu backup dan menulis.
- **Validasi terpusat** — `TaskRepositoryImpl` mengekstrak `_decodeJsonMap()` dan `_validateSchemaVersion()` agar `load`, `saveRawJson`, dan import memakai aturan JSON/versi yang sama.
- **Konten eksternal terenkripsi** — `TaskLocalDataSource.decodeExternalContent()` mengembalikan JSON biasa apa adanya atau mendekripsi konten terenkripsi dengan PIN sesi. PIN tidak tersedia menghasilkan `TaskLockedException`; PIN salah menghasilkan `TaskDecryptionException`, tanpa menyentuh file lama.
- **Backup sebelum import** — `importJson()` memanggil `backupCurrentFile()` sebelum `write()`. Kegagalan backup membatalkan import.
- **Data Center individual** — `_exportTaskMaster()` memakai `exportJson()` dari repository; `_importTaskMaster()` memakai `importJson()` dan menampilkan SnackBar sukses/gagal. Pesan gagal menegaskan data lama tidak diubah.
- **Import ZIP** — `DataCenterScreen` mencari `my_tasks.json` di arsip, memvalidasinya sebelum folder Jurnal/Checklist/Notes/Prompts/Documents dibersihkan, lalu mengimpor lewat repository setelah ekstraksi file lain. File Task Master tidak lagi ditulis mentah di tengah loop ekstraksi.
- **Fake test** — `FakeTaskLocalDataSource` dan `FakeTaskRepository` diperluas agar kontrak baru dapat dipakai seluruh test presentasi yang sudah ada.
- **Test kontrak baru** — 6 test repository untuk import v2 lengkap, migrasi legacy saat dibuka, penolakan file tidak valid tanpa perubahan data, round-trip export/import termasuk field tak dikenal dan field legacy, validasi tanpa tulis/backup, serta round-trip file terenkripsi dengan PIN sesi. 2 test data source untuk konten impor biasa dan terenkripsi.

### Keputusan penting

- **Import legacy tidak langsung dinormalisasi.** File legacy yang valid ditulis apa adanya; `load()` tetap menjadi satu-satunya tempat migrasi dan backup legacy. Ini mempertahankan perilaku "dimigrasi saat dibuka" dan menghindari dua jalur migrasi.
- **Validasi sebelum operasi destruktif.** Import individual dan import ZIP memvalidasi file Task Master sebelum membuat backup, menulis, atau menghapus folder lain. Dengan begitu file rusak/versi tak dikenal tidak merusak data lama.
- **Ekspor mengikuti status enkripsi asli.** Konten mentah dipertahankan agar backup tidak diam-diam berubah menjadi plaintext. Import memahami ciphertext dan mendekripsinya dengan PIN sesi sebelum validasi.
- **Penulisan tetap satu jalur.** Import memakai `TaskLocalDataSource.write()`, jadi antrean tulis, atomic write, dan enkripsi aktif tetap berlaku. Tidak ada penulisan ad hoc dari widget.
- **Field tak dikenal dan field legacy dipertahankan.** Round-trip memakai konten yang sudah dinormalisasi mapper; field tambahan tetap ada, dan field legacy (`type`, `countToday`, dan seterusnya) tetap ditulis untuk kompatibilitas.
- **Cakupan Data Center dibatasi.** Perubahan hanya pada dua aksi individual Task Master dan penanganan `my_tasks.json` di ZIP restore. Checklist, Jurnal, Notes, Prompts, Documents, reset, dan Local Sharing tidak diubah.

### Pengujian

- `dart format` pada file yang diubah.
- `flutter analyze lib/features/task_master_new lib/features/data_center test/features/task_master_new` — tidak ada error baru. Satu warning lama `unused_label` di `backup_tab.dart` tetap ada.
- `flutter test test/features/task_master_new/data/task_repository_contract_test.dart test/features/task_master_new/data/task_local_data_source_contract_test.dart` — **32 test lulus**.
- `flutter test` seluruh suite (tanpa `test/features/task_master_new/performance/large_dataset_performance_test.dart`) — **201 test lulus**.
- Catatan: file `test/features/task_master_new/performance/large_dataset_performance_test.dart` sudah ada dalam keadaan kosong dan membuat kompilasi suite penuh gagal (`Undefined name 'main'`). File itu milik pekerjaan performa tiket 14, bukan perubahan tiket ini, sehingga tidak diubah.

### Catatan review

- Standards review tidak menemukan pelanggaran standar tertulis (repo belum punya dokumen standar). Temuan judgement yang ditindaklanjuti: duplikasi decode/validasi JSON diekstrak ke helper, dan sentinel `ArchiveFile` kosong diganti loop dengan nullable.
- Spec review menekankan cakupan test wiring Data Center dan jalur terenkripsi. Contract test repository/data source sudah mencakup round-trip, migrasi legacy, validasi tanpa tulis, field tak dikenal, field legacy, dan decode eksternal terenkripsi. Wiring UI Data Center tetap diverifikasi lewat analyze dan manual QA karena `FilePicker`/`Share` membutuhkan platform.
- Review juga mencatat import terenkripsi memerlukan PIN sesi. Ini disengaja agar file tidak didekripsi tanpa kredensial; pesan exception meminta pengguna memasukkan PIN lebih dulu dan data lama tetap aman.
- Tidak ada I/O di `build`, tidak ada dependency baru, dan tidak ada perubahan pada skema enkripsi global.

### Tindak lanjut

- Manual QA Android/Linux: ekspor/impor individual dalam kondisi enkripsi aktif dan nonaktif, import file legacy, import v2, serta ZIP restore dengan `my_tasks.json` valid dan rusak.
- Hardening performa 1.000 tugas dan pengisian test performa yang masih kosong dikerjakan pada tiket 14.
- QA parity dan switch navigasi dikerjakan pada tiket 15.
