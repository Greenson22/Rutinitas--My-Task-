# 09: Pencarian dan filter

**What to build:** Pengguna dapat mencari kategori dan tugas dari satu kolom, melihat hasil yang dikelompokkan per kategori, dan memfilter tugas berdasarkan status aktif, nonaktif, atau punya target hari ini. Pencarian merespons cepat dengan debounce dan menampilkan empty state yang jelas saat tidak ada hasil.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target

**Status:** ready-for-agent

- [ ] Pencarian mencakup nama kategori dan nama tugas.
- [ ] Hasil pencarian dikelompokkan per kategori dan menampilkan konteks kategori.
- [ ] Pencarian memakai debounce 250 ms.
- [ ] Filter minimal tersedia: semua, aktif, nonaktif, dan punya target hari ini.
- [ ] Filter dan pencarian dapat dipakai bersamaan.
- [ ] Tugas nonaktif yang muncul tetap memiliki badge nonaktif.
- [ ] Empty state “tidak ada hasil” menyediakan aksi menghapus pencarian/filter.
- [ ] Widget test pencarian, filter, dan empty state lulus.
