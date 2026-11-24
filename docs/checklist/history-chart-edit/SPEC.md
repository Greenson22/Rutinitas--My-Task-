# SPEC — History Chart & Edit pada DailyTracker History Screen

| Field | Value |
|---|---|
| Fitur | `history_chart_edit` |
| Sumber | `docs/checklist/history-chart-edit/PRD.md` |
| Status | Ready for Agent |
| Tanggal | 24 November 2026 |
| Platform Utama | Android |
| Platform Pendukung | Linux desktop |

---

## Problem Statement

`DailyTrackerHistoryScreen` hanya menampilkan daftar tanggal secara linear tanpa visualisasi tren, selalu menampilkan semua history tanpa filter, dan tidak memiliki cara untuk mengoreksi data satu hari yang salah (edit/hapus per entry). Pengguna tidak bisa menilai konsistensi kebiasaan secara cepat dan tidak bisa memperbaiki data yang keliru tanpa menghapus seluruh bulan.

---

## Solution

Tambahkan ke `DailyTrackerHistoryScreen`:
1. **Bar chart** (menggunakan `fl_chart`) di atas list, menampilkan persentase selesai per hari dengan tooltip interaktif.
2. **Filter rentang** (chip preset + date range picker) yang mensinkronkan tampilan grafik dan list.
3. **Edit & hapus per entry** via long-press pada card tanggal, dengan bottom sheet editable untuk status item dan nilai progress/countdown, serta dialog konfirmasi untuk hapus.

---

## User Stories

### Grafik & Filter

31. Sebagai pengguna, saya ingin melihat bar chart progress harian di atas daftar history, agar saya bisa menilai tren konsistensi secara visual.
32. Sebagai pengguna, saya ingin grafik secara default menampilkan data bulan kalender berjalan (Bulan Ini), agar saya langsung melihat performa bulan ini saat membuka screen.
33. Sebagai pengguna, saya ingin memilih filter preset (Bulan Ini / 7 Hari / 30 Hari) untuk mengubah rentang data yang ditampilkan di grafik dan list, agar saya bisa fokus ke periode tertentu dengan cepat.
34. Sebagai pengguna, saya ingin memilih "Custom Range" untuk menentukan tanggal mulai dan akhir sendiri via date range picker, agar saya bisa menganalisis rentang tertentu yang saya inginkan.
35. Sebagai pengguna, saya ingin mengetuk batang grafik untuk melihat tooltip berisi tanggal, persentase selesai, dan jumlah item (mis: "15 Nov — 80% (8/10)"), agar saya bisa membaca detail hari tertentu langsung dari grafik.
36. Sebagai pengguna, saya ingin grafik dan list history selalu sinkron dengan filter yang dipilih, agar tidak ada inkonsistensi tampilan.

### Edit & Hapus Per Entry

37. Sebagai pengguna, saya ingin melakukan long-press pada card tanggal di list untuk memunculkan menu konteks dengan opsi "Edit" dan "Hapus", agar saya bisa mengakses aksi per entry dengan gestur yang natural.
38. Sebagai pengguna, saya ingin mengedit status item (belum / sementara / selesai) pada satu entry history melalui bottom sheet editable, agar saya bisa mengoreksi status yang salah diisi.
39. Sebagai pengguna, saya ingin mengedit nilai `currentValue` untuk item bertipe `progress` atau `countdown` pada satu entry history, agar nilai progress yang salah bisa diperbaiki.
40. Sebagai pengguna, saya ingin perubahan dari edit entry tersimpan persisten ke `dailyLogs`, agar koreksi data tidak hilang setelah aplikasi ditutup.
41. Sebagai pengguna, saya ingin ringkasan (jumlah selesai/total) pada card tanggal di list diperbarui setelah edit disimpan, agar feedback-nya langsung terlihat.
42. Sebagai pengguna, saya ingin menghapus satu entry history (satu hari tertentu) dengan konfirmasi dialog, agar saya tidak kehilangan data karena salah aksi.
43. Sebagai pengguna, saya ingin setelah hapus satu entry, card tanggal tersebut langsung menghilang dari list dan grafik diperbarui, agar feedback-nya instan.
44. Sebagai pengguna, saya ingin aksi edit dan hapus per entry disimpan persisten via callback (`onEditEntry` & `onDeleteEntry`) ke parent, agar arsitektur tetap konsisten dengan pola yang sudah ada (onDeleteAll, onDeleteByMonth).

