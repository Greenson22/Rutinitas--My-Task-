# 03: Unit test skenario pergantian bulan di `JurnalAktivitasController`

**What to build:** Tambahkan serangkaian unit test yang mereproduksi bug secara deterministik dan memverifikasi bahwa perbaikan dari tiket 01 dan 02 bekerja. Test menggunakan direktori sementara dan waktu yang dapat dikendalikan agar skenario pergantian bulan dapat disimulasikan tanpa menunggu kalender. Setiap test harus lulus secara independen dan tidak meninggalkan file di disk setelah selesai.

**Blocked by:** 01 — segarkan `currentActiveMonth` di awal `loadData`, 02 — perkuat `addActivityDuration`

**Status:** completed

- [x] Test: `loadData` yang dipanggil di hari pertama bulan baru membaca/membuat file bulan yang benar, bukan file bulan sebelumnya.
- [x] Test: setelah `loadData` di bulan baru, `logs` di memori mengandung entri untuk hari ini (tanggal bulan baru).
- [x] Test: `addActivityDuration` di hari pertama bulan baru menambahkan durasi ke entri hari ini — bukan ke entri bulan sebelumnya.
- [x] Test: `saveData` setelah increment di bulan baru menulis ke file bulan baru; file bulan lama tidak berubah.
- [x] Test: `loadData` yang dipanggil dua kali berturut-turut di bulan yang sama tidak menduplikasi entri hari ini.
- [x] Test: skenario normal (pertengahan bulan, entri hari ini sudah ada) tetap lulus tanpa perubahan perilaku.
- [x] Semua test menggunakan direktori sementara dan dibersihkan setelah selesai (tidak ada sisa file di disk).

---

## Catatan Implementasi & Riwayat Waktu

- **Waktu Mulai**: 2026-11-23T10:27:37+08:00
- **Waktu Selesai**: 2026-11-23T10:33:50+08:00
- **Durasi**: ~6 menit

### Rangkuman Pekerjaan:
1. Menambahkan suite unit test komprehensif di `test/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller_ticket_03_test.dart` yang mencakup:
   - Verifikasi `loadData` di hari pertama bulan baru membaca dan membuat file bulan baru yang benar (`jurnal_YYYY_MM.json`), bukan file bulan lampau.
   - Verifikasi setelah `loadData` di bulan baru, struktur `logs` di memori memiliki entri hari ini dengan template tugas berdurasi 0 menit.
   - Verifikasi `addActivityDuration` di hari pertama bulan baru menambahkan durasi hanya ke entri hari ini (tanpa menyentuh entri bulan lampau).
   - Verifikasi `saveData` setelah penambahan durasi di bulan baru menulis ke file bulan baru dan file bulan lampau tetap utuh.
   - Verifikasi idempotensi pemanggilan `loadData` berturut-turut di bulan yang sama agar tidak menduplikasi entri hari ini.
   - Verifikasi skenario normal (pertengahan bulan di mana entri hari ini sudah ada) berjalan tanpa regresi.
   - Seluruh test menggunakan direktori sementara sistem (`Directory.systemTemp.createTemp`) dan membersihkannya secara otomatis pada `tearDown`.
2. Menjalankan analisis dan pengujian:
   - `flutter test test/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller_ticket_03_test.dart` lulus (7 tests).
   - `flutter test` penuh pada seluruh project lulus 100% (313 tests).
