# PRD — DailyTracker

| Field | Value |
|---|---|
| Produk | Rutinitasku |
| Nama Fitur | `daily_tracker` |
| Versi Dokumen | 1.0 |
| Tanggal | 23 November 2026 |
| Status | Draft — siap untuk SPEC |
| Konteks Fitur | Berada di dalam `ChecklistDetailScreen` |
| Platform Utama | Android |
| Platform Pendukung | Linux desktop |

---

## 1. Ringkasan

**DailyTracker** adalah mode tracking harian yang dapat diaktifkan per card `DailySubject` di dalam `ChecklistDetailScreen`. Ketika diaktifkan, pengguna dapat mencentang item-item seperti biasa, lalu menekan tombol **"Simpan Hari Ini"** untuk menyimpan snapshot status seluruh item sebagai catatan harian. Setiap hari memiliki rekam jejaknya sendiri, yang dapat dilihat kembali melalui **DailyTracker History Screen** — serupa dengan fitur Jurnal Aktivitas yang sudah ada.

Fitur ini tidak mengubah tampilan atau cara kerja card checklist yang belum mengaktifkan DailyTracker. Card dengan DailyTracker aktif mendapat badge penanda, tombol aksi tambahan, dan link ke history-nya.

---

## 2. Latar Belakang

### 2.1 Kondisi Saat Ini

- `DailySubject` (card checklist) sudah mendukung list item bertingkat (`SubSubjectItem`) dengan status progress: `belum`, `sementara`, `selesai`.
- Pengguna bisa mencentang item setiap hari, namun status tersebut **tidak tersimpan sebagai riwayat harian** — keesokan harinya, data hari kemarin tidak terdokumentasi.
- Tidak ada mekanisme untuk melacak konsistensi pengerjaan checklist per hari.
- Fitur Jurnal Aktivitas sudah ada dan menjadi referensi UX untuk tampilan history.

### 2.2 Masalah yang Diselesaikan

| Masalah | Dampak |
|---|---|
| Status centang item hilang setiap hari | Tidak ada rekam jejak pengerjaan rutin |
| Tidak bisa melihat "kemarin saya sudah selesaikan apa" | Tidak mendukung kebiasaan reflektif |
| Tidak ada cara reset manual untuk hari baru | Pengguna harus hapus centang satu-satu |
| Tidak ada agregasi progress checklist per hari | Tidak bisa mengevaluasi konsistensi |

---

## 3. Tujuan dan Non-Goals

### 3.1 Tujuan

| ID | Tujuan | Ukuran Keberhasilan |
|---|---|---|
| G-01 | Mode DailyTracker bisa diaktifkan per card DailySubject | Toggle tersedia dan persisten di JSON |
| G-02 | Status item tersimpan per hari dengan key tanggal | `dailyLogs['yyyy-MM-dd']` terbentuk saat simpan |
| G-03 | Data hari ini tetap tampil setelah disimpan | UI tidak berubah setelah tekan "Simpan Hari Ini" |
| G-04 | Reset hari baru bisa dilakukan secara eksplisit | Semua item kembali ke `belum` / `currentValue: 0` |
| G-05 | History per tanggal bisa dilihat di screen terpisah | DailyTracker History Screen dapat diakses dari card |
| G-06 | History bisa dihapus per card atau per bulan | Opsi hapus tersedia di History Screen |
| G-07 | Backward compatible: card lama tanpa field baru tetap bekerja | `fromJson` memberi default `isDailyTrackerEnabled: false` |

### 3.2 Non-Goals

- **Bukan** fitur notifikasi/reminder untuk mengisi checklist harian.
- **Bukan** sinkronisasi atau backup cloud.
- **Bukan** statistik agregat lintas card (misalnya: "minggu ini berapa card yang 100% selesai").
- **Bukan** perubahan pada card yang tidak mengaktifkan DailyTracker.
- **Bukan** otomatisasi reset — reset hanya dilakukan atas permintaan eksplisit pengguna.

---

