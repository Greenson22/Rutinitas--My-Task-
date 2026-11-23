# 02: Controller — saveTodayLog & resetForNewDay

**What to build:** `ChecklistDetailController` mendapat dua method baru untuk operasi inti DailyTracker. `saveTodayLog()` membuat snapshot seluruh item di `DailySubject` secara rekursif dan menyimpannya ke `dailyLogs` dengan key tanggal hari ini (`yyyy-MM-dd`); jika key sudah ada (pengguna simpan dua kali di hari yang sama), entry lama di-overwrite. `resetForNewDay()` mereset progress seluruh `SubSubjectItem` secara rekursif ke `belum` dan `currentValue` ke `0`, diawali dialog konfirmasi — tanpa menyentuh `dailyLogs` yang sudah tersimpan. Kedua method memanggil `saveGroupData()` yang sudah ada setelah operasi selesai.

**Blocked by:** 01

**Status:** done

- [x] `saveTodayLog(DailySubject subject)` membuat `List<DailyLogEntry>` dari seluruh `subMateri` secara rekursif menggunakan `DailyLogEntry.fromSubSubjectItem()`.
- [x] `saveTodayLog()` menyimpan hasil snapshot ke `subject.dailyLogs[tanggalHariIni]` (format `yyyy-MM-dd`), menimpa entry lama jika sudah ada.
- [x] `saveTodayLog()` memanggil `saveGroupData()` setelah update.
- [x] `resetForNewDay(DailySubject subject)` menampilkan dialog konfirmasi sebelum melakukan reset.
- [x] `resetForNewDay()` mereset `progress` ke `'belum'` dan `currentValue` ke `0` pada seluruh `SubSubjectItem` secara rekursif (termasuk semua level anak).
- [x] `resetForNewDay()` tidak mengubah `dailyLogs` sama sekali.
- [x] `resetForNewDay()` memanggil `saveGroupData()` setelah reset.
- [x] Unit test: setelah `saveTodayLog()`, `subject.dailyLogs` memiliki key hari ini dengan jumlah entry yang benar.
- [x] Unit test: memanggil `saveTodayLog()` dua kali di hari yang sama menghasilkan satu entry (overwrite, bukan duplikasi).
- [x] Unit test: setelah `resetForNewDay()`, semua item memiliki `progress == 'belum'` dan `currentValue == 0`, termasuk item bertingkat.
- [x] Unit test: setelah `resetForNewDay()`, `dailyLogs` tidak berubah dari kondisi sebelumnya.

---

## Catatan implementasi

**Tanggal & Waktu:** 23 November 2026, 22:58:00+08:00

### Ringkasan
Operasi controller inti untuk fitur DailyTracker telah diimplementasikan di `ChecklistDetailController`:
1. **`saveTodayLog(DailySubject subject)`**:
   - Menghasilkan key tanggal hari ini berformat `yyyy-MM-dd` (`DateTime.now()`).
   - Melakukan mapping deep snapshot seluruh tree `subject.subMateri` ke `List<DailyLogEntry>` menggunakan `DailyLogEntry.fromSubSubjectItem`.
   - Menyimpan snapshot ke `subject.dailyLogs[todayKey]`. Jika key sudah ada di hari yang sama, entri lama langsung di-overwrite (tidak duplikasi/merge).
   - Memanggil `saveGroupData()` untuk persistensi data (termasuk enkripsi otomatis bila group dienkripsi).

2. **`resetForNewDay(DailySubject subject)`**:
   - Menampilkan `AlertDialog` konfirmasi: "Reset Hari Baru?" sebelum aksi dijalankan. Jika dibatalkan (`Batal` atau dialog ditutup), method mengembalikan `false` tanpa melakukan mutasi apa pun.
   - Jika dikonfirmasi (`Ya, Reset`), fungsi `resetRecursive` dijalankan untuk mereset seluruh `SubSubjectItem` di seluruh kedalaman tree menjadi `progress = 'belum'` dan `currentValue = 0`.
   - `dailyLogs` tidak dimutasi sama sekali (riwayat aman).
   - Memanggil `saveGroupData()` dan mengembalikan `true`.

3. **Pengujian**:
   - Ditambahkan unit & widget test di `test/features/checklist/presentation/checklist_detail_controller_ticket_02_test.dart`.
   - Menguji persistensi key hari ini & snapshot yang terbentuk.
   - Menguji perilaku overwrite ketika `saveTodayLog()` dipanggil dua kali di hari yang sama.
   - Menguji pembatalan dialog reset tidak mengubah data.
   - Menguji konfirmasi reset mengembalikan semua item bertingkat ke `'belum'` dan `0` serta memastikan `dailyLogs` tidak berubah.
   - Seluruh pengujian (4 test) lulus. Seluruh test fitur checklist (9 test) lulus.
