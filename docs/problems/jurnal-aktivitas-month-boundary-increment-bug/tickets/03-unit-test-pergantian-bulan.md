# 03: Unit test skenario pergantian bulan di `JurnalAktivitasController`

**What to build:** Tambahkan serangkaian unit test yang mereproduksi bug secara deterministik dan memverifikasi bahwa perbaikan dari tiket 01 dan 02 bekerja. Test menggunakan direktori sementara dan waktu yang dapat dikendalikan agar skenario pergantian bulan dapat disimulasikan tanpa menunggu kalender. Setiap test harus lulus secara independen dan tidak meninggalkan file di disk setelah selesai.

**Blocked by:** 01 — segarkan `currentActiveMonth` di awal `loadData`, 02 — perkuat `addActivityDuration`

**Status:** ready-for-agent

- [ ] Test: `loadData` yang dipanggil di hari pertama bulan baru membaca/membuat file bulan yang benar, bukan file bulan sebelumnya.
- [ ] Test: setelah `loadData` di bulan baru, `logs` di memori mengandung entri untuk hari ini (tanggal bulan baru).
- [ ] Test: `addActivityDuration` di hari pertama bulan baru menambahkan durasi ke entri hari ini — bukan ke entri bulan sebelumnya.
- [ ] Test: `saveData` setelah increment di bulan baru menulis ke file bulan baru; file bulan lama tidak berubah.
- [ ] Test: `loadData` yang dipanggil dua kali berturut-turut di bulan yang sama tidak menduplikasi entri hari ini.
- [ ] Test: skenario normal (pertengahan bulan, entri hari ini sudah ada) tetap lulus tanpa perubahan perilaku.
- [ ] Semua test menggunakan direktori sementara dan dibersihkan setelah selesai (tidak ada sisa file di disk).
