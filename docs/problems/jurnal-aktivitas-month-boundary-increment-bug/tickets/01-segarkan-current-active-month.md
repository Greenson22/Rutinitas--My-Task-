# 01: Segarkan `currentActiveMonth` di awal `loadData`

**What to build:** Setiap kali `loadData` dipanggil, controller harus memperbarui bulan aktifnya ke waktu saat ini sebelum menentukan file jurnal mana yang akan dibaca atau dibuat. Dengan ini, ketika pengguna membuka Jurnal Aktivitas di hari pertama bulan baru, controller langsung menarget file bulan yang benar — bukan file bulan sebelumnya yang sudah di-cache sejak controller diinisialisasi. File bulan baru dibuat otomatis jika belum ada. Entri hari ini terbentuk di memori sehingga tampilan tidak lagi "error" saat berganti bulan. `saveData` juga otomatis benar karena bergantung pada nilai bulan aktif yang sama.

**Blocked by:** None (can start immediately)

**Status:** completed

- [x] `loadData` memperbarui bulan aktif ke waktu saat ini sebagai langkah paling awal, sebelum path file jurnal ditentukan.
- [x] File jurnal bulan baru dibuat secara otomatis jika belum ada (dengan konten kosong yang valid), tanpa error.
- [x] Ketika bulan aktif sudah sama dengan bulan sekarang (kasus normal), perilaku tidak berubah — tidak ada regresi.
- [x] Entri hari ini terbentuk di `logs` di memori ketika file bulan baru kosong atau belum punya riwayat hari ini.
- [x] `saveData` yang dipanggil setelah `loadData` menulis ke file bulan yang benar (bulan baru, bukan bulan lama).

---

## Catatan Implementasi & Riwayat Waktu

- **Waktu Mulai**: 2026-11-23T10:00:40+08:00
- **Waktu Selesai**: 2026-11-23T10:15:45+08:00
- **Durasi**: ~15 menit

### Rangkuman Pekerjaan:
1. Menambahkan parameter injeksi opsional `_clock` pada `JurnalAktivitasController` dengan default `DateTime.now`, sehingga waktu controller dapat diuji secara deterministik saat simulasi pergantian bulan.
2. Memperbarui `loadData`:
   - `currentActiveMonth = _clock();` dijalankan di baris awal sebelum pemanggilan file jurnal.
   - Pengecekan bulan aktif dan penggabungan kerangka template dengan riwayat hari ini menggunakan `_clock()` yang konsisten.
   - Menggunakan `_clock()` pada `getTodayDateString()`.
3. Menambahkan pengujian komprehensif di `test/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller_ticket_01_test.dart` yang menguji:
   - Pembaruan `currentActiveMonth` dan penentuan file jurnal bulan baru.
   - Pembuatan file bulan baru secara otomatis dan inisialisasi entri hari ini dari template tugas.
   - `saveData` menyimpan ke file bulan baru tanpa menyentuh file bulan sebelumnya.
   - Integritas skenario normal tanpa regresi.
4. Menjalankan analisis statis dan seluruh test suite proyek (301 tests) dengan hasil lulus 100%.
