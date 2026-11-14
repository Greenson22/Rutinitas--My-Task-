# 11: Layout adaptif desktop/mobile dan aksesibilitas

**What to build:** Task Master New nyaman dipakai di mobile, tablet, dan desktop. Desktop memakai dua panel dengan daftar kategori di kiri dan detail di kanan; mobile memakai push ke halaman detail. Target sentuh, text scale, label aksesibilitas, dan keyboard shortcut terpenuhi.

**Blocked by:** 08 — Dashboard “Hari Ini” dan ringkasan; 09 — Pencarian dan filter; 10 — Reorder, pindah tugas, dan aksi massal

**Status:** ready-for-agent

- [ ] Breakpoint mobile (< 600 dp), tablet (600–1024 dp), dan desktop (> 1024 dp) bekerja.
- [ ] Desktop menampilkan dua panel dan tidak melakukan push screen untuk kategori.
- [ ] Mobile membuka halaman detail kategori melalui push dan kembali ke dashboard.
- [ ] Tablet memilih pola yang sesuai tanpa overflow.
- [ ] Target sentuh minimal 48×48 dp.
- [ ] Layout tidak overflow pada text scale 1.5.
- [ ] Ikon aksi dan progress bar memiliki label aksesibilitas.
- [ ] Keyboard shortcut desktop minimal: pencarian, tambah tugas, dan `Esc` menutup dialog.
- [ ] Fokus keyboard terlihat dengan jelas.
- [ ] Widget test layout mobile dan desktop lulus.
