# 06: Prompt — Sembunyikan Seksi

**What to build:** Di layar utama MyPrompt, seksi bisa disembunyikan lewat tombol mata di mode edit header, identik dengan tiket 05 (Notes). Tombol mata di AppBar menjadi toggle global untuk semua seksi hidden di Prompt. State disimpan ke `prompt_hidden_sections` di SharedPreferences. `PromptGroup.isHidden` untuk grup individual tidak disentuh. Seksi yang sebelumnya terlipat tetap terlipat saat diperlihatkan kembali.

**Blocked by:** 03 — Prompt Collapse Seksi.

**Status:** done

- [x] Di mode edit header seksi di MyPrompt, tombol mata muncul dan bisa di-tap untuk menyembunyikan seksi.
- [x] Setelah disembunyikan, header dan seluruh kartu grup prompt tidak tampil.
- [x] Nama seksi tersimpan ke `prompt_hidden_sections` di SharedPreferences.
- [x] Membuka ulang aplikasi: seksi yang tersembunyi tetap tidak tampil.
- [x] Tombol mata (👁) di AppBar toggle global tampilkan/sembunyikan semua seksi hidden.
- [x] Saat `showHiddenSections = true`: seksi hidden muncul dengan badge "Tersembunyi".
- [x] Seksi yang terlipat lalu di-hidden → saat diperlihatkan, tetap dalam kondisi terlipat.
- [x] `PromptGroup.isHidden` untuk grup individual tidak berubah.
- [x] Widget test: tap 👁 edit mode → seksi hilang; `prompt_hidden_sections` di SharedPreferences memuat nama seksi.
- [x] Widget test: tap 👁 AppBar → seksi muncul dengan badge; tap lagi → hilang.
- [x] Widget test: seksi terlipat + hidden → saat diperlihatkan, ikon `chevron_right` ada, kartu tidak tampil.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
