# SPEC — Checklist UX Enhancement
**Label:** `ready-for-agent`  
**Versi:** 1.0  
**Tanggal:** 2026-11-25  
**Referensi PRD:** [PRD.md](./PRD.md)

---

## Problem Statement

Pengguna aplikasi Checklist menghadapi tiga hambatan UX yang mengurangi produktivitas:

1. **Pemilihan warna Card Checklist tidak intuitif.** Dialog ubah warna hanya menyediakan grid palet statis dan kolom input kode HEX mentah. Pengguna tidak bisa menjelajahi spektrum warna secara visual. Selain itu, warna teks kadang tidak terbaca karena kontras yang buruk dengan warna latar yang dipilih.

2. **Bar History DailyTracker hanya satu warna per bar.** Grafik batang di halaman riwayat menampilkan satu warna solid per bar (oranye/teal/abu berdasarkan persentase). Informasi "item mana yang berhasil diselesaikan hari itu" tidak terlihat secara visual — semua bar terasa seragam dan tidak informatif.

3. **Edit History tidak menunjukkan tipe item secara jelas.** Saat pengguna membuka sheet edit riwayat untuk memperbaiki data historis, mereka tidak mendapat indikasi visual apakah item bertipe `normal`, `progress`, atau `countdown`. Hal ini menyebabkan kebingungan saat harus memasukkan nilai numerik yang konteksnya tidak jelas.

---

## Solution

### F1 — Color Wheel Interaktif pada Dialog Ubah Warna

Tambahkan color wheel interaktif di dalam dialog `ChangeColorDialog`. Color wheel dan input HEX tetap berdampingan dan sinkron dua arah: menggeser wheel memperbarui HEX, mengetik HEX memindahkan posisi wheel. Warna teks dihitung otomatis dari kecerahan warna background (brightness detection) — tidak ada kontrol manual untuk warna teks.

### F2 — Bar History Stacked dengan Warna per Item

Ubah `HistoryBarChart` dari bar satu warna menjadi **stacked bar**: setiap segmen mewakili satu item yang berstatus `selesai` pada hari tersebut. Warna tiap item diturunkan secara deterministik dari nama item menggunakan algoritma djb2 hash → HSL color, sehingga warna konsisten antar hari tanpa perlu disimpan ke storage.

### F3 — Badge Tipe Item di Edit History Sheet

Tambahkan badge/chip tipe item di bawah nama setiap item dalam `EditHistoryEntrySheet`. Badge menampilkan ikon dan label tipe: 📊 Progress atau ⏳ Hitung Mundur. Label input nilai numerik diperjelaskan menjadi "Nilai saat ini:" (progress) dan "Sisa:" (countdown). Badge dan label berlaku rekursif untuk semua level hierarki item.

---

## User Stories

### Fitur 1 — Color Wheel

1. Sebagai pengguna Checklist, saya ingin membuka dialog ubah warna dan melihat color wheel yang interaktif, agar saya bisa memilih warna secara visual tanpa harus hafal kode HEX.
2. Sebagai pengguna Checklist, saya ingin menyeret titik pada color wheel untuk mengubah hue dan saturation secara real-time, agar saya melihat pratinjau card berubah langsung saat saya menjelajah warna.
3. Sebagai pengguna Checklist, saya ingin input HEX tetap tersedia di bawah color wheel, agar saya bisa memasukkan warna presisi dari sumber luar (desainer, branding).
4. Sebagai pengguna Checklist, saya ingin memilih warna di color wheel dan nilai HEX langsung terupdate secara sinkron, agar kedua kontrol selalu menampilkan warna yang sama.
5. Sebagai pengguna Checklist, saya ingin mengetikkan kode HEX yang valid dan color wheel otomatis pindah ke posisi warna tersebut, agar saya tidak perlu mengoperasikan keduanya secara terpisah.
6. Sebagai pengguna Checklist, saya ingin warna teks (hitam/putih) dipilihkan otomatis berdasarkan kecerahan warna background yang saya pilih, agar teks di card selalu terbaca tanpa saya perlu memikul keputusan itu.
7. Sebagai pengguna Checklist, saya ingin melihat pratinjau (live preview) card dengan warna background dan teks sebelum menyimpan, agar saya tidak terkejut dengan hasil akhirnya.
8. Sebagai pengguna Checklist, saya ingin palet warna kuratif statis tetap tersedia sebagai shortcut di bagian bawah dialog, agar saya bisa memilih warna cepat tanpa berinteraksi dengan wheel.
9. Sebagai pengguna Checklist, saya ingin memilih warna dari palet kuratif dan color wheel serta HEX input ikut bergerak ke warna tersebut, agar semua kontrol tetap sinkron.
10. Sebagai pengguna Checklist, saya ingin menekan "Simpan Warna" dan perubahan warna langsung terefleksi di card checklist, agar feedback terasa instan.
11. Sebagai pengguna Checklist, saya ingin menekan "Batal" dan warna card kembali ke warna semula tanpa berubah, agar saya bisa mengeksplorasi warna tanpa risiko.

