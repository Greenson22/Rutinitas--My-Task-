# PRD — History Chart & Edit pada DailyTracker History Screen

| Field | Value |
|---|---|
| Produk | Rutinitasku |
| Nama Fitur | `history_chart_edit` |
| Versi Dokumen | 1.0 |
| Tanggal | 24 November 2026 |
| Status | Draft — siap untuk SPEC |
| Konteks Fitur | Berada di dalam `DailyTrackerHistoryScreen` (fitur `daily_tracker`) |
| Platform Utama | Android |
| Platform Pendukung | Linux desktop |
| Referensi Fitur Sebelumnya | `docs/checklist/daily_tracker/` |

---

## 1. Ringkasan

Fitur ini memperluas **DailyTrackerHistoryScreen** yang sudah ada dengan dua peningkatan utama:

1. **Grafik Bar History** — Menampilkan bar chart interaktif di atas daftar history untuk memvisualisasikan persentase penyelesaian per hari. Default menampilkan bulan ini dengan filter preset (Bulan Ini, 7 Hari, 30 Hari) atau rentang tanggal custom.

2. **Edit & Hapus Satu Entry History** — Pengguna dapat long-press pada card tanggal di daftar untuk membuka menu konteks yang memungkinkan edit status item atau hapus (dengan konfirmasi) untuk satu hari tertentu.

---

## 2. Latar Belakang

### 2.1 Kondisi Saat Ini

- `DailyTrackerHistoryScreen` sudah menampilkan daftar tanggal yang pernah disimpan (descending) dengan ringkasan selesai/total.
- Ketuk tanggal → membuka bottom sheet read-only snapshot hari itu.
- Hapus tersedia hanya di level: hapus semua atau hapus per bulan (bukan per tanggal individual).
- Belum ada visualisasi agregat/grafik progress lintas hari.
- Belum ada cara mengoreksi data salah pada satu hari tertentu.

### 2.2 Masalah yang Diselesaikan

| Masalah | Dampak |
|---|---|
| Tidak bisa melihat tren progress secara visual lintas hari | Tidak bisa mengevaluasi konsistensi kebiasaan secara cepat |
| Default tampilan menampilkan semua history tanpa filter | Daftar bisa sangat panjang; susah fokus ke bulan ini |
| Tidak bisa mengedit status item pada hari yang salah diisi | Data yang salah tidak bisa dikoreksi tanpa hapus seluruh hari |
| Tidak bisa menghapus hanya satu hari tertentu | Kalau satu hari bermasalah, harus hapus per bulan (berlebihan) |

---

## 3. Tujuan dan Non-Goals

### 3.1 Tujuan

| ID | Tujuan | Ukuran Keberhasilan |
|---|---|---|
| G-01 | Grafik bar progress per hari tampil di atas list | Bar chart merender dengan data `dailyLogs` yang difilter |
| G-02 | Default filter = bulan ini (seluruh hari di bulan kalender berjalan) | Saat screen dibuka, otomatis tampil data bulan ini |
| G-03 | Filter preset tersedia: Bulan Ini, 7 Hari, 30 Hari, Custom Range | Chip/tombol filter berfungsi dan memperbarui grafik + list |
| G-04 | Custom Range: pilih dari tanggal berapa s/d tanggal berapa | Date range picker native Flutter dapat dibuka dan hasilnya diterapkan |
| G-05 | Tap batang grafik menampilkan tooltip dengan detail hari | Tooltip tampil: tanggal + % selesai + jumlah (mis: "15 Nov — 80% (8/10)") |
| G-06 | Long-press card tanggal di list → menu edit/hapus | Menu konteks muncul dengan opsi Edit dan Hapus |
| G-07 | Edit entry: bottom sheet dengan toggle status per item (belum/sementara/selesai) & nilai progress/countdown | Bottom sheet editable terbuka dan perubahan tersimpan |
| G-08 | Hapus satu entry memerlukan konfirmasi dialog | Dialog konfirmasi muncul sebelum hapus |
| G-09 | Edit & hapus disimpan persisten via callback ke parent | Callback `onEditEntry` & `onDeleteEntry` dipanggil; data tersimpan di JSON |
| G-10 | List history mengikuti filter yang dipilih (grafik & list sync) | Filter yang sama diterapkan ke grafik dan list di bawahnya |

