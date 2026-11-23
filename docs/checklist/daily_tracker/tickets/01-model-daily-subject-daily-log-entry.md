# 01: Model — DailySubject & DailyLogEntry

**What to build:** Fondasi data seluruh fitur DailyTracker. `DailySubject` diperluas dengan dua field baru (`isDailyTrackerEnabled` dan `dailyLogs`) dan model baru `DailyLogEntry` ditambahkan untuk merepresentasikan snapshot satu item per hari secara rekursif. Serialisasi `fromJson`/`toJson` diperbarui untuk kedua model, dengan jaminan backward compatibility — file JSON lama yang tidak memiliki field baru tetap terbaca tanpa error dan mendapat nilai default yang aman.

**Blocked by:** None (dapat mulai segera)

**Status:** done

- [x] `DailySubject` memiliki field `isDailyTrackerEnabled: bool` dengan default `false`.
- [x] `DailySubject` memiliki field `dailyLogs: Map<String, List<DailyLogEntry>>` dengan default map kosong `{}`.
- [x] `DailySubject.fromJson()` mem-parse `isDailyTrackerEnabled` dengan fallback `false` jika key tidak ada.
- [x] `DailySubject.fromJson()` mem-parse `dailyLogs` dengan fallback `{}` jika key tidak ada.
- [x] `DailySubject.toJson()` menyertakan `isDailyTrackerEnabled` dan `dailyLogs`.
- [x] Model `DailyLogEntry` memiliki field: `itemName`, `progress`, `itemType`, `currentValue`, `targetValue`, `children` (rekursif).
- [x] `DailyLogEntry.fromSubSubjectItem(SubSubjectItem)` melakukan deep-clone snapshot secara rekursif ke seluruh tree anak.
- [x] `DailyLogEntry.fromJson()` dan `DailyLogEntry.toJson()` bekerja dengan benar termasuk field `children`.
- [x] Unit test: round-trip `DailySubject.toJson()` → `DailySubject.fromJson()` menghasilkan objek yang ekuivalen.
- [x] Unit test: round-trip `DailyLogEntry.toJson()` → `DailyLogEntry.fromJson()` menghasilkan objek yang ekuivalen, termasuk children bertingkat.
- [x] Unit test: `DailySubject.fromJson()` pada JSON lama (tanpa `isDailyTrackerEnabled` dan `dailyLogs`) tidak throw error dan menghasilkan default yang benar.
- [x] Unit test: `DailyLogEntry.fromSubSubjectItem()` pada item bertingkat 3 level menghasilkan snapshot rekursif yang benar.

---

## Catatan implementasi

**Tanggal & Waktu:** 23 November 2026, 14:55:00+08:00

### Ringkasan
Implementasi model fondasi untuk fitur DailyTracker selesai dikerjakan:
1. `DailySubject` diperluas dengan properti `isDailyTrackerEnabled: bool` (default `false`) dan `dailyLogs: Map<String, List<DailyLogEntry>>` (default `{}`).
2. Serialisasi `DailySubject.fromJson` dan `DailySubject.toJson` diperbarui untuk mendukung backward compatibility (fallback default aman saat key tidak ada) dan round-trip serialisasi `dailyLogs`.
3. Model baru `DailyLogEntry` ditambahkan ke `lib/features/checklist/data/models/daily_model.dart` dengan properti:
   - `itemName: String`
   - `progress: String`
   - `itemType: String`
   - `currentValue: int`
   - `targetValue: int`
   - `children: List<DailyLogEntry>` (snapshot rekursif)
4. Constructor `DailyLogEntry.fromSubSubjectItem(SubSubjectItem item)` meng-clone snapshot secara rekursif hingga ke level anak terdalam secara immutable/deep copy.
5. Unit test komprehensif ditambahkan di `test/features/checklist/data/models/daily_model_test.dart` menguji default values, fallback JSON lama, round-trip serialisasi bertingkat, dan snapshot 3 level tree. Seluruh test berhasil (5/5 passed).
