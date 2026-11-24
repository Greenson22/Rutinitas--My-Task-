# 04: Widget — `EditHistoryEntrySheet`

**What to build:** Widget bottom sheet editable untuk mengedit satu entry history (satu hari) di `DailyTrackerHistoryScreen`.

File: `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/edit_history_entry_sheet.dart`

### Spesifikasi

- `StatefulWidget` yang menerima:
  - `String dateKey` — tanggal yang sedang diedit (untuk judul).
  - `List<DailyLogEntry> entries` — snapshot yang akan diedit.
  - `Future<void> Function(List<DailyLogEntry> updated) onSave` — callback saat simpan.
- Dibuka via `showModalBottomSheet` dengan `DraggableScrollableSheet` (initialSize: 0.75, min: 0.5, max: 0.95).

### Layout

```
── drag handle ──
Row: [ikon edit] [Tanggal: "24 November 2026"]  [X close]
Divider
ScrollView (rekursif, indent 16dp per level):
  Setiap item:
    Row: [nama item] + [SegmentedButton: Belum | Sementara | Selesai]
    (jika progress/countdown):
      Row: [label "Nilai:"] [TextField currentValue] [label "/ {targetValue}"]
Divider
Row: [TextButton Batal] [ElevatedButton Simpan (teal)]
```

### Logika Edit Internal

- Saat sheet dibuka, buat deep copy dari `entries` menggunakan `DailyLogEntry.copyWith` (dari tiket 01) agar tidak mengubah data asli sebelum simpan.
- Gunakan `List<_EditableDailyLogEntry>` sebagai state internal (class helper sederhana dengan field mutable atau Dart `ValueNotifier`).
- Tombol "Simpan" → rebuild `List<DailyLogEntry>` dari state internal → panggil `onSave(updatedEntries)` → `Navigator.pop`.
- Tombol "Batal" → `Navigator.pop` tanpa memanggil `onSave`.

**Blocked by:** 01

**Status:** done

- [x] Bottom sheet menampilkan judul tanggal yang diformat ("24 November 2026").
- [x] Semua item (level 1 dan child-nya) tampil secara rekursif dengan indent.
- [x] Setiap item memiliki `SegmentedButton` / `ChoiceChip` untuk status (Belum / Sementara / Selesai).
- [x] Item bertipe `progress` atau `countdown` memiliki `TextField` untuk `currentValue`.
- [x] Nilai default setiap field sesuai dengan data snapshot yang diterima.
- [x] Tombol "Simpan" memanggil `onSave` dengan data terbaru dan menutup sheet.
- [x] Tombol "Batal" menutup sheet tanpa memanggil `onSave`.
- [x] Widget test: sheet merender semua item dari snapshot 3-entry.
- [x] Widget test: ubah status satu item → tap Simpan → `onSave` dipanggil dengan item yang sudah berubah.
- [x] Widget test: tap Batal → `onSave` tidak dipanggil.
- [x] Seluruh test suite lama tetap lulus 100%.

---

## Catatan implementasi

- Dibuat widget `EditHistoryEntrySheet` di `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/edit_history_entry_sheet.dart` yang mengimplementasikan bottom sheet editable berbasis `DraggableScrollableSheet`.
- Header menampilkan ikon edit, judul tanggal terformat dalam bahasa Indonesia (misalnya `24 November 2026`), dan tombol close `[X]`.
- Hirarki item dirender secara rekursif dengan indentasi 16dp per tingkat kedalaman.
- Setiap item memiliki pemilih status berbasis `SegmentedButton` (`belum`, `sementara`, `selesai`) dan input angka `TextField` khusus jika item bertipe `progress` atau `countdown`.
- Tombol `Simpan` mengumpulkan snapshot terbarui lalu memanggil callback `onSave(updatedEntries)` dan menutup sheet, sedangkan tombol `Batal` atau tombol `[X]` menutup sheet tanpa memicu `onSave`.
- Dibuat suite widget tests komprehensif di `test/features/checklist/presentation/widgets/edit_history_entry_sheet_test.dart` menguji rendering semua item, perubahan status/nilai, dan penanganan tombol batal/close.
- Analisis statis bersih dan seluruh pengujian checklist (43 test cases) lulus 100%.
- Waktu selesai: 2026-11-24T09:20:00+08:00.
