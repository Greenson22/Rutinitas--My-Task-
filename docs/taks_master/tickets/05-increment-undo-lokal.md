# 05: Increment satu klik dan undo lokal

**What to build:** Pengguna menaikkan hitungan tugas dengan satu klik. UI berubah seketika, hitungan total, hitungan hari ini, dan riwayat hari ini ikut bertambah, lalu data disimpan tanpa memblokir tampilan. Setelah increment, SnackBar menampilkan Undo selama 5 detik untuk mengembalikan perubahan.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target

**Status:** ready-for-agent

- [ ] Increment memperbarui total, hitungan hari ini, dan riwayat hari ini dalam satu aksi.
- [ ] UI berubah seketika tanpa menunggu penulisan file.
- [ ] Tidak ada dialog konfirmasi setiap kali increment.
- [ ] SnackBar Undo tampil selama 5 detik setelah increment.
- [ ] Undo mengembalikan total, hitungan hari ini, dan riwayat hari ini.
- [ ] Hanya increment terakhir yang dapat di-undo.
- [ ] Tombol increment aman dari double tap yang tidak disengaja.
- [ ] Perubahan tetap tersimpan setelah aplikasi ditutup dan dibuka kembali.
- [ ] Unit test increment/undo dan widget test SnackBar Undo lulus.