---

## Architecture

### File yang Dimodifikasi

| File | Perubahan |
|---|---|
| `pubspec.yaml` | Tambah `fl_chart: ^0.69.0` (atau versi terbaru stabil) |
| `lib/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart` | Refactor major: tambah state filter, bar chart, long-press menu, bottom sheet edit |
| `lib/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart` | Teruskan `onEditEntry` & `onDeleteEntry` ke `DailyTrackerHistoryScreen` |
| `lib/features/checklist/presentation/checklist_detail_screen/controllers/checklist_detail_controller.dart` | Tambah method `editDailyLogEntry(subject, dateKey, updatedEntries)` & `deleteDailyLogEntry(subject, dateKey)` |

### File Baru

| File | Isi |
|---|---|
| `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/history_bar_chart.dart` | Widget `HistoryBarChart` yang wraps `BarChart` dari `fl_chart` |
| `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/history_filter_chips.dart` | Widget `HistoryFilterChips` untuk chip preset dan trigger date range picker |
| `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/edit_history_entry_sheet.dart` | Bottom sheet editable untuk edit status & nilai progress per item |

### State Baru di `_DailyTrackerHistoryScreenState`

```dart
// Filter state
_FilterPreset _selectedPreset = _FilterPreset.thisMonth; // enum
DateTimeRange? _customRange;

// Computed dari filter
List<String> get _filteredKeys { ... } // keys dari dailyLogs yang masuk rentang filter
```

---

## Detailed Design

### `HistoryBarChart`

```dart
class HistoryBarChart extends StatelessWidget {
  final List<String> dateKeys;         // sorted ascending, format 'yyyy-MM-dd'
  final Map<String, List<DailyLogEntry>> dailyLogs;
  final int Function(List<DailyLogEntry>) countTotal;
  final int Function(List<DailyLogEntry>) countFinished;

  // ... BarChart dari fl_chart
  // X-axis: index bar, label = 'd MMM' atau hanya hari jika banyak
  // Y-axis: 0–100%
  // touchCallback: tampilkan BarTouchTooltipData
}
```

**Tooltip format:** `"{dd MMM}\n{persen}%\n({finished}/{total})"`

**Warna batang:**
- 100% → `Colors.teal`
- 50–99% → `Colors.teal.shade300`
- 1–49% → `Colors.amber`
- 0% / tidak ada data → `Colors.grey.shade300`

### `HistoryFilterChips`

```dart
enum _FilterPreset { thisMonth, last7Days, last30Days, custom }

class HistoryFilterChips extends StatelessWidget {
  final _FilterPreset selected;
  final DateTimeRange? customRange;
  final void Function(_FilterPreset preset) onPresetChanged;
  final void Function(DateTimeRange range) onCustomRangeChanged;
}
```

**Label custom range:** "10 Nov – 20 Nov" (atau "10 – 20 Nov" jika bulan sama).

### `EditHistoryEntrySheet`

```dart
class EditHistoryEntrySheet extends StatefulWidget {
  final String dateKey;
  final List<DailyLogEntry> entries; // snapshot yang akan diedit
  final Future<void> Function(List<DailyLogEntry> updated) onSave;
}
```

**Logika edit:**
- Buat deep copy dari `entries` (karena `DailyLogEntry` immutable → buat `MutableDailyLogEntry` atau `DailyLogEntry.copyWith`).
- Tampilkan item secara rekursif; untuk setiap item:
  - Label nama item (non-editable).
  - `SegmentedButton` / 3 chip: Belum / Sementara / Selesai.
  - Jika `itemType == 'progress'` atau `'countdown'`: `TextField` untuk `currentValue` (integer, `TextInputType.number`).
  - Children indent 16dp dan tampil di bawah parent-nya.
- Tombol "Simpan" → rebuild `DailyLogEntry` list → panggil `onSave`.
- Tombol "Batal" → `Navigator.pop`.

### Method Controller Baru

```dart
// di ChecklistDetailController

Future<void> editDailyLogEntry(
  DailySubject subject,
  String dateKey,
  List<DailyLogEntry> updatedEntries,
) async {
  subject.dailyLogs[dateKey] = updatedEntries;
  await saveChecklist();
  setState(() {});
}

Future<void> deleteDailyLogEntry(
  DailySubject subject,
  String dateKey,
) async {
  subject.dailyLogs.remove(dateKey);
  await saveChecklist();
  setState(() {});
}
```

