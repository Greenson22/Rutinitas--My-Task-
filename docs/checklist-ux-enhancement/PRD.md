# PRD — Checklist UX Enhancement
**Versi:** 1.0  
**Tanggal:** 2026-11-25  
**Status:** Draft — Siap Implementasi  

---

## 1. Latar Belakang & Permasalahan

Fitur **Checklist** (DailyTracker) saat ini memiliki tiga area UX yang belum optimal:

| # | Area | Masalah |
|---|------|---------|
| 1 | **Pemilihan warna Card Checklist** | Dialog `ChangeColorDialog` hanya menyediakan grid palet statis dan input HEX mentah. Pengguna tidak bisa mengeksplorasi spektrum warna secara visual dan intuitif. Selain itu, warna teks (textColor) kadang tidak terbaca karena kontras yang buruk dengan warna latar. |
| 2 | **Bar History DailyTracker** | `HistoryBarChart` menampilkan setiap bar dengan satu warna solid (oranye/teal/abu berdasarkan persentase). Informasi "item mana yang selesai hari itu" tidak terbaca secara visual. |
| 3 | **Edit History — tampilan tipe item** | Di `EditHistoryEntrySheet`, item bertipe `progress` dan `countdown` sudah ada input nilai numerik, tetapi tidak ada indikator visual yang jelas tentang tipe item sehingga pengguna bingung konteks setiap field yang mereka edit. |

---

## 2. Solusi

### Fitur 1 — Color Wheel pada ChangeColorDialog
Tambahkan **color wheel interaktif** di samping atau di atas input HEX yang sudah ada. Keduanya tetap tampil berdampingan: wheel untuk eksplorasi visual, HEX input untuk presisi angka. Warna teks (`textColor`) dikalkulasi **otomatis** via `ThemeData.estimateBrightnessForColor` tanpa opsi override manual.

### Fitur 2 — Bar History Multi-Warna per Item
Ubah setiap bar di `HistoryBarChart` menjadi **stacked bar**: tiap segmen mewakili satu item yang selesai pada hari tersebut, dengan warna unik yang diturunkan dari **hash nama item** (algoritma djb2/fnv1a → HSL → Color). Item yang belum selesai tidak mendapat segmen (atau bisa diberi segmen abu tipis sebagai "sisa").

### Fitur 3 — Edit History Sadar Tipe Item
Di `EditHistoryEntrySheet`, tambahkan **badge/chip tipe item** di sebelah nama item. Badge menampilkan ikon & label: 📊 `Progress`, ⏳ `Hitung Mundur`, atau ✅ `Normal`. Untuk item `progress` dan `countdown`, input nilai numerik tetap bisa diubah pengguna (bukan dikunci). Status selector (Belum/Sementara/Selesai) tetap manual untuk semua tipe.

---

## 3. User Stories

### Fitur 1 — Color Wheel

1. Sebagai pengguna, saya ingin membuka dialog ubah warna dan melihat color wheel yang interaktif, agar saya bisa memilih warna secara visual tanpa harus hafal kode HEX.
2. Sebagai pengguna, saya ingin bisa menyeret titik pada color wheel untuk mengubah hue dan saturation secara real-time, agar preview card langsung berubah.
3. Sebagai pengguna, saya ingin input HEX tetap tersedia di bawah color wheel, agar saya bisa memasukkan warna yang presisi dari sumber luar (desainer, branding).
4. Sebagai pengguna, saya ingin memilih warna di color wheel dan nilai HEX langsung terupdate secara sinkron, agar kedua kontrol selalu sinkron.
5. Sebagai pengguna, saya ingin memilih warna dan warna teks teks (hitam/putih) otomatis dipilihkan berdasarkan kecerahan warna background, agar card selalu terbaca.
6. Sebagai pengguna, saya ingin melihat pratinjau (live preview) card dengan warna background & teks pilihan sebelum menyimpan, agar tidak terkejut hasilnya.
7. Sebagai pengguna, saya ingin palet warna kuratif tetap tersedia sebagai shortcut, agar saya bisa memilih cepat tanpa berinteraksi dengan wheel.
8. Sebagai pengguna, saya ingin menekan tombol "Simpan Warna" dan perubahan warna langsung terefleksi di card, agar feedback terasa instan.

