# 07: Riwayat harian dan streak

**What to build:** Pengguna dapat melihat riwayat harian tugas dan streak yang dihitung dari data nyata. Riwayat bersifat sparse, hanya menyimpan tanggal dengan hitungan, dan dipangkas maksimal 365 hari per tugas. Streak mengikuti target harian jika ada; jika tidak, mengikuti aktivitas.

**Blocked by:** 05 — Increment satu klik dan undo lokal

**Status:** done

- [x] Riwayat harian tugas dapat dilihat dan tetap ada setelah aplikasi dibuka kembali.
- [x] `countToday` diturunkan dari riwayat hari ini, bukan dari reset terjadwal.
- [x] Pergantian hari membuat hitungan hari ini menjadi nol tanpa job reset.
- [x] Streak dihitung dari hari kemarin ke belakang.
- [x] Jika target harian tersedia, hari berhasil hanya bila hitungan mencapai target.
- [x] Jika target harian nol, hari dianggap aktif bila ada hitungan.
- [x] Hari ini yang belum dikerjakan tidak memutus streak.
- [x] Riwayat lebih dari 365 hari dipangkas saat penulisan.
- [x] Definisi selesai konsisten untuk `Habit`, `Counter`, dan `Progress`.
- [x] Unit test streak dan pemangkasan riwayat lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

### Ringkasan

Riwayat harian sparse sekarang dapat dibuka dari setiap baris tugas, baik di dashboard maupun halaman detail kategori. Halaman riwayat menampilkan streak berjalan dan daftar tanggal yang memiliki hitungan. Streak dihitung dari data riwayat nyata, bukan dari penghitung terpisah, dan pemangkasan 365 hari tetap terjadi pada jalur penulisan.

### Perubahan utama

- **Domain** — `domain/operations/streak_calculator.dart` menyediakan `calculateStreak`, `pruneHistory`, `historyRetentionCutoffKey`, dan konstanta `historyRetentionDays = 365`. `Task` mendapat `isDailyGoalMetOn` untuk aturan berhasil harian dan `isCompleteOn` untuk definisi selesai tiap jenis tugas.
- **Aturan streak** — Perhitungan dimulai dari kemarin lalu mundur. Bila `targetDaily > 0`, hari berhasil hanya saat hitungan mencapai target; bila target nol, hari berhasil bila ada hitungan. Hari ini tidak dihitung dan tidak memutus streak ketika belum dikerjakan.
- **Pemangkasan** — `pruneHistory` membuang hitungan nol dan tanggal lebih lama dari 365 hari. Mapper memakai fungsi ini saat menulis, sehingga seluruh jalur tulis (save, increment, undo, migrasi) memakai aturan retensi yang sama.
- **Definisi selesai** — Mapper kini memakai `Task.isCompleteOn`, menggantikan logika `checked` yang tersebar. Habit selesai bila target harian tercapai, progress selesai bila total mencapai target total, dan counter tidak memiliki status selesai.
- **Presentasi** — `TaskHistoryScreen` menampilkan kartu streak serta daftar riwayat terurut terbaru. `TaskTile` menampilkan badge streak ketika ada streak berjalan dan tombol riwayat dengan label aksesibilitas. Tombol tersedia di dashboard dan halaman detail kategori.
- **Test** — Unit test streak untuk target terpenuhi, target tidak terpenuhi, tanpa target, hari ini belum dikerjakan, dan batas retensi. Unit test pemangkasan serta definisi selesai tiap jenis. Widget test untuk tampilan streak, isi riwayat, persistensi setelah layar dibangun ulang, dan pergantian hari. Contract test file nyata untuk menyimpan lalu memuat ulang riwayat dan streak.

### Keputusan penting

- **Streak tidak memasukkan hari ini.** Ini mengikuti bunyi tiket dan PRD: streak dihitung dari kemarin ke belakang. Konsekuensinya, capaian hari ini baru menambah streak pada hari berikutnya. Hari ini yang belum dikerjakan tidak pernah memutus streak.
- **Riwayat adalah sumber kebenaran.** `countToday` tetap proyeksi `history[today]`, sehingga pergantian hari tidak memerlukan job reset; kunci tanggal yang dibaca berubah sendiri.
- **Pemangkasan dilakukan saat menulis, bukan saat membaca.** File lama masih bisa dibaca apa adanya. Data yang lebih dari 365 hari baru dibuang ketika file ditulis ulang, sesuai keputusan arsitektur.
- **Tanggal masa depan tidak dibuang.** Pemangkasan hanya membuang entri lebih lama dari batas retensi agar koreksi jam perangkat tidak menghapus data yang sah.
- **Riwayat memakai halaman, bukan dialog.** Spesifikasi membatasi dialog untuk form pendek dan konfirmasi destruktif, sehingga riwayat yang bisa berisi ratusan baris ditampilkan sebagai halaman tersendiri.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **136 test lulus**.
- Test baru:
  - `domain/streak_calculator_test.dart` — streak target terpenuhi, target tidak terpenuhi, tanpa target, hari ini belum dikerjakan, batas 365 hari, definisi selesai habit/counter/progress, pemangkasan 365 hari, dan pembuangan hitungan nol.
  - `presentation/task_history_test.dart` — badge streak, halaman riwayat beserta status target, persistensi setelah layar dibangun ulang, dan hitungan hari ini menjadi nol saat pergantian hari.
  - `data/task_repository_task_contract_test.dart` — riwayat dan streak bertahan setelah disimpan dan dimuat ulang dari file nyata di direktori sementara.

### Catatan review

Review dua sumbu (standards + spec) dilakukan. Temuan yang sudah ditindaklanjuti:

- Mengganti dialog riwayat menjadi halaman tersendiri agar tidak melanggar aturan “dialog hanya untuk form pendek dan konfirmasi destruktif”.
- Menambahkan label aksesibilitas pada ikon streak.
- Menghapus parameter retensi yang tidak dipakai dan menyederhanakan perhitungan cutoff.
- Tidak lagi membuang tanggal masa depan saat pemangkasan agar koreksi jam tidak menghapus data.
- Menyeragamkan label status riwayat dengan definisi selesai tiap jenis tugas.
- Menambahkan contract test file nyata agar persistensi riwayat benar-benar teruji, bukan hanya pembangunan ulang widget dengan repository in-memory.
- Menyatukan pembuka halaman riwayat agar dashboard dan detail kategori memakai jalur yang sama.

Temuan yang sengaja ditunda:

- Streak masih dihitung ulang per baris tugas saat `build`. Untuk 1.000 tugas, biayanya masih kecil karena riwayat dibatasi 365 hari; optimasi cache akan ditinjau pada tiket hardening performa (14).
