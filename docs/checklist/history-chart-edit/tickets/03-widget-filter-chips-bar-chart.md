# 03: Widget — `HistoryFilterChips` & `HistoryBarChart`

**What to build:** Dua widget baru yang akan digunakan di `DailyTrackerHistoryScreen`.

### `HistoryFilterChips`
File: `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/history_filter_chips.dart`

Widget stateless yang menampilkan 4 chip: **Bulan Ini** | **7 Hari** | **30 Hari** | **Custom Range**.
- Chip terpilih tampil dengan style "filled" (warna teal) berbeda dari yang tidak terpilih.
- Ketuk "Custom Range" memanggil `showDateRangePicker` lalu meneruskan hasil `DateTimeRange` ke callback `onCustomRangeChanged`.
- Label "Custom Range" diupdate menjadi rentang terpilih (mis: "10–20 Nov") setelah dipilih.

### `HistoryBarChart`
File: `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/history_bar_chart.dart`

Widget stateless yang membungkus `BarChart` dari `fl_chart`.
- Input: `List<String> dateKeys` (sorted ascending, 'yyyy-MM-dd'), `Map<String, List<DailyLogEntry>> dailyLogs`, fungsi `countTotal` & `countFinished`.
- Sumbu X: label hari (format 'd' atau 'd/M' jika lebih dari 14 bar), sumbu Y: 0–100%.
- Tinggi batang = `(finished / total) * 100`; jika `total == 0`, tinggi = 0.
- Warna batang: teal (100%), teal.shade300 (50–99%), amber (1–49%), grey.shade300 (0%).
- `BarTouchData` dengan `BarTouchTooltipData`: format `"{dd MMM}\n{persen}%\n({finished}/{total})"`.
- Tinggi widget: 180dp.

**Blocked by:** 01

**Status:** todo

- [ ] `HistoryFilterChips` merender 4 chip; chip yang dipilih memiliki visual berbeda.
- [ ] Ketuk chip preset → `onPresetChanged` dipanggil dengan enum yang sesuai.
- [ ] Ketuk "Custom Range" → `showDateRangePicker` terbuka (atau mock-nya dalam test).
- [ ] Setelah pilih custom range, label chip berubah ke format rentang terpilih.
- [ ] `HistoryBarChart` merender tanpa error dengan data 5 hari.
- [ ] Jumlah bar = jumlah `dateKeys` yang diberikan.
- [ ] Widget test: bar 100% mendapat warna teal; bar 0% mendapat warna grey.
- [ ] Widget test: `HistoryBarChart` merender empty state (tidak error) jika `dateKeys` kosong.
- [ ] Seluruh test suite lama tetap lulus 100%.

---

## Catatan implementasi

_Diisi oleh agent setelah implementasi selesai._
