# 02: Notes — Collapse Seksi

**What to build:** Di layar utama MyNotes, setiap header seksi bisa di-tap untuk melipat atau membuka kartu-kartu grup di bawahnya. Ikon chevron (▶/▼) muncul di kiri nama seksi sebagai indikator kondisi lipatan. State terlipat per seksi disimpan ke SharedPreferences (`notes_collapsed_sections`) jika pengaturan "Ingat status lipatan seksi" aktif; jika tidak, state hanya di memori dan diinisialisasi dari pengaturan "Tutup seksi secara default". Collapse hanya ada di layar utama (layar grup/seksi), bukan di layar detail grup.

**Blocked by:** 01 — Settings Dialog toggle baru (harus ada `sections_default_collapsed` dan `sections_remember_collapse_state` sebelum layar bisa membacanya).

**Status:** ready-for-agent

- [ ] Tap pada header seksi melipat kartu-kartu grup di bawahnya; ikon chevron berubah dari `expand_more` ke `chevron_right`.
- [ ] Tap lagi pada header yang terlipat membuka kembali kartu-kartu grup; ikon chevron berubah dari `chevron_right` ke `expand_more`.
- [ ] Animasi `AnimatedCrossFade` digunakan untuk transisi lipat/buka (tidak ada perubahan pada `GroupedSectionLayout`).
- [ ] Saat `sections_remember_collapse_state = true`: setelah tap collapse, nama seksi tersimpan ke `notes_collapsed_sections` di SharedPreferences.
- [ ] Saat `sections_remember_collapse_state = true`: saat layar dibuka ulang, seksi yang sebelumnya terlipat kembali terlipat.
- [ ] Saat `sections_remember_collapse_state = false`: tap collapse tidak mengubah `notes_collapsed_sections` di SharedPreferences (state hanya di memori).
- [ ] Saat `sections_default_collapsed = true` dan `sections_remember_collapse_state = false`: semua seksi dimulai terlipat saat layar dibuka.
- [ ] Saat `sections_default_collapsed = false` dan `sections_remember_collapse_state = false`: semua seksi dimulai terbuka saat layar dibuka.
- [ ] Melipat seksi A tidak memengaruhi state seksi B.
- [ ] Widget test: tap header → kartu grup hilang, chevron berubah ke `chevron_right`.
- [ ] Widget test: tap header lagi → kartu grup muncul, chevron berubah ke `expand_more`.
- [ ] Widget test: `sections_remember_collapse_state = true` → tap collapse → `notes_collapsed_sections` di SharedPreferences memuat nama seksi.
- [ ] Widget test: `sections_remember_collapse_state = false` → tap collapse → `notes_collapsed_sections` tidak berubah.
- [ ] Widget test: `sections_default_collapsed = true` → semua seksi terlipat saat build.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
