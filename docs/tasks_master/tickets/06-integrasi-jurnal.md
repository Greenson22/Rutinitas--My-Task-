# 06: Integrasi Jurnal saat increment dan undo

**What to build:** Tugas yang tertaut ke Jurnal ditandai. Saat pengguna melakukan increment pada tugas tertaut, durasi Jurnal bertambah sesuai pengaturan template, dengan fallback 30 menit. Saat Undo, durasi yang sama dikurangi kembali. Jika rollback Jurnal gagal, data Task Master tetap kembali dan pengguna mendapat peringatan.

**Blocked by:** 05 — Increment satu klik dan undo lokal

**Status:** done

- [x] Tugas yang memiliki `linkedTaskIds` di Jurnal menampilkan indikator tertaut.
- [x] Increment tugas tertaut menambah durasi sesuai pengaturan template Jurnal.
- [x] Jika pengaturan tidak tersedia atau tidak valid, durasi fallback 30 menit dipakai.
- [x] Increment tugas yang tidak tertaut tetap menaikkan hitungan tanpa mengubah Jurnal.
- [x] Undo mengurangi durasi yang ditambahkan ke Jurnal.
- [x] Rollback Jurnal yang gagal tidak membatalkan rollback data Task Master dan menampilkan peringatan jelas.
- [x] File Jurnal terenkripsi tetap dapat dibaca dan ditulis.
- [x] Relasi Jurnal tidak disalin ke data Task Master.
- [x] Contract test `JournalGateway` untuk tambah, kurangi, fallback, enkripsi, dan kegagalan lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

### Ringkasan

Task Master New sekarang membaca relasi Jurnal lewat kontrak `JournalGateway` dan menampilkan badge `Jurnal` pada tugas yang tertaut, baik di dashboard maupun halaman detail kategori. Increment tugas tertaut menambah durasi aktivitas Jurnal yang sesuai; Undo mengurangi durasi yang sama. Tautan Jurnal tetap berada di file Jurnal dan tidak pernah disalin ke data Task Master.

### Perubahan utama

- **Domain** — `domain/repositories/journal_gateway.dart` mendefinisikan `JournalGateway`, `JournalLinkState`, `JournalAdjustment`, `JournalGatewayException`, dan `defaultJournalIncrementMinutes = 30`.
- **Data** — `data/gateways/file_journal_gateway.dart` membaca/menulis `jurnal_YYYY_MM.json` dan `jurnal_template.json`, tetap mendukung master lama `time_log.json`, memakai `CryptoHelper` saat enkripsi aktif, dan menulis lewat `AtomicWriteHelper`. Operasi dibaca dan ditulis secara berurutan lewat antrean internal agar increment cepat tidak saling menimpa. `createJournalGateway` di `data/repositories/journal_gateway_factory.dart` menjadi jalur produksi.
- **Controller** — `TaskMasterNewController` menerima `JournalGateway` opsional. `load()` memuat relasi Jurnal ke `journalLinks` di state. `incrementTask` menambah durasi Jurnal secara asinkron untuk tugas tertaut, sedangkan `undoLastIncrement` mengembalikan data Task Master lebih dulu lalu menunggu penambahan Jurnal selesai sebelum mengurangi durasi yang sama. Kegagalan membaca relasi, menambah, atau mengurangi Jurnal menjadi `actionMessage` yang jelas dan tidak membatalkan operasi Task Master.
- **Presentasi** — `TaskTile` menampilkan badge `Jurnal`; `CategoryCard` dan `CategoryDetailScreen` meneruskan status tautan dari controller. SnackBar increment menampilkan `Jurnal +N menit` untuk tugas tertaut atau `Jurnal tidak tertaut` untuk tugas biasa.
- **Test** — contract test gateway, unit test controller, dan widget test untuk indikator, increment, undo, kegagalan, serta lintas tengah malam.

### Keputusan penting

- **Jurnal bersifat best-effort.** Rollback Task Master selalu berhasil lebih dulu; kegagalan Jurnal hanya menampilkan peringatan agar pengguna memeriksa Jurnal manual. Ini mencegah data tugas “macet” karena file Jurnal bermasalah.
- **Waktu increment dipakai untuk undo.** `_PendingJournalIncrement` menyimpan `at` dari saat increment. Undo yang melewati tengah malam tetap mengurangi entri Jurnal pada hari yang benar.
- **Hanya tautan hari ini yang dianggap aktif.** Template dan log bulanan dibaca, tetapi tautan dari log harian difilter ke `tanggal` hari ini. Tautan lama tidak ikut menempel ke tugas.
- **Fallback 30 menit** dipakai bila `settings.default_increment_minutes` tidak ada, bukan angka positif, atau bukan angka.
- **Underflow tidak didiamkan.** Bila durasi Jurnal tersisa lebih kecil dari yang akan dikurangi, gateway menulis `0` agar tidak negatif lalu melempar `JournalGatewayException` supaya pengguna mendapat peringatan.
- **Tautan tidak disalin ke Task Master.** Relasi hanya hidup di `JournalLinkState` pada state presentasi; model dan file Task Master tidak berubah.
- **Master Jurnal lama tetap didukung.** Bila file baru belum ada dan `time_log.json` ada, gateway memakai format lama agar pengguna lama tidak kehilangan integrasi.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **119 test lulus**.
- Test baru:
  - `data/journal_gateway_contract_test.dart` — tambah sesuai pengaturan template, kurangi saat undo, fallback 30 untuk pengaturan hilang/tidak valid, tugas tidak tertaut tidak mengubah Jurnal, baca/tulis file terenkripsi, kata sandi salah, aktivitas tidak ditemukan, penggabungan template + log hari ini, tautan hari sebelumnya diabaikan, underflow menulis nol lalu gagal, dan master lama.
  - `presentation/journal_integration_controller_test.dart` — relasi tidak disalin ke data, peringatan saat relasi gagal dibaca, increment tertaut, increment tidak tertaut, undo mengurangi durasi, undo lintas tengah malam, undo menunggu penambahan selesai, gagal menambah tetap menaikkan hitungan, dan gagal rollback Jurnal tidak membatalkan rollback Task Master.
  - `presentation/journal_integration_test.dart` — badge di dashboard dan detail, SnackBar `Jurnal +45 menit`, undo mengurangi, dan pesan `Jurnal tidak tertaut`.

### Catatan review

Review dua sumbu (standards + spec) dilakukan. Temuan yang sudah ditindaklanjuti:

- Menambahkan indikator Jurnal di kartu kategori dashboard, bukan hanya halaman detail.
- Memakai waktu increment untuk pengurangan Jurnal agar undo lintas tengah malam tidak salah hari.
- Memfilter tautan log ke tanggal hari ini agar tautan lama tidak dianggap aktif.
- Menampilkan peringatan saat relasi Jurnal gagal dibaca, bukan diam-diam menampilkan semua tugas sebagai tidak tertaut.
- Memperingatkan saat pengurangan melebihi durasi tersedia, sambil tetap menulis nol agar durasi tidak negatif.
- Menghapus field/getter yang tidak terpakai dan menyatukan jalur tambah/kurangi bulanan dengan master lama.
