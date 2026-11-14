# 06: Integrasi Jurnal saat increment dan undo

**What to build:** Tugas yang tertaut ke Jurnal ditandai. Saat pengguna melakukan increment pada tugas tertaut, durasi Jurnal bertambah sesuai pengaturan template, dengan fallback 30 menit. Saat Undo, durasi yang sama dikurangi kembali. Jika rollback Jurnal gagal, data Task Master tetap kembali dan pengguna mendapat peringatan.

**Blocked by:** 05 — Increment satu klik dan undo lokal

**Status:** ready-for-agent

- [ ] Tugas yang memiliki `linkedTaskIds` di Jurnal menampilkan indikator tertaut.
- [ ] Increment tugas tertaut menambah durasi sesuai pengaturan template Jurnal.
- [ ] Jika pengaturan tidak tersedia atau tidak valid, durasi fallback 30 menit dipakai.
- [ ] Increment tugas yang tidak tertaut tetap menaikkan hitungan tanpa mengubah Jurnal.
- [ ] Undo mengurangi durasi yang ditambahkan ke Jurnal.
- [ ] Rollback Jurnal yang gagal tidak membatalkan rollback data Task Master dan menampilkan peringatan jelas.
- [ ] File Jurnal terenkripsi tetap dapat dibaca dan ditulis.
- [ ] Relasi Jurnal tidak disalin ke data Task Master.
- [ ] Contract test `JournalGateway` untuk tambah, kurangi, fallback, enkripsi, dan kegagalan lulus.
