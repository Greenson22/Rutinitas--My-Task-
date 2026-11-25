# 07: Documents — Sembunyikan Seksi

**What to build:** Di layar utama MyDocuments, seksi bisa disembunyikan lewat tombol mata di mode edit header, identik dengan tiket 05 (Notes). Tombol mata di AppBar untuk seksi menggunakan naming `showHiddenSections` (jamak) agar tidak bertabrakan dengan `showHiddenSection` (singular) yang sudah ada untuk grup individual. State disimpan ke `docs_hidden_sections` di SharedPreferences. `DocumentGroup.isHidden` untuk grup individual tidak disentuh. Fitur sembunyikan grup (via `showHiddenSection`) dan sembunyikan seksi (via `showHiddenSections`) dapat dioperasikan bersamaan tanpa konflik.

**Blocked by:** 04 — Documents Collapse Seksi.

**Status:** done

- [x] Di mode edit header seksi di MyDocuments, tombol mata muncul dan bisa di-tap untuk menyembunyikan seksi.
- [x] Setelah disembunyikan, header dan seluruh kartu grup dokumen tidak tampil.
- [x] Nama seksi tersimpan ke `docs_hidden_sections` di SharedPreferences.
- [x] Membuka ulang aplikasi: seksi yang tersembunyi tetap tidak tampil.
- [x] Tombol mata (👁) di AppBar toggle global tampilkan/sembunyikan semua seksi hidden (terpisah dari toggle untuk grup hidden yang sudah ada).
- [x] Saat `showHiddenSections = true`: seksi hidden muncul dengan badge "Tersembunyi".
- [x] Seksi yang terlipat lalu di-hidden → saat diperlihatkan, tetap dalam kondisi terlipat.
- [x] `DocumentGroup.isHidden` untuk grup individual tidak berubah saat seksi di-hidden.
- [x] `showHiddenSection` untuk grup individual tetap berfungsi independen dari `showHiddenSections` untuk seksi.
- [x] Menyembunyikan seksi X tidak menyembunyikan grup individual yang ada di dalam seksi Y.
- [x] Widget test: tap 👁 edit mode seksi → seksi hilang; `docs_hidden_sections` di SharedPreferences memuat nama seksi.
- [x] Widget test: tap 👁 AppBar untuk seksi → seksi muncul; tap lagi → hilang. Toggle ini tidak mempengaruhi visibilitas grup hidden.
- [x] Widget test: `showHiddenSection` untuk grup individual tetap berjalan setelah `showHiddenSections` untuk seksi ditambahkan.
- [x] Widget test: seksi terlipat + hidden → saat diperlihatkan, ikon `chevron_right` ada, kartu tidak tampil.
- [x] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
