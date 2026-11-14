# 04: Kelola tugas, jenis tugas, dan target

**What to build:** Pengguna dapat membuka halaman detail kategori dan mengelola tugas di dalamnya: menambah, mengedit, menghapus, serta memilih `TaskKind` (`Habit`, `Counter`, `Progress`) dengan target yang sesuai. Daftar tugas menampilkan hitungan hari ini, total, badge jenis, progress bar untuk `Progress`, dan status aktif/nonaktif.

**Blocked by:** 03 — Kelola kategori dengan identitas stabil

**Status:** ready-for-agent

- [ ] Pengguna dapat menambah tugas ke kategori dengan nama, jenis, target harian, target total, dan status aktif.
- [ ] `Progress` mewajibkan target total lebih dari nol; target harian tidak boleh negatif.
- [ ] Pengguna dapat mengedit semua field tugas tanpa kehilangan `id`.
- [ ] Pengguna dapat menghapus tugas dengan konfirmasi.
- [ ] Pengguna dapat menonaktifkan dan mengaktifkan kembali tugas.
- [ ] Daftar tugas menampilkan badge jenis, total, hitungan hari ini, progress bar `Progress`, dan status aktif.
- [ ] Perubahan tugas bertahan setelah aplikasi ditutup dan dibuka kembali.
- [ ] Widget test form tugas, validasi target, dan daftar tugas lulus.