## 4. Pengguna dan Skenario

### 4.1 Persona Utama

**Pengguna Rutin** — seseorang yang memiliki checklist rutinitas harian (contoh: "Rutinitas Pagi", "Ibadah Harian") dan ingin melacak seberapa konsisten mereka mengerjakannya dari hari ke hari.

### 4.2 Skenario Utama

**Skenario 1 — Aktivasi DailyTracker**
> Pengguna membuka ChecklistDetail, melihat card "Rutinitas Pagi". Ia membuka popup menu card → memilih "Aktifkan DailyTracker". Card sekarang menampilkan badge DailyTracker dan tombol-tombol aksi baru muncul.

**Skenario 2 — Mengisi dan Menyimpan Hari Ini**
> Pengguna mencentang item-item di card. Setelah selesai (atau kapanpun ingin menyimpan), ia menekan tombol **"Simpan Hari Ini"**. Muncul konfirmasi singkat (SnackBar). Data hari ini tersimpan, tampilan tidak berubah.

**Skenario 3 — Reset untuk Hari Baru**
> Keesokan paginya, pengguna ingin memulai hari baru dengan item kosong. Ia menekan tombol **"Reset Hari Baru"**. Semua item kembali ke `belum`. (Reset hanya bisa dilakukan setelah hari sebelumnya disimpan, atau secara eksplisit.)

**Skenario 4 — Melihat History**
> Pengguna penasaran dengan apa yang dikerjakan seminggu lalu. Ia menekan tombol **"Lihat History"** di card. Aplikasi membuka **DailyTracker History Screen** yang menampilkan daftar tanggal yang pernah disimpan. Pengguna mengetuk tanggal dan melihat snapshot item pada hari itu (read-only).

**Skenario 5 — Menghapus History**
> Pengguna ingin membersihkan history bulan lalu. Di History Screen, ia memilih opsi "Hapus per bulan" → memilih bulan Oktober 2026 → konfirmasi → history bulan tersebut terhapus.

---

## 5. Deskripsi Fitur

### 5.1 Aktivasi DailyTracker

- Toggle aktivasi tersedia via **popup menu card** di `ChecklistDetailScreen` (item baru: "Aktifkan DailyTracker" / "Nonaktifkan DailyTracker").
- Ketika aktif, card menampilkan **badge** kecil (misalnya: ikon 📅 atau label "Daily" berwarna) di area header card.
- Status aktif/nonaktif disimpan di field `isDailyTrackerEnabled` pada `DailySubject`.
- Menonaktifkan DailyTracker **tidak menghapus** `dailyLogs` yang sudah tersimpan.

### 5.2 Menyimpan Data Hari Ini ("Simpan Hari Ini")

- Tombol **"Simpan Hari Ini"** muncul di dalam card ketika DailyTracker aktif.
- Menekan tombol ini akan:
  1. Membuat snapshot rekursif seluruh `SubSubjectItem` (nama, progress, tipe, nilai) → list `DailyLogEntry`.
  2. Menyimpan ke `dailyLogs[tanggalHariIni]` di dalam `DailySubject`.
  3. Memanggil `saveGroupData()` untuk menulis ke file JSON.
  4. Menampilkan SnackBar: *"Data [tanggal] berhasil disimpan"*.
- Jika tombol ditekan lebih dari sekali di hari yang sama, log **di-overwrite** (snapshot terbaru menang).
- UI **tidak berubah** setelah menyimpan — item tetap menampilkan status saat ini.

### 5.3 Reset Hari Baru ("Reset Hari Baru")

- Tombol **"Reset Hari Baru"** muncul di dalam card ketika DailyTracker aktif.
- Menekan tombol ini akan menampilkan dialog konfirmasi terlebih dahulu.
- Setelah dikonfirmasi:
  1. Semua `SubSubjectItem` di-reset: `progress = 'belum'`, `currentValue = 0`.
  2. `saveGroupData()` dipanggil.
- Reset tidak menghapus history — `dailyLogs` tetap utuh.

