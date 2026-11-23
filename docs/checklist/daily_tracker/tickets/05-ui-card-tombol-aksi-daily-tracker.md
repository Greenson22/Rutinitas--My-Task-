# 05: UI Card — Tombol Aksi DailyTracker (Simpan, Reset, Lihat History)

**What to build:** Ketika DailyTracker aktif pada sebuah card, tiga tombol aksi muncul di dalam card di `ChecklistDetailScreen`: "Simpan Hari Ini", "Reset Hari Baru", dan "Lihat History". "Simpan Hari Ini" memanggil `saveTodayLog()` dan menampilkan SnackBar konfirmasi dengan tanggal yang disimpan. "Reset Hari Baru" menampilkan dialog konfirmasi lalu memanggil `resetForNewDay()`. "Lihat History" menavigasi ke `DailyTrackerHistoryScreen`. Ketika DailyTracker nonaktif, tidak ada satu pun tombol ini yang tampil.

**Blocked by:** 02, 03, 04

**Status:** ready-for-agent

- [ ] Ketika `isDailyTrackerEnabled == true`, tombol "Simpan Hari Ini" tampil di dalam card.
- [ ] Menekan "Simpan Hari Ini" memanggil `saveTodayLog()` dan menampilkan SnackBar dengan pesan yang menyertakan tanggal yang baru disimpan.
- [ ] Ketika `isDailyTrackerEnabled == true`, tombol "Reset Hari Baru" tampil di dalam card.
- [ ] Menekan "Reset Hari Baru" menampilkan dialog konfirmasi; membatalkan dialog tidak melakukan perubahan apapun.
- [ ] Menekan "Konfirmasi" di dialog reset memanggil `resetForNewDay()` dan me-refresh tampilan item.
- [ ] Ketika `isDailyTrackerEnabled == true`, tombol "Lihat History" tampil di dalam card.
- [ ] Menekan "Lihat History" menavigasi ke `DailyTrackerHistoryScreen` dengan data `DailySubject` yang sesuai.
- [ ] Ketika `isDailyTrackerEnabled == false`, tidak ada satu pun dari ketiga tombol ini yang ada di tree widget.
- [ ] Widget test: ketiga tombol tampil ketika `isDailyTrackerEnabled == true`.
- [ ] Widget test: tidak ada tombol DailyTracker ketika `isDailyTrackerEnabled == false`.
- [ ] Widget test: menekan "Simpan Hari Ini" memunculkan SnackBar dengan teks yang mengandung tanggal hari ini.
