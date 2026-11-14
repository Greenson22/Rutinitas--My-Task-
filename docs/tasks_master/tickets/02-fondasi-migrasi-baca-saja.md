# 02: Fondasi Task Master New dengan migrasi dan tampilan baca-saja

**What to build:** Pengguna membuka Task Master New dan melihat kategori serta tugas dari data lama yang sudah dimigrasi ke skema v2. Migrasi berjalan otomatis, membuat backup, mendukung file terenkripsi, dan tidak mengubah file asli jika gagal. Tampilan masih baca-saja, tetapi sudah memperlihatkan daftar kategori, tugas, loading, empty, dan error state.

**Blocked by:** 01 — Pindahkan pengaturan folder dan enkripsi ke core

**Status:** done

- [x] Skema v2 memuat `schemaVersion`, `id` kategori, `sortOrder`, `kind`, `createdAt`, `updatedAt`, dan `history`.
- [x] Data legacy dipetakan dengan `id` kategori yang stabil, `id` tugas yang dipertahankan, dan `TaskKind` yang benar.
- [x] `countToday` historis dipindahkan ke riwayat harian agar tidak hilang.
- [x] Migrasi membuat backup sebelum menulis dan berjalan idempoten.
- [x] Migrasi gagal tidak mengubah file asli dan menampilkan pesan yang dapat ditindaklanjuti.
- [x] File terenkripsi dapat dibaca, dimigrasi, dan ditulis ulang dengan atomic write.
- [x] Versi skema yang tidak dikenal ditolak tanpa merusak data.
- [x] Pengguna melihat kategori dan tugas hasil migrasi dalam tampilan baca-saja.
- [x] Ada loading, empty, dan error state yang jelas.
- [x] Unit test mapper/migrasi dan contract test repository/local data source lulus.