### Fitur 2 — Bar History Multi-Warna

12. Sebagai pengguna DailyTracker, saya ingin melihat bar riwayat yang tersusun dari segmen berwarna, agar saya langsung tahu item mana yang berhasil diselesaikan pada hari tertentu.
13. Sebagai pengguna DailyTracker, saya ingin setiap item selalu memiliki warna yang konsisten antar hari (tidak berubah-ubah), agar saya bisa mengenali pola penyelesaian item tertentu secara visual.
14. Sebagai pengguna DailyTracker, saya ingin warna item diturunkan otomatis dari nama item tanpa konfigurasi tambahan, agar tidak ada langkah ekstra yang harus saya lakukan.
15. Sebagai pengguna DailyTracker, saya ingin warna-warna yang dihasilkan mudah dibedakan satu sama lain, agar saya bisa membaca komposisi segmen bar dengan jelas.
16. Sebagai pengguna DailyTracker, saya ingin bar pada hari dengan 0% penyelesaian tetap tampil (sebagai batang tipis abu-abu), agar saya bisa melihat bahwa hari itu memang tidak ada progress.
17. Sebagai pengguna DailyTracker, saya ingin tooltip saat menyentuh bar tetap menampilkan tanggal, persentase, dan detail selesai/total, agar informasi kuantitatif tidak hilang.
18. Sebagai pengguna DailyTracker, saya ingin bar yang 100% selesai menampilkan seluruh segmen item yang selesai memenuhi tinggi penuh, agar saya merasa puas melihat hari yang produktif.
19. Sebagai pengguna DailyTracker, saya ingin bar yang sebagian selesai menampilkan segmen berwarna di bagian bawah dan sisa abu-abu di bagian atas, agar saya bisa mengukur seberapa jauh saya sudah sampai.

### Fitur 3 — Edit History Sadar Tipe

20. Sebagai pengguna DailyTracker, saya ingin melihat badge tipe di sebelah nama item saat membuka Edit History, agar saya langsung tahu apakah item itu progress, hitung mundur, atau normal.
21. Sebagai pengguna DailyTracker, saya ingin badge item `progress` menampilkan ikon 📊 dan label "Progress" dengan warna biru muda, agar tipenya mudah dikenali sekilas.
22. Sebagai pengguna DailyTracker, saya ingin badge item `countdown` menampilkan ikon ⏳ dan label "Hitung Mundur" dengan warna oranye, agar tipenya mudah dikenali sekilas.
23. Sebagai pengguna DailyTracker, saya ingin item `progress` menampilkan label "Nilai saat ini:" di depan field input, agar saya tahu saya sedang mengedit nilai yang menuju target.
24. Sebagai pengguna DailyTracker, saya ingin item `countdown` menampilkan label "Sisa:" di depan field input, agar saya tahu saya sedang mengedit sisa hitung mundur.
25. Sebagai pengguna DailyTracker, saya ingin kedua tipe — progress dan countdown — tetap memperbolehkan saya mengubah nilai numerik secara bebas, agar saya bisa mengkoreksi data historis yang salah.
26. Sebagai pengguna DailyTracker, saya ingin status selector (Belum/Sementara/Selesai) tetap bisa diubah manual untuk semua tipe item, agar saya bisa mengkoreksi status yang tidak sesuai.
27. Sebagai pengguna DailyTracker, saya ingin sub-item (children) juga menampilkan badge tipe yang sesuai, agar tidak ada ambiguitas di level hierarki manapun.
28. Sebagai pengguna DailyTracker, saya ingin badge tidak muncul untuk item bertipe `normal` yang tidak memiliki input nilai, agar tampilan tidak terkesan penuh informasi yang tidak relevan.

---

## Implementation Decisions

### F1 — Color Wheel

- **Library:** Tambahkan dependency `flutter_colorpicker` ke `pubspec.yaml`. Library ini menyediakan widget `ColorPicker` dengan mode HSL/HSV wheel yang sesuai kebutuhan. Jika project sudah memiliki library serupa, gunakan yang sudah ada.

- **Modul yang dimodifikasi:** Hanya `ChangeColorDialog`. Tidak ada perubahan pada model data (`DailySubject`), karena `backgroundColor` dan `textColor` tetap disimpan sebagai `int`.

- **Layout dialog (urutan dari atas ke bawah):**
  1. Live Preview (tidak berubah)
  2. Color Wheel (tambahan baru)
  3. Input HEX (tetap, sinkron dua arah)
  4. Palet kuratif statis (tetap)

