# 04: Documents — Collapse Seksi

**What to build:** Di layar utama MyDocuments, setiap header seksi bisa di-tap untuk melipat atau membuka kartu-kartu grup dokumen. Perilaku identik dengan tiket 02 (Notes) dan 03 (Prompt), tetapi logika collapse diletakkan di `DocumentsController` yang sudah ada. State tersimpan ke key `docs_collapsed_sections`. Implementasi tidak boleh bertabrakan dengan `showHiddenSection` (boolean untuk grup individual) yang sudah ada di controller. Collapse hanya di layar utama.

**Blocked by:** 01 — Settings Dialog toggle baru.

**Status:** ready-for-agent

- [ ] Tap pada header seksi di MyDocuments melipat kartu-kartu grup; ikon chevron berubah ke `chevron_right`.
- [ ] Tap lagi membuka kartu-kartu grup; ikon chevron berubah ke `expand_more`.
- [ ] Saat `sections_remember_collapse_state = true`: nama seksi terlipat tersimpan ke `docs_collapsed_sections` di SharedPreferences.
- [ ] Saat `sections_remember_collapse_state = true`: membuka ulang layar memulihkan state lipatan.
- [ ] Saat `sections_remember_collapse_state = false`: `docs_collapsed_sections` tidak berubah saat tap collapse.
- [ ] Saat `sections_default_collapsed = true` dan remember off: semua seksi dimulai terlipat.
- [ ] `showHiddenSection` yang sudah ada (untuk grup individual) tidak tersentuh dan tetap berjalan seperti semula.
- [ ] Collapse seksi dan toggle `showHiddenSection` untuk grup individual dapat dioperasikan secara bersamaan tanpa konflik.
- [ ] Widget test: tap header → kartu grup hilang, chevron berubah.
- [ ] Widget test: `sections_remember_collapse_state = true` → tap → `docs_collapsed_sections` berisi nama seksi.
- [ ] Widget test: `showHiddenSection` untuk grup tetap berfungsi setelah collapse seksi ditambahkan.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
