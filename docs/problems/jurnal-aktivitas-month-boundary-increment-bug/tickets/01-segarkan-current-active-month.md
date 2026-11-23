# 01: Segarkan `currentActiveMonth` di awal `loadData`

**What to build:** Setiap kali `loadData` dipanggil, controller harus memperbarui bulan aktifnya ke waktu saat ini sebelum menentukan file jurnal mana yang akan dibaca atau dibuat. Dengan ini, ketika pengguna membuka Jurnal Aktivitas di hari pertama bulan baru, controller langsung menarget file bulan yang benar — bukan file bulan sebelumnya yang sudah di-cache sejak controller diinisialisasi. File bulan baru dibuat otomatis jika belum ada. Entri hari ini terbentuk di memori sehingga tampilan tidak lagi "error" saat berganti bulan. `saveData` juga otomatis benar karena bergantung pada nilai bulan aktif yang sama.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `loadData` memperbarui bulan aktif ke waktu saat ini sebagai langkah paling awal, sebelum path file jurnal ditentukan.
- [ ] File jurnal bulan baru dibuat secara otomatis jika belum ada (dengan konten kosong yang valid), tanpa error.
- [ ] Ketika bulan aktif sudah sama dengan bulan sekarang (kasus normal), perilaku tidak berubah — tidak ada regresi.
- [ ] Entri hari ini terbentuk di `logs` di memori ketika file bulan baru kosong atau belum punya riwayat hari ini.
- [ ] `saveData` yang dipanggil setelah `loadData` menulis ke file bulan yang benar (bulan baru, bukan bulan lama).
