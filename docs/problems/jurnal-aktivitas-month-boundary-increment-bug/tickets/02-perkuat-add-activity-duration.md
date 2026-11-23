# 02: Perkuat `addActivityDuration` — hapus fallback bulan lama

**What to build:** Tombol "+ Waktu" harus selalu menambahkan durasi ke entri hari ini, bahkan ketika hari ini belum punya entri di `logs`. Saat ini, jika entri hari ini tidak ditemukan, kode jatuh ke fallback yang mencari task serupa di entri bulan sebelumnya dan menulis durasi ke sana — sehingga data tersimpan di file bulan yang salah dan tombol tampak tidak bekerja. Fallback ini harus dihilangkan dan diganti: jika entri hari ini belum ada, buat dulu entri baru untuk hari ini dengan task yang diminta, baru tambahkan durasinya. Riwayat bulan lama tidak boleh disentuh.

**Blocked by:** 01 — segarkan `currentActiveMonth` di awal `loadData`

**Status:** ready-for-agent

- [ ] Menekan tombol "+ Waktu" di hari pertama bulan baru berhasil menambahkan durasi — nilainya langsung terlihat berubah di UI.
- [ ] Jika entri hari ini belum ada di `logs`, entri baru dibuat untuk hari ini sebelum durasi ditambahkan.
- [ ] Tidak ada entri dengan tanggal selain hari ini yang dimodifikasi oleh operasi increment.
- [ ] File bulan sebelumnya tidak berubah setelah `saveData` dipanggil di bulan baru.
- [ ] Increment di hari-hari normal (entri hari ini sudah ada) tetap bekerja persis seperti sebelumnya — tidak ada regresi.
- [ ] Increment di hari pertama bulan baru dapat di-undo dengan benar (data dikurangi dari entri hari ini yang sama).