### Fitur 2 — Bar History Multi-Warna

9. Sebagai pengguna, saya ingin melihat bar history tersusun dari segmen berwarna, agar saya langsung tahu item mana yang saya selesaikan pada hari tertentu.
10. Sebagai pengguna, saya ingin setiap item selalu memiliki warna yang konsisten (tidak berubah antar hari), agar saya bisa mengenali item secara visual tanpa membaca nama.
11. Sebagai pengguna, saya ingin warna item diturunkan dari nama item secara deterministik, agar tidak butuh konfigurasi tambahan.
12. Sebagai pengguna, saya ingin warna-warna yang dihasilkan mudah dibedakan satu sama lain (kontras antar-segmen cukup), agar bar mudah dibaca.
13. Sebagai pengguna, saya ingin tooltip pada bar tetap berfungsi dan menampilkan tanggal, persentase, serta detail item/total, agar informasi kuantitatif tidak hilang.
14. Sebagai pengguna, saya ingin bar yang 0% (tidak ada progress) tetap tampil sebagai batang abu-abu tipis, agar saya tahu hari itu memang tidak ada yang diselesaikan.

### Fitur 3 — Edit History Sadar Tipe

15. Sebagai pengguna, saya ingin melihat badge tipe di sebelah nama setiap item saat membuka Edit History, agar saya langsung tahu apakah item itu normal, progress, atau hitung mundur.
16. Sebagai pengguna, saya ingin badge item `progress` menampilkan ikon 📊 dan label "Progress", agar tipenya langsung terbaca.
17. Sebagai pengguna, saya ingin badge item `countdown` menampilkan ikon ⏳ dan label "Hitung Mundur", agar tipenya langsung terbaca.
18. Sebagai pengguna, saya ingin item `progress` menampilkan field input nilai dengan label "Nilai saat ini" dan keterangan "/ {targetValue}", agar saya paham konteks angka yang saya edit.
19. Sebagai pengguna, saya ingin item `countdown` menampilkan field input nilai dengan label "Sisa" dan keterangan "/ {targetValue}", agar saya paham konteks angka yang saya edit.
20. Sebagai pengguna, saya ingin status selector (Belum/Sementara/Selesai) tetap bisa diubah manual untuk semua tipe item, agar saya bisa mengkoreksi status yang salah saat edit historis.
21. Sebagai pengguna, saya ingin item children (sub-item) juga menampilkan badge tipe yang sesuai, agar tidak ada ambiguitas di hierarki manapun.

---

## 4. Keputusan Implementasi

### 4.1 Color Wheel (Fitur 1)

- **Library:** Gunakan package `flutter_colorpicker` (sudah umum di ekosistem Flutter) yang menyediakan widget `ColorPicker` dengan mode `HSL` atau `HSV wheel`. Alternatif: `flex_color_picker`. Periksa `pubspec.yaml` apakah sudah ada.
- **Layout Dialog:** Urutan komponen dalam `ChangeColorDialog`:
  1. Live Preview (tetap di paling atas)
  2. **Color Wheel** (tambahan baru — di bawah preview)
  3. Input HEX (tetap, sinkron dua arah dengan wheel)
  4. Palet kuratif statis (tetap, bawah)
- **Sinkronisasi:** Ketika wheel digeser → update `_selectedBgColor` → update `_hexInputController.text`. Ketika HEX diketik (valid 6 karakter) → update `_selectedBgColor` → wheel ikut bergerak ke posisi warna tersebut.
- **Auto-Text-Color:** Brightness detection tetap via `ThemeData.estimateBrightnessForColor`. Dropdown manual "Gelap/Putih" **dihapus**.
- **Penyimpanan:** Tidak ada perubahan pada model data (`backgroundColor` dan `textColor` tetap `int` di `DailySubject`).

### 4.2 Bar History Multi-Warna (Fitur 2)