- **Sinkronisasi dua arah:**
  - Wheel digeser → update state `_selectedBgColor` → `_hexInputController.text` diperbarui.
  - HEX diketik (valid 6 karakter) → update state `_selectedBgColor` → wheel ikut berpindah ke posisi warna baru.
  - Palet dipilih → update `_selectedBgColor` → wheel dan HEX keduanya ikut.

- **Auto text color:** Fungsi `ThemeData.estimateBrightnessForColor` tetap digunakan. Dropdown manual "Gelap/Putih" **dihapus** dari UI.

- **Tidak ada perubahan pada API/contract `ChangeColorDialog`:** Callback `onColorSaved` dan parameter `subject` tidak berubah.

---

### F2 — Bar History Stacked

- **Modul yang dimodifikasi:** `HistoryBarChart`.

- **Perubahan signature widget:** Tambahkan parameter `List<DailyLogEntry> allEntries` (atau `List<String> allItemNames`) untuk menyediakan data nama item guna menghitung mapping nama → warna. Semua caller (`DailyTrackerHistoryScreen`) harus diperbarui.

- **Algoritma warna deterministik (dari prototype):**

  ```dart
  // djb2 hash → HSL → Color
  // saturation = 0.6, lightness = 0.55 (tetap untuk semua item)
  Color colorFromItemName(String name) {
    int hash = 5381;
    for (final c in name.codeUnits) {
      hash = ((hash << 5) + hash) + c;
      hash &= 0xFFFFFFFF;
    }
    final double hue = (hash % 360).toDouble().abs();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.55).toColor();
  }
  ```
  Fungsi ini bersifat murni (pure function) dan deterministik — nama yang sama selalu menghasilkan warna yang sama.

- **Struktur bar stacked:** Setiap `BarChartGroupData` memiliki satu `BarChartRodData` dengan `rodStackItems`. Tiap `BarChartRodStackItem` merepresentasikan satu item berstatus `selesai`. Bobot tiap item: **1 unit flat** (bukan proporsional ke `targetValue`), sehingga tiap item berkontribusi sama rata terhadap tinggi bar.

- **Bar 0%:** Tampilkan batang abu-abu minimal (`toY: 5`, warna `Colors.grey.shade200`) agar bar tetap terlihat pada hari tanpa penyelesaian.

- **Y-axis:** Tetap 0–100 (persentase). Tinggi total stack = persentase penyelesaian hari itu.

- **Tooltip:** Tidak berubah — tetap menampilkan tanggal, persentase, dan `selesai/total`.

- **Legend item:** Di luar scope versi 1 ini. Tidak ada panel legenda nama item → warna.

---

### F3 — Edit History Badge Tipe

- **Modul yang dimodifikasi:** `EditHistoryEntrySheet` (dan internal class `_EditableEntry`).

- **Badge tipe:** Widget `Container` dengan `BorderRadius`, ikon (Icon), dan teks kecil. Ditempatkan sebagai baris kedua di bawah nama item (bukan inline), sehingga tidak menyempitkan ruang status selector.

- **Spesifikasi badge:**
  - `itemType == 'progress'` → ikon `Icons.trending_up`, label `"Progress"`, warna biru muda (`Colors.blue.shade100`, teks `Colors.blue.shade800`)
  - `itemType == 'countdown'` → ikon `Icons.timer_outlined`, label `"Hitung Mundur"`, warna oranye (`Colors.orange.shade100`, teks `Colors.orange.shade800`)
  - `itemType == 'normal'` → badge **tidak ditampilkan**

- **Label input nilai:**
  - `progress` → `"Nilai saat ini:"` (sebelumnya `"Nilai:"`)
  - `countdown` → `"Sisa:"` (tidak berubah)

- **Tidak ada perubahan pada logika save/serialisasi:** `_EditableEntry.toDailyLogEntry()` dan `onSave` callback tidak berubah.

- **Hierarki rekursif:** Fungsi `_buildEntryItem` yang sudah bersifat rekursif otomatis menerapkan badge ke semua level kedalaman.

---

## Testing Decisions

### Prinsip pengujian yang baik

Test hanya memverifikasi **perilaku eksternal yang dapat diamati** (widget yang tampil, callback yang dipanggil, state yang berubah) — bukan detail implementasi internal seperti nama method private, struktur `rodStackItems` secara langsung, atau internal state widget.

### Seam & file test

Semua test menggunakan `flutter_test` dengan `testWidgets` (widget test) sebagai seam utama, mengikuti pola yang sudah ada di project.

#### F1 — `ChangeColorDialog` widget test
**File baru:** `test/features/checklist/presentation/widgets/change_color_dialog_test.dart`

