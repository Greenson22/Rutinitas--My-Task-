# 03: Prompt — Collapse Seksi

**What to build:** Di layar utama MyPrompt, setiap header seksi bisa di-tap untuk melipat atau membuka kartu-kartu grup prompt di bawahnya. Perilaku identik dengan tiket 02 (Notes), tetapi logika collapse diletakkan di `PromptController` (bukan di state layar secara langsung), dan state tersimpan ke key `prompt_collapsed_sections`. Ikon chevron muncul. Collapse hanya di layar utama.

**Blocked by:** 01 — Settings Dialog toggle baru.

**Status:** done

- [x] Tap pada header seksi di MyPrompt melipat kartu-kartu grup; ikon chevron berubah ke `chevron_right`.
- [x] Tap lagi membuka kartu-kartu grup; ikon chevron berubah ke `expand_more`.
- [x] Saat `sections_remember_collapse_state = true`: nama seksi yang terlipat tersimpan ke `prompt_collapsed_sections` di SharedPreferences.
- [x] Saat `sections_remember_collapse_state = true`: membuka ulang layar memulihkan state lipatan per seksi.
- [x] Saat `sections_remember_collapse_state = false`: `prompt_collapsed_sections` tidak berubah saat tap collapse.
- [x] Saat `sections_default_collapsed = true` dan remember off: semua seksi dimulai terlipat.
- [x] Saat `sections_default_collapsed = false` dan remember off: semua seksi dimulai terbuka.
- [x] Melipat seksi A tidak memengaruhi state seksi B.
- [x] Widget test: tap header → kartu grup hilang, chevron berubah.
- [x] Widget test: `sections_remember_collapse_state = true` → tap → `prompt_collapsed_sections` di SharedPreferences berisi nama seksi.
- [x] Widget test: `sections_remember_collapse_state = false` → tap → `prompt_collapsed_sections` tidak berubah.
- [x] Widget test: `sections_default_collapsed = true` → semua seksi terlipat saat build.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
