# 04: Kelola tugas, jenis tugas, dan target

**What to build:** Pengguna dapat membuka halaman detail kategori dan mengelola tugas di dalamnya: menambah, mengedit, menghapus, serta memilih `TaskKind` (`Habit`, `Counter`, `Progress`) dengan target yang sesuai. Daftar tugas menampilkan hitungan hari ini, total, badge jenis, progress bar untuk `Progress`, dan status aktif/nonaktif.

**Blocked by:** 03 — Kelola kategori dengan identitas stabil

**Status:** done

- [x] Pengguna dapat menambah tugas ke kategori dengan nama, jenis, target harian, target total, dan status aktif.
- [x] `Progress` mewajibkan target total lebih dari nol; target harian tidak boleh negatif.
- [x] Pengguna dapat mengedit semua field tugas tanpa kehilangan `id`.
- [x] Pengguna dapat menghapus tugas dengan konfirmasi.
- [x] Pengguna dapat menonaktifkan dan mengaktifkan kembali tugas.
- [x] Daftar tugas menampilkan badge jenis, total, hitungan hari ini, progress bar `Progress`, dan status aktif.
- [x] Perubahan tugas bertahan setelah aplikasi ditutup dan dibuka kembali.
- [x] Widget test form tugas, validasi target, dan daftar tugas lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

### Ringkasan

Pengelolaan tugas penuh tersedia di `task_master_new` melalui halaman detail kategori. Tugas tetap memakai `id` stabil; edit hanya mengubah field yang diedit sehingga total, riwayat harian, dan urutan tidak hilang.

### Perubahan utama

- **Domain** — `domain/operations/task_operations.dart` berisi operasi murni tambah/edit/aktif-nonaktif/hapus dan validasi (nama wajib maksimal 120 karakter, target harian tidak negatif, target total wajib lebih dari nol untuk `Progress`). `TaskMasterData.categoryById` menjadi satu jalur pencarian kategori.
- **Repository** — kontrak `TaskRepository` diperluas dengan `addTask`, `updateTask`, `setTaskActive`, dan `deleteTask`. `TaskRepositoryImpl` memakai satu helper `_mutateData` sehingga semua jalur tulis tetap memakai atomic write dan enkripsi yang sudah ada. ID tugas dan waktu sekarang dapat diinjeksi untuk test.
- **Controller** — `TaskMasterNewController` menangani aksi tugas, validasi nama, error yang bisa dicoba ulang, dan lookup kategori untuk halaman detail.
- **Presentasi** — halaman `CategoryDetailScreen` menampilkan daftar tugas, FAB tambah tugas, empty state, serta menu Ubah/Nonaktifkan/Aktifkan/Hapus per tugas. Dialog form tugas mendukung ketiga jenis, target harian, target total khusus `Progress`, dan status aktif. Dialog hapus memberi peringatan bila tugas punya riwayat. Kartu kategori kini punya tombol "Kelola tugas" dan bisa diketuk untuk membuka detail.

### Keputusan penting

- `targetTotal` non-`Progress` tetap disimpan bila pengguna berpindah jenis, sehingga tidak hilang diam-diam saat edit.
- Target harian baru default `0` (tanpa target), supaya `Counter` tidak otomatis dianggap punya kewajiban harian.
- `Progress` menampilkan field target total secara kondisional; validasi ganda dilakukan di form dan domain/repository.
- Menghapus tugas hanya menghapus tugas tersebut; hitungan dan riwayatnya ikut terhapus dan dialog menjelaskan dampaknya.
- Reorder, pindah kategori, seleksi massal, dan increment tetap menjadi cakupan tiket 05 dan 10.

### Pengujian

- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test test/features/task_master_new` — **74 test lulus**.
- Test baru:
  - `domain/task_operations_test.dart` — validasi nama/target, tambah, edit mempertahankan id/riwayat/total, aktif-nonaktif, hapus.
  - `data/task_repository_task_contract_test.dart` — tambah/edit/aktif/hapus bertahan setelah reload, validasi tidak menulis file, dan round-trip pada file nyata di direktori sementara.
  - `presentation/task_management_test.dart` — daftar tugas dengan badge/progress/status, empty state, tambah tugas, validasi target `Progress` dan target harian negatif, edit semua field tanpa kehilangan `id`, aktif-nonaktif, hapus dengan konfirmasi, banner retry saat penyimpanan gagal, dan persistensi setelah layar dibuka ulang.

### Catatan review

Review dua sumbu (standards + spec) dilakukan. Temuan yang sudah ditindaklanjuti:

- Menyatukan pencarian kategori dan memvalidasi target lewat helper domain agar form dan repository tidak menyimpang.
- Menghapus helper domain yang tidak terpakai dan menggunakan clock yang diinjeksi untuk pembuatan ID.
- Mempertahankan `targetTotal` saat jenis tugas diubah.
- Mengganti default target harian tugas baru menjadi `0` agar `Counter` tidak otomatis punya target.
- Menampilkan pesan kegagalan penyimpanan yang sebenarnya di dialog serta banner retry setelah dialog ditutup.
- Membatasi badge "Aktif" pada halaman detail agar kartu kategori tidak berubah di luar cakupan tiket.
- Menambahkan test persistensi tugas pada file nyata di direktori sementara.
