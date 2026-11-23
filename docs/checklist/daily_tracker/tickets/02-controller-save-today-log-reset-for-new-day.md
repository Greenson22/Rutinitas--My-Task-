# 02: Controller — saveTodayLog & resetForNewDay

**What to build:** `ChecklistDetailController` mendapat dua method baru untuk operasi inti DailyTracker. `saveTodayLog()` membuat snapshot seluruh item di `DailySubject` secara rekursif dan menyimpannya ke `dailyLogs` dengan key tanggal hari ini (`yyyy-MM-dd`); jika key sudah ada (pengguna simpan dua kali di hari yang sama), entry lama di-overwrite. `resetForNewDay()` mereset progress seluruh `SubSubjectItem` secara rekursif ke `belum` dan `currentValue` ke `0`, diawali dialog konfirmasi — tanpa menyentuh `dailyLogs` yang sudah tersimpan. Kedua method memanggil `saveGroupData()` yang sudah ada setelah operasi selesai.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `saveTodayLog(DailySubject subject)` membuat `List<DailyLogEntry>` dari seluruh `subMateri` secara rekursif menggunakan `DailyLogEntry.fromSubSubjectItem()`.
- [ ] `saveTodayLog()` menyimpan hasil snapshot ke `subject.dailyLogs[tanggalHariIni]` (format `yyyy-MM-dd`), menimpa entry lama jika sudah ada.
- [ ] `saveTodayLog()` memanggil `saveGroupData()` setelah update.
- [ ] `resetForNewDay(DailySubject subject)` menampilkan dialog konfirmasi sebelum melakukan reset.
- [ ] `resetForNewDay()` mereset `progress` ke `'belum'` dan `currentValue` ke `0` pada seluruh `SubSubjectItem` secara rekursif (termasuk semua level anak).
- [ ] `resetForNewDay()` tidak mengubah `dailyLogs` sama sekali.
- [ ] `resetForNewDay()` memanggil `saveGroupData()` setelah reset.
- [ ] Unit test: setelah `saveTodayLog()`, `subject.dailyLogs` memiliki key hari ini dengan jumlah entry yang benar.
- [ ] Unit test: memanggil `saveTodayLog()` dua kali di hari yang sama menghasilkan satu entry (overwrite, bukan duplikasi).
- [ ] Unit test: setelah `resetForNewDay()`, semua item memiliki `progress == 'belum'` dan `currentValue == 0`, termasuk item bertingkat.
- [ ] Unit test: setelah `resetForNewDay()`, `dailyLogs` tidak berubah dari kondisi sebelumnya.
