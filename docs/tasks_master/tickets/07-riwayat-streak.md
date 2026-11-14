# 07: Riwayat harian dan streak

**What to build:** Pengguna dapat melihat riwayat harian tugas dan streak yang dihitung dari data nyata. Riwayat bersifat sparse, hanya menyimpan tanggal dengan hitungan, dan dipangkas maksimal 365 hari per tugas. Streak mengikuti target harian jika ada; jika tidak, mengikuti aktivitas.

**Blocked by:** 05 — Increment satu klik dan undo lokal

**Status:** ready-for-agent

- [ ] Riwayat harian tugas dapat dilihat dan tetap ada setelah aplikasi dibuka kembali.
- [ ] `countToday` diturunkan dari riwayat hari ini, bukan dari reset terjadwal.
- [ ] Pergantian hari membuat hitungan hari ini menjadi nol tanpa job reset.
- [ ] Streak dihitung dari hari kemarin ke belakang.
- [ ] Jika target harian tersedia, hari berhasil hanya bila hitungan mencapai target.
- [ ] Jika target harian nol, hari dianggap aktif bila ada hitungan.
- [ ] Hari ini yang belum dikerjakan tidak memutus streak.
- [ ] Riwayat lebih dari 365 hari dipangkas saat penulisan.
- [ ] Definisi selesai konsisten untuk `Habit`, `Counter`, dan `Progress`.
- [ ] Unit test streak dan pemangkasan riwayat lulus.