### 5.4 DailyTracker History Screen

- Screen baru, diakses via tombol **"Lihat History"** di dalam card (ikon riwayat/kalender).
- **Layout:**
  - AppBar dengan judul nama card ("History: Rutinitas Pagi") dan tombol back.
  - List tanggal yang pernah disimpan, diurutkan dari terbaru ke terlama.
  - Setiap item list menampilkan: tanggal, jumlah item selesai / total item.
  - Mengetuk tanggal → membuka detail snapshot (read-only, mirip tampilan checklist).
- **Detail snapshot:** Menampilkan `DailyLogEntry` secara rekursif, mirip `ChecklistTreeView` tapi non-interaktif. Item `selesai` tampil dengan centang, `belum` tampil abu-abu.

### 5.5 Hapus History

Tersedia di DailyTracker History Screen melalui menu atau tombol:

| Opsi | Aksi |
|---|---|
| Hapus semua history card ini | `dailyLogs = {}` → simpan |
| Hapus per bulan | Dialog pilih bulan → hapus semua key dengan prefix `yyyy-MM` |

Kedua aksi memerlukan dialog konfirmasi sebelum dieksekusi.

---

## 6. Struktur Data

### 6.1 Perubahan pada `DailySubject`

Dua field baru ditambahkan ke `DailySubject`:

```dart
class DailySubject {
  // ... field yang sudah ada ...

  /// Apakah mode DailyTracker aktif untuk card ini.
  /// Default: false (backward compatible).
  bool isDailyTrackerEnabled;

  /// Riwayat harian. Key: 'yyyy-MM-dd'. Value: snapshot items.
  /// Disimpan dalam JSON sebagai map nested.
  Map<String, List<DailyLogEntry>> dailyLogs;
}
```

**Perubahan `fromJson` (backward compatible):**
```dart
isDailyTrackerEnabled: json['isDailyTrackerEnabled'] ?? false,
dailyLogs: _parseDailyLogs(json['dailyLogs']),
```

### 6.2 Model Baru: `DailyLogEntry`

