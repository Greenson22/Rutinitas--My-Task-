# 02: Controller — `editDailyLogEntry` & `deleteDailyLogEntry`

**What to build:** Tambahkan dua method baru ke `ChecklistDetailController` di `lib/features/checklist/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart`:

1. `editDailyLogEntry(DailySubject subject, String dateKey, List<DailyLogEntry> updatedEntries)` — mengganti entries pada key tanggal tertentu di `subject.dailyLogs`, lalu menyimpan dan me-refresh UI.
2. `deleteDailyLogEntry(DailySubject subject, String dateKey)` — menghapus key tanggal tertentu dari `subject.dailyLogs`, lalu menyimpan dan me-refresh UI.

Pola implementasi mengikuti method yang sudah ada: `deleteDailyLog` dan `deleteDailyLogsByMonth`.

**Blocked by:** —

**Status:** todo

- [ ] `editDailyLogEntry` melakukan `subject.dailyLogs[dateKey] = updatedEntries`.
- [ ] `editDailyLogEntry` memanggil method save (persist JSON) yang sudah ada.
- [ ] `editDailyLogEntry` memanggil `setState` / memicu refresh UI.
- [ ] `deleteDailyLogEntry` melakukan `subject.dailyLogs.remove(dateKey)`.
- [ ] `deleteDailyLogEntry` memanggil method save dan me-refresh UI.
- [ ] Widget/integration test: `editDailyLogEntry` mengubah entries yang sesuai tanpa mengubah entries hari lain.
- [ ] Widget/integration test: `deleteDailyLogEntry` menghapus key yang sesuai; key lain tetap ada.
- [ ] Seluruh test suite lama tetap lulus 100%.

---

## Catatan implementasi

_Diisi oleh agent setelah implementasi selesai._
