# 02: Controller — `editDailyLogEntry` & `deleteDailyLogEntry`

**What to build:** Tambahkan dua method baru ke `ChecklistDetailController` di `lib/features/checklist/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart`:

1. `editDailyLogEntry(DailySubject subject, String dateKey, List<DailyLogEntry> updatedEntries)` — mengganti entries pada key tanggal tertentu di `subject.dailyLogs`, lalu menyimpan dan me-refresh UI.
2. `deleteDailyLogEntry(DailySubject subject, String dateKey)` — menghapus key tanggal tertentu dari `subject.dailyLogs`, lalu menyimpan dan me-refresh UI.

Pola implementasi mengikuti method yang sudah ada: `deleteDailyLog` dan `deleteDailyLogsByMonth`.

**Blocked by:** —

**Status:** done

- [x] `editDailyLogEntry` melakukan `subject.dailyLogs[dateKey] = updatedEntries`.
- [x] `editDailyLogEntry` memanggil method save (persist JSON) yang sudah ada.
- [x] `editDailyLogEntry` memanggil `setState` / memicu refresh UI.
- [x] `deleteDailyLogEntry` melakukan `subject.dailyLogs.remove(dateKey)`.
- [x] `deleteDailyLogEntry` memanggil method save dan me-refresh UI.
- [x] Widget/integration test: `editDailyLogEntry` mengubah entries yang sesuai tanpa mengubah entries hari lain.
- [x] Widget/integration test: `deleteDailyLogEntry` menghapus key yang sesuai; key lain tetap ada.
- [x] Seluruh test suite lama tetap lulus 100%.

---

## Catatan implementasi

- Ditambahkan method `editDailyLogEntry(DailySubject subject, String dateKey, List<DailyLogEntry> updatedEntries)` ke `ChecklistDetailController` di `lib/features/checklist/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart`. Method ini membungkus penugasan `subject.dailyLogs[dateKey] = updatedEntries` dalam `setState` dan memanggil `saveGroupData()`.
- Ditambahkan method `deleteDailyLogEntry(DailySubject subject, String dateKey)` ke `ChecklistDetailController`. Method ini membungkus `subject.dailyLogs.remove(dateKey)` dalam `setState` dan memanggil `saveGroupData()`.
- Dibuat suite pengujian baru di `test/features/checklist/presentation/checklist_detail_controller_edit_delete_test.dart` untuk memvalidasi:
  1. `editDailyLogEntry` mengubah entry sesuai tanggal tanpa mengubah tanggal lain dan memanggil penyimpanan data.
  2. `deleteDailyLogEntry` menghapus tanggal yang sesuai dan mempertahankan entri tanggal lain.
  3. `deleteDailyLogEntry` pada tanggal yang tidak terdaftar tetap aman dan memanggil persistensi.
- Seluruh test suite (367 test cases total) lulus 100% tanpa regresi.
- Waktu selesai: 2026-11-24T09:12:30+08:00.
