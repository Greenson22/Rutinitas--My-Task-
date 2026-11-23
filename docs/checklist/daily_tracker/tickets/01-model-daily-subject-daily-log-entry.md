# 01: Model — DailySubject & DailyLogEntry

**What to build:** Fondasi data seluruh fitur DailyTracker. `DailySubject` diperluas dengan dua field baru (`isDailyTrackerEnabled` dan `dailyLogs`) dan model baru `DailyLogEntry` ditambahkan untuk merepresentasikan snapshot satu item per hari secara rekursif. Serialisasi `fromJson`/`toJson` diperbarui untuk kedua model, dengan jaminan backward compatibility — file JSON lama yang tidak memiliki field baru tetap terbaca tanpa error dan mendapat nilai default yang aman.

**Blocked by:** None (dapat mulai segera)

**Status:** ready-for-agent

- [ ] `DailySubject` memiliki field `isDailyTrackerEnabled: bool` dengan default `false`.
- [ ] `DailySubject` memiliki field `dailyLogs: Map<String, List<DailyLogEntry>>` dengan default map kosong `{}`.
- [ ] `DailySubject.fromJson()` mem-parse `isDailyTrackerEnabled` dengan fallback `false` jika key tidak ada.
- [ ] `DailySubject.fromJson()` mem-parse `dailyLogs` dengan fallback `{}` jika key tidak ada.
- [ ] `DailySubject.toJson()` menyertakan `isDailyTrackerEnabled` dan `dailyLogs`.
- [ ] Model `DailyLogEntry` memiliki field: `itemName`, `progress`, `itemType`, `currentValue`, `targetValue`, `children` (rekursif).
- [ ] `DailyLogEntry.fromSubSubjectItem(SubSubjectItem)` melakukan deep-clone snapshot secara rekursif ke seluruh tree anak.
- [ ] `DailyLogEntry.fromJson()` dan `DailyLogEntry.toJson()` bekerja dengan benar termasuk field `children`.
- [ ] Unit test: round-trip `DailySubject.toJson()` → `DailySubject.fromJson()` menghasilkan objek yang ekuivalen.
- [ ] Unit test: round-trip `DailyLogEntry.toJson()` → `DailyLogEntry.fromJson()` menghasilkan objek yang ekuivalen, termasuk children bertingkat.
- [ ] Unit test: `DailySubject.fromJson()` pada JSON lama (tanpa `isDailyTrackerEnabled` dan `dailyLogs`) tidak throw error dan menghasilkan default yang benar.
- [ ] Unit test: `DailyLogEntry.fromSubSubjectItem()` pada item bertingkat 3 level menghasilkan snapshot rekursif yang benar.