- **Algoritma warna dari nama:**
  ```dart
  // Fungsi deterministik: nama item → Color
  Color _colorFromItemName(String name) {
    // djb2 hash
    int hash = 5381;
    for (final c in name.codeUnits) {
      hash = ((hash << 5) + hash) + c;
      hash &= 0xFFFFFFFF; // 32-bit
    }
    final double hue = (hash % 360).toDouble().abs();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.55).toColor();
  }
  ```
  Saturation tetap 0.6, Lightness tetap 0.55 agar warna cukup cerah dan terbedakan.

- **Struktur bar stacked:**  
  Setiap `BarChartGroupData` memiliki **satu** `BarChartRodData` dengan `rodStackItems: List<BarChartRodStackItem>`. Tiap stack item merepresentasikan satu item yang berstatus `'selesai'`.
  - Nilai tiap stack item: **1 unit per item selesai** (atau bobot dari `targetValue` untuk progress/countdown — keputusan: gunakan **1 unit flat** untuk kesederhanaan).
  - Y-axis: tetap 0–100 (persentase) agar grafik tidak berubah skala.
  - Item yang belum selesai: tidak mendapat segmen (tidak di-render dalam stack).
  - Bar 0%: tampilkan batang abu-abu minimal (`toY: 5`, warna `Colors.grey.shade200`) agar bar tetap tampak.

- **Data yang dibutuhkan `HistoryBarChart`:** Widget perlu menerima daftar nama item (dan tipenya) untuk membuat mapping nama→warna. Tambah parameter `List<String> itemNames` atau gunakan `List<DailyLogEntry>` flatten dari semua entri agar bisa mengekstrak nama item unik.

- **Tooltip:** Tetap menampilkan `tanggal\n%\n(selesai/total)`. Tidak perlu legend (legenda item) di versi 1 ini untuk menjaga UI simpel.

### 4.3 Edit History Sadar Tipe (Fitur 3)

- **Badge tipe:** Widget `Chip` kecil atau `Container` dengan border radius, ikon + label teks kecil. Ditempatkan di bawah nama item (bukan inline di row yang sama, agar tidak desak status selector).
- **Badge spec:**
  - `itemType == 'normal'` → ✅ "Normal" (abu-abu, tampilkan hanya jika ada value input = tidak tampil untuk normal karena tidak ada value input)  
  - `itemType == 'progress'` → 📊 "Progress" (biru muda)  
  - `itemType == 'countdown'` → ⏳ "Hitung Mundur" (oranye)  
  - Badge hanya tampil untuk `progress` dan `countdown` (item `normal` tanpa value input tidak perlu badge).
- **Label input nilai:**
  - `progress` → Label: `"Nilai saat ini:"`, suffix: `"/ {targetValue}"`
  - `countdown` → Label: `"Sisa:"`, suffix: `"/ {targetValue}"`
- **Status selector:** Tidak ada perubahan — tetap `SegmentedButton` dengan 3 opsi manual.
- **Sub-item (children):** Ikuti aturan yang sama secara rekursif di `_buildEntryItem`.

---

## 5. Keputusan Arsitektur / ADR

### ADR-001: Color wheel library pilihan
**Konteks:** Perlu widget color wheel interaktif di Flutter.  
**Keputusan:** Gunakan `flutter_colorpicker` atau `flex_color_picker`. Periksa dulu `pubspec.yaml` — jika belum ada keduanya, tambahkan `flutter_colorpicker` karena lebih ringan.  
**Konsekuensi:** Tambahan dependency. Jika sudah ada alternatif, gunakan yang ada.

### ADR-002: Algoritma warna deterministik
**Konteks:** Warna item di bar history harus konsisten antar sesi dan antar hari tanpa disimpan ke storage.  
**Keputusan:** Gunakan djb2 hash dari `String.codeUnits` → HSL dengan S=0.6, L=0.55.  
**Konsekuensi:** Warna tidak bisa dikustomisasi per item. Jika dua item kebetulan hash ke hue yang sangat mirip, warnanya bisa susah dibedakan (acceptable trade-off untuk MVP).