### Navigasi ke History Screen (Updated)

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => DailyTrackerHistoryScreen(
      subject: subject,
      onDeleteAll: () => controller.deleteDailyLog(subject),
      onDeleteByMonth: (m) => controller.deleteDailyLogsByMonth(subject, m),
      onEditEntry: (dateKey, updated) => controller.editDailyLogEntry(subject, dateKey, updated),
      onDeleteEntry: (dateKey) => controller.deleteDailyLogEntry(subject, dateKey),
    ),
  ),
).then((_) => setState(() {}));
```

---

## `DailyLogEntry` — Handling Immutability

`DailyLogEntry` saat ini menggunakan `const` constructor. Untuk mendukung edit, tambahkan `copyWith`:

```dart
DailyLogEntry copyWith({
  String? itemName,
  String? progress,
  String? itemType,
  int? currentValue,
  int? targetValue,
  List<DailyLogEntry>? children,
}) {
  return DailyLogEntry(
    itemName: itemName ?? this.itemName,
    progress: progress ?? this.progress,
    itemType: itemType ?? this.itemType,
    currentValue: currentValue ?? this.currentValue,
    targetValue: targetValue ?? this.targetValue,
    children: children ?? this.children,
  );
}
```

---

## pubspec.yaml Change

```yaml
dependencies:
  # ... existing ...
  fl_chart: ^0.69.0  # Bar chart untuk DailyTracker History
```

Jalankan: `flutter pub get`

---

## Test Plan

### Widget Tests Baru

| File | Test Cases |
|---|---|
| `test/features/checklist/presentation/daily_tracker_history_screen_test.dart` | Tambah test baru (tidak hapus yang sudah ada) |

**Test cases tambahan:**

- **Chart render:** `HistoryBarChart` merender tanpa error dengan data 5 hari.
- **Filter bulan ini:** Saat screen dibuka, hanya entry bulan berjalan yang tampil di list.
- **Filter 7 hari:** Setelah pilih "7 Hari", hanya 7 entry terakhir yang tampil.
- **Filter custom:** Setelah set custom range, hanya entry dalam range yang tampil.
- **Grafik + list sync:** Setelah ubah filter, jumlah bar di grafik = jumlah card di list.
- **Long-press → menu:** Long-press pada card tanggal menampilkan menu "Edit" dan "Hapus".
- **Edit entry:** Setelah edit dan simpan, ringkasan card diperbarui & `onEditEntry` dipanggil.
- **Hapus entry:** Setelah konfirmasi hapus, card tanggal hilang & `onDeleteEntry` dipanggil.
- **Konfirmasi hapus:** Jika dialog konfirmasi dibatalkan, entry tidak terhapus.

---

## Acceptance Criteria

- [ ] `fl_chart` berhasil ditambahkan dan `flutter pub get` sukses.
- [ ] Bar chart tampil di atas list dengan batang per hari, sumbu Y 0–100%.
- [ ] Default filter = Bulan Ini; saat screen dibuka, hanya entry bulan berjalan tampil.
- [ ] Chip Bulan Ini / 7 Hari / 30 Hari mengubah grafik dan list secara sinkron.
- [ ] Custom Range membuka date range picker; setelah dipilih, grafik dan list diperbarui.
- [ ] Tap batang grafik menampilkan tooltip dengan format yang benar.
- [ ] Long-press card tanggal menampilkan menu dengan opsi "Edit" dan "Hapus".
- [ ] Bottom sheet edit menampilkan semua item (rekursif) dengan toggle status.
- [ ] Item tipe `progress`/`countdown` memiliki field input nilai pada bottom sheet edit.
- [ ] Simpan di bottom sheet edit memanggil `onEditEntry` dan memperbarui ringkasan card.
- [ ] Hapus per entry menampilkan dialog konfirmasi; konfirmasi memanggil `onDeleteEntry`.
- [ ] Setelah hapus entry, card tersebut hilang dari list dan batang grafik pada hari itu hilang/diperbarui.
- [ ] `DailyLogEntry.copyWith` tersedia dan berfungsi.
- [ ] Controller memiliki method `editDailyLogEntry` dan `deleteDailyLogEntry`.
- [ ] Semua widget test baru lulus.
- [ ] Tidak ada regresi: seluruh test suite lama tetap lulus 100%.
