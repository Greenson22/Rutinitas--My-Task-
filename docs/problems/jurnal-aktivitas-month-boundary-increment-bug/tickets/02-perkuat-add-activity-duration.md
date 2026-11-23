# 02: Perkuat `addActivityDuration` — hapus fallback bulan lama

**What to build:** Tombol "+ Waktu" harus selalu menambahkan durasi ke entri hari ini, bahkan ketika hari ini belum punya entri di `logs`. Saat ini, jika entri hari ini tidak ditemukan, kode jatuh ke fallback yang mencari task serupa di entri bulan sebelumnya dan menulis durasi ke sana — sehingga data tersimpan di file bulan yang salah dan tombol tampak tidak bekerja. Fallback ini harus dihilangkan dan diganti: jika entri hari ini belum ada, buat dulu entri baru untuk hari ini dengan task yang diminta, baru tambahkan durasinya. Riwayat bulan lama tidak boleh disentuh.

**Blocked by:** 01 — segarkan `currentActiveMonth` di awal `loadData`

**Status:** completed

- [x] Menekan tombol "+ Waktu" di hari pertama bulan baru berhasil menambahkan durasi — nilainya langsung terlihat berubah di UI.
- [x] Jika entri hari ini belum ada di `logs`, entri baru dibuat untuk hari ini sebelum durasi ditambahkan.
- [x] Tidak ada entri dengan tanggal selain hari ini yang dimodifikasi oleh operasi increment.
- [x] File bulan sebelumnya tidak berubah setelah `saveData` dipanggil di bulan baru.
- [x] Increment di hari-hari normal (entri hari ini sudah ada) tetap bekerja persis seperti sebelumnya — tidak ada regresi.
- [x] Increment di hari pertama bulan baru dapat di-undo dengan benar (data dikurangi dari entri hari ini yang sama).

---

## Catatan Implementasi & Riwayat Waktu

- **Waktu Mulai**: 2026-11-23T10:16:58+08:00
- **Waktu Selesai**: 2026-11-23T10:26:30+08:00
- **Durasi**: ~10 menit

### Rangkuman Pekerjaan:
1. Menghapus logika fallback `for (var logEntry in logs.reversed)` pada metode `addActivityDuration` di `JurnalAktivitasController` yang sebelumnya keliru mencari task di entri tanggal lampau/bulan sebelumnya dan menambahkan durasi ke sana.
2. Memperkuat `addActivityDuration` dengan:
   - Jika `todayIdx == -1` (belum ada entri untuk hari ini di `logs`), buat entri baru `TimeLogEntry` untuk tanggal hari ini (`todayStr`) berisi task yang di-increment dengan durasi awal 0 menit.
   - Jika entri hari ini sudah ada tetapi belum mengandung task yang diminta (`taskIdx == -1`), tambahkan task baru ke entri hari ini dengan durasi awal 0 menit.
   - Menambahkan `minutes` ke task pada entri hari ini (`logs[todayIdx].tasks[taskIdx].durasiMenit += minutes;`).
   - Memastikan tidak ada entri dengan tanggal selain hari ini yang dimodifikasi.
   - Mendukung undo increment (pengurangan durasi dengan nilai negatif).
3. Mengikuti alur TDD dengan menulis unit test di `test/features/jurnal_aktivitas/presentation/controllers/jurnal_aktivitas_controller_ticket_02_test.dart` yang awalnya gagal (merah) mereproduksi masalah fallback bulan lama, kemudian berhasil lulus (hijau) setelah implementasi diperbaiki.
4. Menjalankan seluruh test suite proyek (306 test), semuanya lulus 100%.
