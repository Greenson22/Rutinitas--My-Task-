# 05: UI Card — Tombol Aksi DailyTracker (Simpan, Reset, Lihat History)

**What to build:** Ketika DailyTracker aktif pada sebuah card, tiga tombol aksi muncul di dalam card di `ChecklistDetailScreen`: "Simpan Hari Ini", "Reset Hari Baru", dan "Lihat History". "Simpan Hari Ini" memanggil `saveTodayLog()` dan menampilkan SnackBar konfirmasi dengan tanggal yang disimpan. "Reset Hari Baru" menampilkan dialog konfirmasi lalu memanggil `resetForNewDay()`. "Lihat History" menavigasi ke `DailyTrackerHistoryScreen`. Ketika DailyTracker nonaktif, tidak ada satu pun tombol ini yang tampil.

**Blocked by:** 02, 03, 04

**Status:** done

- [x] Ketika `isDailyTrackerEnabled == true`, tombol "Simpan Hari Ini" tampil di dalam card.
- [x] Menekan "Simpan Hari Ini" memanggil `saveTodayLog()` dan menampilkan SnackBar dengan pesan yang menyertakan tanggal yang baru disimpan.
- [x] Ketika `isDailyTrackerEnabled == true`, tombol "Reset Hari Baru" tampil di dalam card.
- [x] Menekan "Reset Hari Baru" menampilkan dialog konfirmasi; membatalkan dialog tidak melakukan perubahan apapun.
- [x] Menekan "Konfirmasi" di dialog reset memanggil `resetForNewDay()` dan me-refresh tampilan item.
- [x] Ketika `isDailyTrackerEnabled == true`, tombol "Lihat History" tampil di dalam card.
- [x] Menekan "Lihat History" menavigasi ke `DailyTrackerHistoryScreen` dengan data `DailySubject` yang sesuai.
- [x] Ketika `isDailyTrackerEnabled == false`, tidak ada satu pun dari ketiga tombol ini yang ada di tree widget.
- [x] Widget test: ketiga tombol tampil ketika `isDailyTrackerEnabled == true`.
- [x] Widget test: tidak ada tombol DailyTracker ketika `isDailyTrackerEnabled == false`.
- [x] Widget test: menekan "Simpan Hari Ini" memunculkan SnackBar dengan teks yang mengandung tanggal hari ini.

---

## Catatan implementasi

**Tanggal & Waktu Selesai:** 24 November 2026, 08:08:00+08:00

### Ringkasan Pekerjaan
Fitur UI Card untuk tiga tombol aksi DailyTracker berhasil diimplementasikan:
1. **Tombol Aksi pada Card (`ChecklistDetailScreen`)**:
   - Menambahkan 3 tombol aksi di dalam card `DailySubject` (jika `isDailyTrackerEnabled == true` dan `type != 'note'`):
     - **"Simpan Hari Ini"** (`Key('btn_save_today_log')`): Memanggil `saveTodayLog(subject)`, mendapatkan string tanggal key yang disimpan, lalu memunculkan SnackBar dengan pesan yang memuat tanggal tersebut.
     - **"Reset Hari Baru"** (`Key('btn_reset_for_new_day')`): Memanggil `resetForNewDay(subject)` yang memunculkan dialog konfirmasi. Jika dikonfirmasi, semua sub-item checklist direset ke `progress: 'belum'` dan `currentValue: 0` serta me-refresh tampilan UI.
     - **"Lihat History"** (`Key('btn_view_history')`): Menavigasi ke `DailyTrackerHistoryScreen` dengan mengoper instance `DailySubject`.
   - Ketika `isDailyTrackerEnabled == false`, ketiga tombol tidak ada di tree widget (zero visual noise).
   - Membungkus konten card dengan `SingleChildScrollView` hanya ketika `isDailyTrackerEnabled == true` untuk mencegah `RenderFlex` overflow pada layar berukuran padat tanpa mengorbankan card biasa.

2. **Penyempurnaan Controller (`ChecklistDetailController`)**:
   - `saveTodayLog(subject)` diperbarui agar mengembalikan `Future<String>` (key tanggal yang disimpan) guna menjamin konsistensi tanggal antara data yang disimpan di `dailyLogs` dan pesan SnackBar yang ditampilkan ke pengguna.

3. **Placeholder Screen**:
   - Dibuat `DailyTrackerHistoryScreen` di `lib/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart` untuk mendukung navigasi dan verifikasi tiket 05, yang siap diimplementasikan secara komprehensif pada Tiket 06.

4. **Pengujian & Review**:
   - Widget test komprehensif ditambahkan di `test/features/checklist/presentation/checklist_card_ticket_05_test.dart` (6/6 test lulus).
   - Seluruh test modul checklist (23/23 test) dan full test suite proyek (358/358 test) lulus tanpa kegagalan maupun regresi.