### 3.2 Non-Goals

- **Bukan** statistik agregat lintas card (dashboard global).
- **Bukan** ekspor data grafik ke gambar/PDF.
- **Bukan** notifikasi berbasis tren.
- **Bukan** edit nama item atau tipe item di history (hanya status & nilai progress/countdown).
- **Bukan** undo/redo setelah edit atau hapus.
- **Bukan** animasi canggih pada grafik (animasi dasar `fl_chart` sudah cukup).

---

## 4. Pengguna dan Skenario

### 4.1 Persona Utama

**Pengguna Rutin** — seseorang yang sudah menggunakan DailyTracker dan ingin mengevaluasi konsistensi kebiasaannya secara visual, serta sesekali perlu mengoreksi data yang salah diisi.

### 4.2 Skenario Utama

**Skenario 1 — Melihat Grafik Bulan Ini (Default)**
> Pengguna membuka History Screen. Langsung tampil bar chart dengan batang per hari untuk bulan November 2026 (bulan berjalan). Chip "Bulan Ini" terpilih. Di bawah grafik, list history juga sudah difilter ke bulan ini.

**Skenario 2 — Filter Custom Range**
> Pengguna ingin melihat data dari 10 Nov sampai 20 Nov. Ia ketuk chip "Custom Range" → date range picker terbuka → pilih 10 Nov & 20 Nov → grafik dan list diperbarui hanya untuk rentang itu.

**Skenario 3 — Tap Batang Grafik**
> Pengguna mengetuk batang tanggal 15 Nov. Tooltip muncul: "15 November — 80% (8/10 selesai)". Pengguna bisa melihat performa hari itu tanpa membuka detail.

**Skenario 4 — Edit Satu Entry History**
> Pengguna sadar kemarin ia lupa centang beberapa item padahal sudah dikerjakan. Ia long-press card tanggal kemarin → menu muncul → pilih "Edit" → bottom sheet edit terbuka → ia toggle beberapa item ke "selesai" → simpan → data tersimpan persisten, ringkasan di card tersebut diperbarui.

**Skenario 5 — Hapus Satu Entry History**
> Pengguna ingin menghapus data tanggal yang salah simpan. Ia long-press card tanggal itu → menu muncul → pilih "Hapus" → dialog konfirmasi muncul → konfirmasi → entry tanggal itu hilang dari list dan grafik.

---

## 5. Deskripsi Fitur

### 5.1 Grafik Bar History

- Library: **`fl_chart`** (ditambahkan ke `pubspec.yaml`).
- Jenis: `BarChart` dari `fl_chart`.
- Sumbu X: label tanggal (hari, disingkat), sumbu Y: persentase 0–100%.
- Tinggi batang = `(finished / total) * 100`. Jika total = 0, batang tidak tampil / tinggi = 0.
- Warna batang: teal jika 100%, abu-abu jika < 100%.
- Interaksi: tap batang → tooltip dengan format `"{dd MMM} — {persen}% ({finished}/{total} selesai)"`.
- Posisi: di atas list history, dalam satu `CustomScrollView` (grafik ikut scroll bersama list).

### 5.2 Filter Rentang Tanggal

- Chip preset: **Bulan Ini** (default) | **7 Hari** | **30 Hari** | **Custom Range**.
- Filter berlaku untuk **grafik** dan **list history** secara bersamaan (sinkron).
- "Bulan Ini" = 1 sampai hari terakhir bulan kalender berjalan.
- "Custom Range": membuka `showDateRangePicker` Flutter native → pilih tanggal mulai & akhir.
- Chip terpilih mendapat tampilan berbeda (filled/selected style).

### 5.3 Edit Satu Entry History

