# 03: Controller — deleteDailyLog & deleteDailyLogsByMonth

**What to build:** `ChecklistDetailController` mendapat dua method untuk mengelola penghapusan history. `deleteDailyLog()` menghapus seluruh `dailyLogs` pada satu `DailySubject` (menjadi map kosong `{}`). `deleteDailyLogsByMonth()` menerima parameter `yearMonth` berformat `yyyy-MM` dan menghapus hanya key-key yang diawali string tersebut — sehingga history bulan lain tetap utuh. Kedua method memanggil `saveGroupData()` setelah operasi.

**Blocked by:** 01

**Status:** done

- [x] `deleteDailyLog(DailySubject subject)` mengosongkan `subject.dailyLogs` menjadi `{}`.
- [x] `deleteDailyLog()` memanggil `saveGroupData()` setelah penghapusan.
- [x] `deleteDailyLogsByMonth(DailySubject subject, String yearMonth)` menghapus semua key yang diawali `yearMonth` (format `yyyy-MM`).
- [x] `deleteDailyLogsByMonth()` tidak mengubah key yang bulannya berbeda.
- [x] `deleteDailyLogsByMonth()` memanggil `saveGroupData()` setelah penghapusan.
- [x] Unit test: setelah `deleteDailyLog()`, `subject.dailyLogs` adalah map kosong `{}`.
- [x] Unit test: `deleteDailyLogsByMonth()` dengan `yearMonth = '2026-10'` pada log yang memiliki entry Oktober dan November hanya menghapus entry Oktober; entry November tetap ada.
- [x] Unit test: `deleteDailyLogsByMonth()` pada `dailyLogs` yang sudah kosong tidak menyebabkan error.

---

## Catatan implementasi

**Tanggal & Waktu:** 23 November 2026, 23:07:00+08:00

### Ringkasan
Method penghapusan history DailyTracker telah diimplementasikan di `ChecklistDetailController`:
1. **`deleteDailyLog(DailySubject subject)`**:
   - Memanggil `setState` untuk mengosongkan `subject.dailyLogs.clear()` sehingga menjadi `{}`.
   - Memanggil `saveGroupData()` untuk persistensi perubahan ke file storage.

2. **`deleteDailyLogsByMonth(DailySubject subject, String yearMonth)`**:
   - Menerima parameter `yearMonth` (misalnya `'2026-10'`).
   - Menggunakan `subject.dailyLogs.removeWhere((key, _) => key.startsWith(yearMonth))` di dalam `setState` untuk hanya menghapus key yang cocok dengan prefix bulan tersebut.
   - Entri di bulan lain tetap aman tidak terhapus.
   - Berjalan aman tanpa error meski `dailyLogs` kosong atau tidak ada entri yang cocok.
   - Memanggil `saveGroupData()`.

3. **Pengujian**:
   - Ditambahkan unit test di `test/features/checklist/presentation/checklist_detail_controller_ticket_03_test.dart`.
   - Menguji pengosongan seluruh map `dailyLogs` dan pemanggilan `saveGroupData`.
   - Menguji pemfilteran hapus per bulan (`yyyy-MM`) memastikan bulan lain tidak terpengaruh.
   - Menguji eksekusi pada `dailyLogs` kosong tidak menimbulkan exception.
   - Menguji prefix bulan yang tidak ada tidak memodifikasi data.
   - Seluruh test (4/4 test tiket 03, 13/13 test fitur checklist, dan 348/348 full test suite) lulus tanpa regresi.
