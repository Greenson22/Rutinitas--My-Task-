# 12: Recovery, editor JSON advanced, dan pengaturan di modul baru

**What to build:** Pengguna mendapat alur pemulihan saat file tidak dapat dibaca: memasukkan PIN, memulihkan backup, atau membuat file baru dengan konfirmasi. Pengguna juga dapat membuka pengaturan folder/enkripsi dari modul baru dan mengedit raw JSON melalui area Advanced dengan validasi serta atomic write.

**Blocked by:** 01 — Pindahkan pengaturan folder dan enkripsi ke core; 02 — Fondasi Task Master New dengan migrasi dan tampilan baca-saja; 04 — Kelola tugas, jenis tugas, dan target

**Status:** done

- [x] File yang gagal didekripsi menampilkan opsi memasukkan PIN.
- [x] PIN yang benar membuka data dan menampilkan hasilnya.
- [x] Opsi memulihkan backup tersedia dan berfungsi.
- [x] Opsi membuat file baru meminta konfirmasi destruktif.
- [x] Pengaturan folder dan enkripsi dapat dibuka dari modul baru tanpa ketergantungan ke modul lama.
- [x] Raw JSON editor tersedia di area Advanced, bukan menu utama.
- [x] Editor memvalidasi JSON sebelum menyimpan.
- [x] Penyimpanan dari editor memakai atomic write dan menghormati enkripsi.
- [x] Widget test recovery dan validasi editor JSON lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

**Durasi build agent:** ±14 menit (22:35–22:49 WITA) untuk implementasi recovery PIN/backup/file baru, area Advanced, editor JSON mentah, integrasi pengaturan core, pembaruan fake/contract test, `dart format`, `flutter analyze` modul, dan `flutter test` penuh.

### Ringkasan

Task Master New sekarang punya jalur pemulihan lengkap saat file gagal dibaca. Error state mengenali jenis kegagalan (terkunci, gagal dekripsi, korup, migrasi, versi tidak didukung) lalu menampilkan aksi yang relevan: buka dengan PIN, pulihkan backup, atau buat file baru setelah konfirmasi destruktif. Pengaturan folder dan enkripsi dibuka dari `SettingsDialog` core melalui area Advanced, sehingga modul baru tidak bergantung pada modul Task Master lama. Editor JSON mentah juga hanya tersedia di area Advanced, divalidasi dua lapis, dan disimpan lewat repository yang memakai atomic write serta enkripsi aktif.

### Perubahan utama

- **State recovery** — `TaskMasterNewState` mendapat `TaskMasterRecoveryKind` (`locked`, `decryption`, `corrupted`, `migration`, `unsupportedVersion`, `generic`) beserta getter `canUnlockWithPin` dan `offersFileRecovery`. Controller mengisi jenis ini dari exception yang ditangkap saat memuat data.
- **Buka dengan PIN** — `TaskRepository.load({String? password})` dan `TaskLocalDataSource.read({String? password})` menerima PIN dari dialog. Bila dekripsi berhasil, `FileTaskLocalDataSource` menyimpan override kata sandi untuk penulisan berikutnya, sehingga file tetap ditulis terenkripsi dengan PIN yang benar walau password sesi tidak tersedia.
- **Pulihkan backup** — `TaskRepository.listBackups()` dan `restoreBackup()` membaca daftar backup terbaru lebih dulu. `FileTaskLocalDataSource.restoreBackup()` menyalin konten backup mentah ke file utama dengan atomic write, lalu repository memuat ulang dan memigrasikan bila perlu. UI menampilkan daftar backup, konfirmasi kedua, dan SnackBar hasil.
- **Buat file baru** — `TaskRepository.createNewFile()` membackup file saat ini lebih dulu lewat `backupCurrentFile()`, lalu menulis data kosong v2. Dialog konfirmasi menyebutkan bahwa data lama akan dibackup dan hilang dari tampilan sampai dipulihkan.
- **Area Advanced** — `TaskMasterAdvancedSheet` dibuka dari ikon `science` di AppBar (bukan menu utama). Isinya hanya dua aksi berisiko: editor JSON mentah dan pengaturan folder & enkripsi.
- **Editor JSON mentah** — `RawJsonEditorDialog` memuat konten terdekripsi, memvalidasi `jsonDecode` dan akar objek sebelum memanggil simpan, serta menampilkan pesan validasi tanpa menutup dialog. Repository juga memvalidasi ulang: JSON tidak valid, kategori bukan list, atau versi skema tidak dikenal ditolak sebelum file disentuh.
- **Normalisasi aman** — `saveRawJson()` memetakan dan menormalkan data v2 di memori lebih dulu, mempertahankan field tidak dikenal melalui `original`, lalu menulis satu kali melalui `TaskLocalDataSource.write` (atomic + enkripsi). File lama tidak pernah ditimpa oleh JSON yang gagal dipetakan.
- **Pengaturan core** — `TaskMasterNewScreen` menerima `StorageService` opsional dan membuka `SettingsDialog` core dari area Advanced. Perubahan folder memicu muat ulang, dan toggle enkripsi memakai callback muat ulang yang sama.
- **Error view** — `TaskMasterErrorView` mendapat tombol opsional `Masukkan PIN`, `Pulihkan backup`, dan `Buat file baru` dengan key stabil untuk widget test. Tombol `Coba Lagi` tetap tersedia.
- **Test** — 14 test baru: 5 widget recovery/editor, 3 contract data source, dan 6 contract repository.