- Trigger: long-press pada `Card` tanggal di list → `showMenu` atau `BottomSheet` context menu dengan opsi "✏️ Edit" dan "🗑️ Hapus".
- **Edit**: membuka `DraggableScrollableSheet` / bottom sheet yang menampilkan daftar item (rekursif, hanya level 1 dan 2 yang editable untuk simplisitas — child dari child ditampilkan read-only atau tidak ditampilkan):
  - Setiap item: nama item (read-only label) + toggle status (chip: Belum / Sementara / Selesai).
  - Jika item bertipe `progress` atau `countdown`: tambahkan input angka `currentValue`.
  - Tombol "Simpan" di bawah → callback `onEditEntry(dateKey, List<DailyLogEntry>)` dipanggil.
- **Hapus**: dialog konfirmasi → callback `onDeleteEntry(dateKey)` dipanggil.

### 5.4 Callback Baru di DailyTrackerHistoryScreen

```dart
final Future<void> Function(String dateKey, List<DailyLogEntry> updatedEntries)? onEditEntry;
final Future<void> Function(String dateKey)? onDeleteEntry;
```

Parent (`ChecklistDetailScreen` atau controller) menyediakan implementasi yang menyimpan perubahan ke `DailySubject.dailyLogs` dan memicu `setState`/persist.

---

## 6. Desain UI

### 6.1 Layout DailyTrackerHistoryScreen (Updated)

```
AppBar: [nama card] [⋮ menu]
─────────────────────────────────
CustomScrollView:
  SliverToBoxAdapter:
    [Filter Chips Row: Bulan Ini | 7 Hari | 30 Hari | Custom Range]
    [Bar Chart — tinggi ~180dp]
  SliverList:
    [Card Tanggal 1] ← long-press → menu edit/hapus
    [Card Tanggal 2]
    ...
─────────────────────────────────
```

### 6.2 Bottom Sheet Edit Entry

```
── drag handle ──
[Tanggal: 24 November 2026]
─ Divider ─
ScrollView:
  Row: [ikon status] [nama item]  [Chip: Belum | Sementara | Selesai]
  Row: (jika progress/countdown)  [TextField: nilai saat ini / target]
  ...
─ Divider ─
[Batal]  [Simpan]
```

---

## 7. Dependensi & Risiko

| Item | Detail |
|---|---|
| Library baru | `fl_chart` perlu ditambahkan ke `pubspec.yaml` dan dijalankan `flutter pub get` |
| Callback baru | `onEditEntry` & `onDeleteEntry` perlu diteruskan dari `ChecklistDetailScreen` ke `DailyTrackerHistoryScreen` |
| `DailyLogEntry` immutable | Saat ini `const` constructor — perlu dibuat copyWith atau buat instance baru untuk edit |
| Filter sinkronisasi | State filter harus memperbarui baik grafik maupun list secara bersamaan |
| Banyak batang grafik | Jika Custom Range sangat panjang (misalnya 1 tahun), batang bisa terlalu rapat — pertimbangkan batas maksimal tampilan atau scroll horizontal pada grafik |

---

## 8. Kriteria Selesai (DoD)

- [ ] `fl_chart` ditambahkan ke `pubspec.yaml`.
- [ ] Bar chart tampil di atas list dengan data bulan ini sebagai default.
- [ ] Filter preset (Bulan Ini, 7 Hari, 30 Hari, Custom Range) berfungsi dan memperbarui grafik + list.
- [ ] Tap batang menampilkan tooltip detail hari.
- [ ] Long-press card tanggal menampilkan menu edit/hapus.
- [ ] Bottom sheet edit entry dapat mengubah status dan nilai progress/countdown setiap item.
- [ ] Hapus satu entry memerlukan konfirmasi dan menghapus entry dari list + grafik.
- [ ] Semua perubahan tersimpan persisten via callback ke parent.
- [ ] Widget tests mencakup: grafik render, filter, edit, hapus per entry.
- [ ] Tidak ada regresi pada test suite yang sudah ada.
