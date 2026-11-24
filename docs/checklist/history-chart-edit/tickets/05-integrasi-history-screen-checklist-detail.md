# 05: Integrasi — Refactor `DailyTrackerHistoryScreen` & Update `ChecklistDetailScreen`

**What to build:** Integrasikan semua komponen baru ke dalam `DailyTrackerHistoryScreen` dan perbarui `ChecklistDetailScreen` untuk meneruskan callback baru.

### A. Refactor `DailyTrackerHistoryScreen`

File: `lib/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart`

**Signature baru widget:**
```dart
class DailyTrackerHistoryScreen extends StatefulWidget {
  final DailySubject subject;
  final Future<void> Function()? onDeleteAll;
  final Future<void> Function(String yearMonth)? onDeleteByMonth;
  // BARU:
  final Future<void> Function(String dateKey, List<DailyLogEntry> updated)? onEditEntry;
  final Future<void> Function(String dateKey)? onDeleteEntry;
}
```

**State baru:**
```dart
_FilterPreset _selectedPreset = _FilterPreset.thisMonth;
DateTimeRange? _customRange;
```

**Computed getter `_filteredKeys`:**
- Ambil semua key dari `subject.dailyLogs`.
- Filter berdasarkan `_selectedPreset` / `_customRange`:
  - `thisMonth`: key yang bulan & tahunnya = bulan & tahun `DateTime.now()`.
  - `last7Days`: key dalam 7 hari terakhir dari hari ini.
  - `last30Days`: key dalam 30 hari terakhir.
  - `custom`: key dalam `_customRange`.
- Sort ascending untuk grafik, sort descending untuk list.

**Layout baru (CustomScrollView):**
```
SliverToBoxAdapter:
  HistoryFilterChips(...)   // widget dari tiket 03
  SizedBox(height: 8)
  HistoryBarChart(...)      // widget dari tiket 03; data dari _filteredKeys (ascending)
  SizedBox(height: 8)

SliverList:
  // List card tanggal dari _filteredKeys (descending)
  // Setiap card: GestureDetector(onLongPress: _showEntryContextMenu)
```

**Long-press handler `_showEntryContextMenu(String dateKey)`:**
```dart
void _showEntryContextMenu(String dateKey, List<DailyLogEntry> entries) {
  showModalBottomSheet(
    // Simple list dengan 2 item:
    // - ListTile(leading: Icon(edit), title: 'Edit', onTap: → _openEditSheet)
    // - ListTile(leading: Icon(delete, color: red), title: 'Hapus', onTap: → _handleDeleteEntry)
  );
}
```

**Edit handler `_openEditSheet(dateKey, entries)`:**
- Buka `EditHistoryEntrySheet` (dari tiket 04).
- `onSave`: panggil `widget.onEditEntry` → `setState(() {})`.

**Hapus entry handler `_handleDeleteEntry(dateKey)`:**
- Dialog konfirmasi AlertDialog.
- Jika konfirmasi: panggil `widget.onDeleteEntry` → `setState(() {})`.

### B. Update `ChecklistDetailScreen`

File: `lib/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart`

Saat navigasi ke `DailyTrackerHistoryScreen`, tambahkan:
```dart
onEditEntry: (dateKey, updated) async {
  await controller.editDailyLogEntry(subject, dateKey, updated);
},
onDeleteEntry: (dateKey) async {
  await controller.deleteDailyLogEntry(subject, dateKey);
},
```

**Blocked by:** 02, 03, 04

**Status:** done

- [x] `DailyTrackerHistoryScreen` menerima `onEditEntry` & `onDeleteEntry` sebagai parameter opsional (nullable).
- [x] Saat screen dibuka, filter default = "Bulan Ini"; grafik dan list hanya menampilkan entry bulan berjalan.
- [x] `HistoryFilterChips` tampil dan perubahan filter memperbarui grafik dan list secara sinkron.
- [x] `HistoryBarChart` tampil di atas list dengan data dari `_filteredKeys` (sorted ascending).
- [x] Long-press card tanggal memunculkan menu konteks dengan "Edit" dan "Hapus".
- [x] Memilih "Edit" dari menu membuka `EditHistoryEntrySheet` dengan data entry hari itu.
- [x] Setelah simpan di sheet edit, `onEditEntry` dipanggil dan ringkasan card diperbarui.
- [x] Memilih "Hapus" dari menu menampilkan dialog konfirmasi.
- [x] Setelah konfirmasi hapus, `onDeleteEntry` dipanggil dan card tanggal itu hilang dari list.
- [x] `ChecklistDetailScreen` meneruskan `onEditEntry` & `onDeleteEntry` dengan implementasi controller yang benar.
- [x] Fungsionalitas lama (delete all, delete by month, detail snapshot read-only via tap biasa) tetap berjalan.
- [x] Widget test: saat screen dibuka dengan data 2 bulan, hanya entry bulan ini yang tampil (default filter).
- [x] Widget test: setelah pilih "30 Hari", semua entry 30 hari terakhir tampil.
- [x] Widget test: long-press card → menu tampil → pilih Edit → `EditHistoryEntrySheet` terbuka.
- [x] Widget test: long-press card → pilih Hapus → konfirmasi → `onDeleteEntry` dipanggil dengan dateKey yang benar.
- [x] Widget test: tap biasa pada card masih membuka detail snapshot read-only (tidak terpengaruh oleh long-press).
- [x] Seluruh test suite lama tetap lulus 100%; tidak ada regresi.

---

## Catatan implementasi

- Melakukan refactor pada `DailyTrackerHistoryScreen` di `lib/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart`:
  - Menambahkan callback opsional `onEditEntry` dan `onDeleteEntry`.
  - Mengintegrasikan state filter: `HistoryFilterPreset.thisMonth` (default) dan `_customRange`.
  - Menerapkan layout berbasis `CustomScrollView` yang menampilkan `HistoryFilterChips` dan `HistoryBarChart` (dengan data `_filteredKeys` terurut ascending) di bagian atas list.
  - Setiap card tanggal mendukung `onTap` (membuka snapshot read-only) dan `onLongPress` (membuka bottom sheet opsi "Edit Entry" dan "Hapus Entry").
  - Menghubungkan opsi Edit ke `EditHistoryEntrySheet` dan opsi Hapus ke dialog konfirmasi `AlertDialog` yang memanggil `onDeleteEntry`.
- Memperbarui navigasi di `lib/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart` untuk meneruskan callback `onEditEntry` dan `onDeleteEntry` ke method controller `editDailyLogEntry` dan `deleteDailyLogEntry`.
- Memperbarui dan melengkapi widget tests di `test/features/checklist/presentation/daily_tracker_history_screen_test.dart` menguji filter default bulan ini, pergantian filter ke 30 hari, interaksi long-press, sheet edit, dialog konfirmasi hapus, dan fungsi snapshot read-only saat tap normal.
- Seluruh test suite (383 test cases) lulus 100% tanpa regresi.
- Waktu selesai: 2026-11-24T09:31:00+08:00.
