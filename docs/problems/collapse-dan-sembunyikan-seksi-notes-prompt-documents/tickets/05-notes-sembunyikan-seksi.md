# 05: Notes — Sembunyikan Seksi

**What to build:** Di layar utama MyNotes, setiap seksi bisa disembunyikan lewat tombol mata di mode edit header. Saat seksi disembunyikan, header dan seluruh kartu grupnya tidak tampil sama sekali. Tombol mata (👁) di AppBar menjadi toggle global: tap sekali tampilkan semua seksi yang hidden (dengan visual berbeda/badge "Tersembunyi"), tap lagi sembunyikan kembali. State hidden seksi disimpan ke `notes_hidden_sections` di SharedPreferences (bukan ke file JSON data). `NoteGroup.isHidden` untuk grup individual tidak disentuh. Ketika seksi yang sebelumnya terlipat diperlihatkan kembali lewat tombol mata AppBar, seksi tersebut muncul dalam kondisi terlipat sesuai state collapse terakhirnya.

**Blocked by:** 02 — Notes Collapse Seksi (infrastruktur collapse harus ada agar interaksi collapse × hidden berfungsi).

**Status:** ready-for-agent

- [ ] Di mode edit header seksi, tombol mata muncul dan bisa di-tap untuk menyembunyikan seksi.
- [ ] Setelah disembunyikan, header seksi dan seluruh kartu grup di bawahnya tidak tampil di layar.
- [ ] Nama seksi tersimpan ke `notes_hidden_sections` di SharedPreferences setelah disembunyikan.
- [ ] Membuka ulang aplikasi: seksi yang tersembunyi tetap tidak tampil (`notes_hidden_sections` dimuat di `initState`).
- [ ] Tombol mata (👁) di AppBar muncul dan bisa di-tap untuk memperlihatkan semua seksi yang hidden.
- [ ] Saat `showHiddenSections = true`: seksi hidden muncul dengan visual berbeda (badge "Tersembunyi" dari `InteractiveSectionHeader`).
- [ ] Tap tombol mata AppBar lagi: seksi hidden kembali tidak tampil.
- [ ] Seksi yang di-hidden dalam kondisi terlipat → saat diperlihatkan lewat tombol AppBar, seksi tampil dengan ikon `chevron_right` (terlipat), konten kartu tidak tampil.
- [ ] `NoteGroup.isHidden` untuk kartu individual tidak berubah saat seksi di-hidden/un-hidden.
- [ ] Menyembunyikan seksi A tidak memengaruhi state seksi B.
- [ ] Widget test: tap 👁 edit mode → seksi tidak tampil; `notes_hidden_sections` di SharedPreferences memuat nama seksi.
- [ ] Widget test: tap 👁 AppBar → seksi hidden muncul dengan badge "Tersembunyi"; tap lagi → hilang.
- [ ] Widget test: seksi yang terlipat lalu di-hidden → saat diperlihatkan, ikon `chevron_right` ada, kartu grup tidak tampil.
- [ ] Widget test: `NoteGroup.isHidden` pada grup individual tidak berubah setelah seksi di-hidden.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.
