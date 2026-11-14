# 08: Dashboard “Hari Ini” dan ringkasan

**What to build:** Pengguna melihat dashboard yang langsung menjawab apa yang perlu dikerjakan hari ini: empat kartu ringkasan, daftar tugas yang punya target atau aktivitas hari ini, dan daftar kategori. Pengguna dapat melakukan increment langsung dari dashboard. Empty state mengarahkan pengguna baru untuk membuat kategori pertama.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target; 05 — Increment satu klik dan undo lokal; 06 — Integrasi Jurnal saat increment dan undo; 07 — Riwayat harian dan streak

**Status:** ready-for-agent

- [ ] Dashboard menampilkan jumlah kategori aktif, total tugas aktif, target selesai hari ini, dan durasi Jurnal hari ini.
- [ ] Daftar “Hari Ini” menampilkan tugas yang punya target harian atau aktivitas hari ini.
- [ ] Setiap baris “Hari Ini” menampilkan nama, kategori, progres harian, tombol increment, dan status target.
- [ ] Increment dari dashboard memakai alur yang sama dengan increment di halaman kategori.
- [ ] Daftar kategori menampilkan ikon, nama, jumlah tugas aktif, dan ringkasan progres hari ini.
- [ ] Kategori tersembunyi tidak tampil kecuali mode “Tampilkan tersembunyi” aktif.
- [ ] Empty state “belum ada kategori” dan “belum ada tugas hari ini” tampil sesuai konteks.
- [ ] Ringkasan akurat untuk tugas aktif, target tercapai, dan durasi Jurnal.
- [ ] Widget test dashboard untuk loading, ready, empty, dan increment lulus.
