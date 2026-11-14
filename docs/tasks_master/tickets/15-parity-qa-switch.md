# 15: Parity QA dan switch navigasi

**What to build:** Task Master New mencapai parity dengan fitur lama, lulus QA manual di Android dan Linux desktop, lalu navigasi aplikasi dialihkan ke modul baru. Versi lama tetap tersedia sebagai fallback dan tidak menulis data setelah switch.

**Blocked by:** 03 — Kelola kategori dengan identitas stabil; 04 — Kelola tugas, jenis tugas, dan target; 05 — Increment satu klik dan undo lokal; 06 — Integrasi Jurnal saat increment dan undo; 07 — Riwayat harian dan streak; 08 — Dashboard “Hari Ini” dan ringkasan; 09 — Pencarian dan filter; 10 — Reorder, pindah tugas, dan aksi massal; 11 — Layout adaptif desktop/mobile dan aksesibilitas; 12 — Recovery, editor JSON advanced, dan pengaturan di modul baru; 13 — Kompatibilitas Data Center dan migrasi saat import; 14 — Hardening performa data besar dan kegagalan simpan

**Status:** ready-for-agent

- [ ] Checklist parity fitur lama terpenuhi.
- [ ] QA manual Android lulus untuk data baru, data lama, enkripsi, dan rotasi layar.
- [ ] QA manual Linux desktop lulus untuk resize window dan keyboard.
- [ ] Increment, Jurnal, Checklist, dan Data Center tidak mengalami regresi.
- [ ] Navigasi aplikasi diarahkan ke Task Master New.
- [ ] Modul lama tidak lagi menulis data setelah switch.
- [ ] Prosedur rollback ke modul lama dan pemulihan backup didokumentasikan.
- [ ] `flutter analyze` dan seluruh test lulus.