```dart
class DailyLogEntry {
  final String itemName;
  final String progress;      // 'belum', 'sementara', 'selesai'
  final String itemType;      // 'normal', 'progress', 'countdown'
  final int currentValue;
  final int targetValue;
  final List<DailyLogEntry> children; // Mendukung struktur tree rekursif

  factory DailyLogEntry.fromSubSubjectItem(SubSubjectItem item) { ... }
  factory DailyLogEntry.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

### 6.3 Contoh JSON

```json
{
  "nama_materi": "Rutinitas Pagi",
  "isDailyTrackerEnabled": true,
  "dailyLogs": {
    "2026-11-23": [
      {
        "itemName": "Olahraga",
        "progress": "selesai",
        "itemType": "normal",
        "currentValue": 0,
        "targetValue": 0,
        "children": []
      },
      {
        "itemName": "Minum Air",
        "progress": "belum",
        "itemType": "progress",
        "currentValue": 5,
        "targetValue": 8,
        "children": []
      }
    ],
    "2026-11-22": [
      {
        "itemName": "Olahraga",
        "progress": "belum",
        "itemType": "normal",
        "currentValue": 0,
        "targetValue": 0,
        "children": []
      }
    ]
  }
}
```

---

## 7. Komponen yang Terlibat

| Komponen | File | Perubahan |
|---|---|---|
| `DailySubject` | `daily_model.dart` | Tambah `isDailyTrackerEnabled`, `dailyLogs`, update `fromJson`/`toJson` |
| `DailyLogEntry` | `daily_model.dart` | **[BARU]** Model snapshot item harian |
| `ChecklistDetailController` | `checklist_detail_controller.dart` | Tambah `saveTodayLog()`, `resetForNewDay()`, `deleteDailyLog()`, `deleteDailyLogsByMonth()` |
| Card UI di `checklist_dialog.dart` | `checklist_dialog.dart` | Tampilkan badge, tombol "Simpan Hari Ini", "Reset Hari Baru", "Lihat History" jika DailyTracker aktif |
| Popup menu card | `checklist_detail_screen.dart` | Tambah item menu "Aktifkan/Nonaktifkan DailyTracker" |
| `DailyTrackerHistoryScreen` | `daily_tracker_history_screen.dart` | **[BARU]** Screen history per tanggal |
| `DailyTrackerHistoryController` | `daily_tracker_history_controller.dart` | **[BARU]** Logic load & hapus history dari `DailySubject.dailyLogs` |

---

## 8. Persyaratan Non-Fungsional

| Aspek | Persyaratan |
|---|---|
| Backward Compatibility | File JSON lama tanpa field `isDailyTrackerEnabled` dan `dailyLogs` tetap terbaca; default ke `false` dan `{}` |
| Ukuran File JSON | History yang menumpuk bisa memperbesar file JSON. Mitigasi: fitur hapus history per bulan. |
| Performa | Snapshot saat "Simpan Hari Ini" harus selesai < 200 ms untuk checklist hingga 200 item bertingkat. |
| Konsistensi Data | Jika "Simpan" ditekan dua kali dalam satu hari, log di-overwrite — tidak ada duplikasi. |
| Enkripsi | Jika `ChecklistGroup.isEncrypted = true`, data `dailyLogs` ikut terenkripsi bersama seluruh file JSON (sudah dihandle oleh mekanisme enkripsi yang ada). |
| Platform | Fitur berjalan di Android dan Linux desktop. Tidak ada dependensi platform-spesifik. |

---

## 9. Keputusan Desain Terbuka

| # | Pertanyaan | Keputusan |
|---|---|---|
| D1 | Di mana tombol "Simpan Hari Ini" ditempatkan? | Di dalam card (di checklist_dialog.dart), hanya muncul jika `isDailyTrackerEnabled = true` |
| D2 | Konflik simpan di hari yang sama? | Overwrite — snapshot terbaru menang |
| D3 | Apakah reset memerlukan konfirmasi? | Ya, dialog konfirmasi wajib sebelum reset |
| D4 | Apakah `dailyLogs` ditampilkan sebagai read-only di History? | Ya, History Screen non-interaktif (tidak bisa mengubah data lama) |
| D5 | Format key tanggal? | `yyyy-MM-dd` (ISO 8601, mudah diurutkan dan diparse) |
| D6 | Apakah ada batas maksimum history? | Tidak ada batas teknis; pengguna mengelola sendiri via fitur hapus |

---

## 10. Kriteria Keberhasilan

- [ ] Toggle DailyTracker per card bisa diaktifkan/nonaktifkan dan status tersimpan di JSON.
- [ ] Menekan "Simpan Hari Ini" menyimpan snapshot seluruh item dengan key tanggal `yyyy-MM-dd`.
- [ ] Menekan "Simpan Hari Ini" dua kali di hari yang sama menghasilkan overwrite, bukan duplikasi.
- [ ] Data yang sudah disimpan tetap tampil di UI setelah tombol ditekan (tidak ada perubahan tampilan).
- [ ] Menekan "Reset Hari Baru" (dengan konfirmasi) mereset semua item ke `belum` / `currentValue: 0`.
- [ ] DailyTracker History Screen menampilkan daftar tanggal dari `dailyLogs.keys`, diurutkan terbaru ke lama.
- [ ] Mengetuk tanggal di History Screen menampilkan snapshot item secara read-only.
- [ ] Opsi "Hapus semua history" dan "Hapus per bulan" bekerja dengan benar dan memerlukan konfirmasi.
- [ ] File JSON yang tidak memiliki field `isDailyTrackerEnabled` dan `dailyLogs` tetap terbaca tanpa error.
- [ ] Jika `ChecklistGroup.isEncrypted = true`, data `dailyLogs` ikut terenkripsi dengan benar.
- [ ] Card yang **tidak** mengaktifkan DailyTracker tidak menampilkan tombol atau badge apapun (zero visual noise).