### ADR-003: Bar stacked vs multi-rod
**Konteks:** `fl_chart` mendukung baik `rodStackItems` (stacked dalam satu rod) maupun beberapa `BarChartRodData` per group.  
**Keputusan:** Gunakan `rodStackItems` dalam satu `BarChartRodData` agar lebih mudah dikontrol tinggi totalnya (selalu 100%).  
**Konsekuensi:** Semua item selesai direpresentasikan secara proporsional dalam 100% tinggi bar.

---

## 6. Glosarium Domain

| Istilah | Definisi | Lokasi kode |
|---------|----------|-------------|
| **DailySubject** | Card utama checklist yang bisa dikustomisasi warna, ikon, dan nama. Memiliki daftar item (`subMateri`) dan riwayat harian (`dailyLogs`). | `daily_model.dart` |
| **SubSubjectItem** | Item individual dalam satu DailySubject. Memiliki tipe (`normal`, `progress`, `countdown`) dan bisa bersarang (hierarki). | `daily_model.dart` |
| **DailyLogEntry** | Snapshot status satu item pada satu tanggal. Disimpan di `dailyLogs[dateKey]`. Strukturnya mirror `SubSubjectItem` tapi immutable. | `daily_model.dart` |
| **HistoryBarChart** | Widget grafik batang yang memvisualisasikan persentase penyelesaian per tanggal. | `history_bar_chart.dart` |
| **EditHistoryEntrySheet** | Modal bottom sheet untuk mengedit snapshot riwayat pada tanggal tertentu. | `edit_history_entry_sheet.dart` |
| **ChangeColorDialog** | Dialog untuk memilih warna background dan teks sebuah DailySubject. | `change_color_dialog.dart` |
| **itemType** | Enum string tipe item: `'normal'` (checklist biasa), `'progress'` (nilai naik menuju target), `'countdown'` (nilai turun menuju nol). | `SubSubjectItem.itemType` |
| **progress** | Status item: `'belum'` (belum dikerjakan), `'sementara'` (sedang), `'selesai'` (selesai). | `SubSubjectItem.progress` |
| **backgroundColor / textColor** | Warna card disimpan sebagai `int` (nilai `Color.value`) di `DailySubject`. | `daily_model.dart` |
| **dailyLogs** | Map berisi log harian: `{dateKey: List<DailyLogEntry>}`. Key berformat `'yyyy-MM-dd'`. | `DailySubject.dailyLogs` |
| **dateKey** | String format `'yyyy-MM-dd'` sebagai kunci untuk tiap sesi log harian. | Seluruh history screen |
| **stack item** | Segmen dalam satu bar chart yang mewakili satu item selesai, diwarnai berdasarkan hash nama item. | Fitur baru di `HistoryBarChart` |
| **djb2 hash** | Algoritma hash string sederhana: `hash = hash * 33 + charCode`, digunakan untuk memetakan nama item ke hue warna HSL. | Fungsi baru `_colorFromItemName` |
| **customPalletColor** | Daftar palet warna kuratif statis yang tersedia di `DailySubject` dan `ChangeColorDialog`. | `daily_model.dart` |

---

## 7. Out of Scope

- Menyimpan warna item ke storage (warna tetap dihitung dari hash nama, tidak dikonfigurasi).
- Legend/keterangan item di bawah bar chart (fase selanjutnya).
- Color wheel untuk memilih warna teks secara manual (otomatis saja).
- Perubahan model data `DailyLogEntry` (tidak ada field baru).
- Dark mode support untuk color wheel (mengikuti tema app yang sudah ada).
- Undo/redo di edit history.

---

## 8. Catatan Tambahan

- Pastikan periksa `pubspec.yaml` untuk ketersediaan library color picker sebelum implementasi Fitur 1.
- Fitur 2 (stacked bar) membutuhkan perubahan signature `HistoryBarChart` — pastikan semua caller diupdate.
- Fitur 3 bersifat **additive** (tidak mengubah logika save), sehingga paling aman diimplementasi pertama sebagai warmup.
- Urutan implementasi yang disarankan: **F3 → F1 → F2** (dari risiko terendah ke tertinggi).
