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

**Status:** todo

- [ ] `DailyTrackerHistoryScreen` menerima `onEditEntry` & `onDeleteEntry` sebagai parameter opsional (nullable).
- [ ] Saat screen dibuka, filter default = "Bulan Ini"; grafik dan list hanya menampilkan entry bulan berjalan.
- [ ] `HistoryFilterChips` tampil dan perubahan filter memperbarui grafik dan list secara sinkron.
- [ ] `HistoryBarChart` tampil di atas list dengan data dari `_filteredKeys` (sorted ascending).
- [ ] Long-press card tanggal memunculkan menu konteks dengan "Edit" dan "Hapus".
- [ ] Memilih "Edit" dari menu membuka `EditHistoryEntrySheet` dengan data entry hari itu.
- [ ] Setelah simpan di sheet edit, `onEditEntry` dipanggil dan ringkasan card diperbarui.
- [ ] Memilih "Hapus" dari menu menampilkan dialog konfirmasi.
- [ ] Setelah konfirmasi hapus, `onDeleteEntry` dipanggil dan card tanggal itu hilang dari list.
- [ ] `ChecklistDetailScreen` meneruskan `onEditEntry` & `onDeleteEntry` dengan implementasi controller yang benar.
- [ ] Fungsionalitas lama (delete all, delete by month, detail snapshot read-only via tap biasa) tetap berjalan.
- [ ] Widget test: saat screen dibuka dengan data 2 bulan, hanya entry bulan ini yang tampil (default filter).
- [ ] Widget test: setelah pilih "30 Hari", semua entry 30 hari terakhir tampil.
- [ ] Widget test: long-press card → menu tampil → pilih Edit → `EditHistoryEntrySheet` terbuka.
- [ ] Widget test: long-press card → pilih Hapus → konfirmasi → `onDeleteEntry` dipanggil dengan dateKey yang benar.
- [ ] Widget test: tap biasa pada card masih membuka detail snapshot read-only (tidak terpengaruh oleh long-press).
- [ ] Seluruh test suite lama tetap lulus 100%; tidak ada regresi.

---

## Catatan implementasi

_Diisi oleh agent setelah implementasi selesai._