### Keputusan penting

- **PIN menjadi override sesi penyimpanan.** Setelah PIN berhasil, penulisan berikutnya memakai PIN itu, bukan hanya pembacaan. Tanpa ini, membuka file dengan PIN lalu increment akan gagal menyimpan karena password sesi tetap kosong.
- **Backup dipulihkan sebagai byte mentah.** Backup mengikuti status enkripsi file asli (sesuai SPEC). Menyalin mentah menghindari dekripsi/enkripsi ulang yang tidak perlu dan menjaga bentuk backup tetap setia; PIN hasil unlock tetap dipakai saat memuat ulang.
- **Validasi editor dua lapis.** UI mencegah JSON sintaks rusak dikirim, sedangkan repository mencegah JSON valid secara sintaks tetapi tidak valid sebagai data Task Master menimpa file. Ini memenuhi syarat “validasi sebelum menyimpan” tanpa mengorbankan atomic write.
- **Editor menormalkan ke v2.** Pengguna mengedit JSON, tetapi hasil tulis selalu skema v2 yang konsisten dan mempertahankan field tak dikenal. Migrasi legacy dari editor tetap aman karena pemetaan dilakukan di memori sebelum tulis.
- **Advanced bukan menu utama.** Ikon `science` sengaja terpisah dari aksi harian dan hanya membuka bottom sheet berisi dua pilihan berisiko. Pengaturan enkripsi tetap memakai dialog core yang sudah dipakai lintas fitur.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter analyze` seluruh proyek masih melaporkan 326 issue lama di fitur lain (deprecation, `BuildContext` async, unused import). Tidak ada issue baru dari `task_master_new`.
- `flutter test` — **193 test lulus**.
- Test baru:
  - `presentation/recovery_test.dart` (5 test): PIN salah menampilkan pesan dan PIN benar membuka data; backup dapat dipulihkan lewat dua konfirmasi; buat file baru meminta konfirmasi destruktif; editor JSON menolak JSON rusak dan akar bukan objek; area Advanced menampilkan pengaturan serta editor.
  - `data/task_local_data_source_contract_test.dart` (+3): PIN pemulihan membaca/menulis ulang file terenkripsi; backup file saat ini dapat dipulihkan dengan atomic write; restore backup hilang gagal tanpa mengubah file.
  - `data/task_repository_contract_test.dart` (+6): `readRawJson`; penolakan JSON tidak valid tanpa menulis; normalisasi v2 dan field tak dikenal; `createNewFile` membackup lalu menulis kosong; `restoreBackup` memuat ulang; urutan backup terbaru lebih dulu.

### Catatan review

- Tidak ada I/O di `build`. Semua aksi recovery berjalan lewat controller dan repository.
- Semua penulisan baru, termasuk editor dan file baru, melewati `TaskLocalDataSource.write` sehingga antrean tulis, atomic write, dan enkripsi tetap satu jalur.
- File asli tidak disentuh saat JSON editor gagal validasi atau gagal dipetakan.
- `BuildContext` dipakai setelah async hanya dengan pengecekan `mounted`.
- Tidak ada dependency baru dan tidak ada perubahan pada Jurnal, Checklist, maupun Data Center.

### Tindak lanjut

- Kompatibilitas ekspor/impor Data Center untuk file v2 dikerjakan pada tiket 13.
- Hardening performa 1.000 tugas dan audit manual Android/Linux desktop dikerjakan pada tiket 14 dan 15.
- QA manual disarankan untuk kombinasi enkripsi aktif + PIN pemulihan + restore backup, karena kontrak otomatis memakai file sementara.