- Verifikasi color wheel widget tampil di dalam dialog.
- Verifikasi HEX input masih ada dan tersinkron: saat nilai HEX diketik, preview card berubah warna.
- Verifikasi dropdown "Warna Teks" (Gelap/Putih) **tidak ada** di UI.
- Verifikasi menekan "Simpan Warna" → `onColorSaved` dipanggil dan `subject.backgroundColor` berubah ke nilai yang sesuai.
- Verifikasi menekan "Batal" → `subject.backgroundColor` tidak berubah.
- Verifikasi memilih warna dari palet → preview berubah.

#### F2 — Ekstensi `history_filter_chips_and_bar_chart_test.dart` + unit test murni

**Unit test (murni, tanpa widget):** Tambahkan `group('colorFromItemName')` di file yang sama atau file test utilitas baru.
- Verifikasi nama yang sama selalu menghasilkan warna yang sama (determinisme).
- Verifikasi dua nama berbeda menghasilkan warna berbeda (tidak semua sama).
- Verifikasi output selalu dalam rentang hue 0–360 (tidak crash untuk nama kosong atau nama Unicode).

**Widget test (ekstensi file yang ada):**
- Verifikasi `BarChart` yang dirender menggunakan `rodStackItems` (ada lebih dari satu stack item saat ada beberapa item selesai).
- Verifikasi bar dengan 0 item selesai tetap tampil (toY minimal > 0).
- Verifikasi jumlah segmen dalam satu bar = jumlah item dengan `progress == 'selesai'`.

#### F3 — Ekstensi `edit_history_entry_sheet_test.dart`

- Verifikasi badge "Progress" (📊) tampil untuk item bertipe `progress`.
- Verifikasi badge "Hitung Mundur" (⏳) tampil untuk item bertipe `countdown`.
- Verifikasi badge **tidak tampil** untuk item bertipe `normal`.
- Verifikasi label `"Nilai saat ini:"` tampil untuk item `progress`.
- Verifikasi label `"Sisa:"` tampil untuk item `countdown` (periksa tidak ada regresi dari label lama).
- Verifikasi badge tampil juga untuk sub-item (child) yang memiliki tipe `progress` atau `countdown`.
- Verifikasi save tetap berfungsi normal setelah penambahan badge (tidak ada regresi pada test save yang sudah ada).

### Prior art

- **Widget test pattern:** Semua test di `test/features/checklist/presentation/widgets/` menggunakan pola yang sama: `MaterialApp > Scaffold > widget`, pump `pumpWidget`, assert dengan `find.text`, `find.byType`, dan `find.byIcon`.
- **Model test pattern:** `test/features/checklist/data/models/daily_model_test.dart` sebagai referensi untuk unit test murni tanpa widget.

---

## Out of Scope

- Legend/panel keterangan nama item → warna di bawah bar chart (rencana fase selanjutnya).
- Color wheel untuk memilih warna teks secara manual (auto-detect sudah cukup).
- Penyimpanan warna per item ke storage (warna tetap dihitung dari hash nama).
- Dark mode support khusus untuk color wheel (mengikuti tema app yang sudah berjalan).
- Undo/redo di edit history.
- Perubahan model data `DailyLogEntry` (tidak ada field baru yang ditambahkan).
- Validasi integritas nilai `currentValue` terhadap `targetValue` saat save (tetap bebas, pengguna bertanggung jawab atas data historis yang diedit).

---

## Further Notes

- **Urutan implementasi yang disarankan:** F3 → F1 → F2. Fitur 3 bersifat additive murni (hanya tambah widget di UI tanpa ubah logika save), sehingga paling aman sebagai warmup. Fitur 1 mengubah satu dialog secara terisolasi. Fitur 2 mengubah signature widget sehingga perlu update semua caller.

- **Tidak ada perubahan pada `DailySubject.customPalletColor`:** Palet kuratif statis yang sudah ada tetap digunakan apa adanya — tidak perlu ditambah atau dikurangi.

- **Library color picker:** Periksa dulu `pubspec.yaml` sebelum menambah dependency. Jika sudah ada `flex_color_picker` atau alternatif lain, gunakan yang ada agar tidak menambah dependency baru tanpa alasan.

- **Kompatibilitas `fl_chart` untuk stacked bar:** Versi `fl_chart: ^0.69.0` (sudah ada di pubspec) mendukung `rodStackItems` pada `BarChartRodData`. Tidak perlu upgrade versi library.

- **Fungsi `colorFromItemName` sebagai pure function:** Disarankan ditempatkan sebagai top-level function atau static method di file terpisah (misalnya `checklist_color_helper.dart`) agar mudah diuji secara unit tanpa konteks widget.
