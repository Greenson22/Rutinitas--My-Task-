# 03: Controller — deleteDailyLog & deleteDailyLogsByMonth

**What to build:** `ChecklistDetailController` mendapat dua method untuk mengelola penghapusan history. `deleteDailyLog()` menghapus seluruh `dailyLogs` pada satu `DailySubject` (menjadi map kosong `{}`). `deleteDailyLogsByMonth()` menerima parameter `yearMonth` berformat `yyyy-MM` dan menghapus hanya key-key yang diawali string tersebut — sehingga history bulan lain tetap utuh. Kedua method memanggil `saveGroupData()` setelah operasi.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `deleteDailyLog(DailySubject subject)` mengosongkan `subject.dailyLogs` menjadi `{}`.
- [ ] `deleteDailyLog()` memanggil `saveGroupData()` setelah penghapusan.
- [ ] `deleteDailyLogsByMonth(DailySubject subject, String yearMonth)` menghapus semua key yang diawali `yearMonth` (format `yyyy-MM`).
- [ ] `deleteDailyLogsByMonth()` tidak mengubah key yang bulannya berbeda.
- [ ] `deleteDailyLogsByMonth()` memanggil `saveGroupData()` setelah penghapusan.
- [ ] Unit test: setelah `deleteDailyLog()`, `subject.dailyLogs` adalah map kosong `{}`.
- [ ] Unit test: `deleteDailyLogsByMonth()` dengan `yearMonth = '2026-10'` pada log yang memiliki entry Oktober dan November hanya menghapus entry Oktober; entry November tetap ada.
- [ ] Unit test: `deleteDailyLogsByMonth()` pada `dailyLogs` yang sudah kosong tidak menyebabkan error.
