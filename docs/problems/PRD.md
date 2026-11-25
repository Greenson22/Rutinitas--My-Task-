# PRD — Tiga Perbaikan UX (Checklist, History Bar, Task Master)

> **Dibuat:** 2026-11-25
> **Status:** Siap Implementasi

---

## Ringkasan

Dokumen ini mencakup tiga perbaikan UX yang terpisah namun berhubungan dengan pengalaman pengguna di fitur **Checklist**, **History Bar Chart**, dan **Task Master New**.

---

## Fitur 1 — Tombol Aksi Seksi Checklist via Long Press

### Latar Belakang

Di layar `ChecklistDetailScreen`, setiap **ChecklistSection** menampilkan header seksi yang berisi nama seksi. Saat ini, tombol-tombol aksi seksi (Sembunyikan, Pindah Atas, Pindah Bawah, Ubah Nama, Hapus Seksi, Tambah Materi) **selalu tampil** di sisi kanan header, bersamaan dengan teks nama seksi. Ini menyebabkan dua masalah:

1. **Layout rusak**: Bila nama seksi panjang, tombol-tombol mendorong atau memotong teks.
2. **Klutter visual**: Tombol selalu tampil padahal pengguna jarang memakai aksi tersebut.

### Solusi

#### 1a. Tombol Aksi Disembunyikan by Default
Tombol aksi seksi **tidak ditampilkan** saat halaman pertama dibuka. Header seksi hanya menampilkan nama seksi (dan indikator jumlah item bila ada).

#### 1b. Long Press untuk Memunculkan Tombol
Ketika pengguna **menahan (long press)** header seksi, tombol aksi muncul **di bawah nama seksi** (inline, dalam card/area yang sama dengan header seksi). Tombol-tombol ditampilkan dalam format baris horizontal yang bisa wrap.

Tombol aksi yang dimunculkan:
- **Sembunyikan** — toggle `isHidden` pada `ChecklistSection`
- **Pindah Atas** — tukar posisi seksi dengan seksi di atasnya
- **Pindah Bawah** — tukar posisi seksi dengan seksi di bawahnya
- **Ubah Nama** — buka dialog edit nama seksi
- **Hapus Seksi** — konfirmasi lalu hapus
- **Tambah Materi** — buka dialog tambah `DailySubject` ke seksi ini

#### 1c. Toggle via Long Press Lagi
Long press **kedua** pada header seksi yang sama **menyembunyikan** tombol aksi kembali. State ini bersifat lokal per-seksi (`Set<int>` expanded section index di `_ChecklistDetailScreenState`).

### Domain Model yang Relevan

```
ChecklistSection {
  String sectionName
  List<DailySubject> items
  bool isHidden
  bool isCollapsed
}
```

Tidak ada perubahan model data yang diperlukan — state "tombol aksi tampil" adalah UI-only state.

### User Stories

1. Sebagai pengguna, saya ingin header seksi tampil bersih tanpa tombol, sehingga nama seksi yang panjang tidak terpotong.
2. Sebagai pengguna, saya ingin menahan header seksi untuk memunculkan tombol aksi, sehingga saya bisa mengelola seksi dengan mudah.
3. Sebagai pengguna, saya ingin tombol aksi muncul di bawah nama seksi, bukan di sampingnya, sehingga layout tidak rusak saat nama panjang.
4. Sebagai pengguna, saya ingin menahan header seksi lagi untuk menyembunyikan tombol aksi, sehingga tampilan kembali bersih.

### Keputusan Implementasi

- **Widget target**: `InteractiveSectionHeader` (di `core/presentation/widgets/interactive_section_header.dart`) atau bagian header di `ChecklistDetailScreen` yang merender `ChecklistSection`.
- **State**: `Set<int> _expandedActionSections` di state layar (bukan di model data).
- **Layout tombol**: `Wrap` widget dengan `spacing` agar tombol bisa wrap ke baris berikutnya bila layar sempit.
- **Animasi**: `AnimatedSize` atau `AnimatedCrossFade` untuk transisi muncul/sembunyi tombol.
- Tombol yang tampil **tidak mengubah posisi item checklist** di bawahnya dengan cara yang abrupt — gunakan animasi smooth.

### Out of Scope

- Tombol aksi pada baris item individual (SubSubjectItem) tidak berubah.
- Implementasi drag-to-reorder antar seksi (di luar permintaan ini).

---

## Fitur 2 — Legenda Warna di History Bar Chart

### Latar Belakang

Di layar `DailyTrackerHistoryScreen`, bar chart (`HistoryBarChart`) menampilkan batang per tanggal yang diwarnai secara stacked. Setiap warna mewakili satu item checklist (`DailyLogEntry`) yang telah selesai pada hari itu. Warna dihasilkan deterministik dari nama item via fungsi `colorFromItemName(name)` (djb2 hash → HSL).

Masalah: **Pengguna tidak tahu warna mewakili item apa**. Tidak ada legenda.

### Solusi

Tambahkan **legenda warna** berupa daftar scrollable di bawah bar chart. Setiap baris legenda berisi:
- Kotak warna kecil (12×12 dp, rounded)
- Nama item checklist

Legenda menampilkan item yang **relevan dengan filter aktif saat ini** (preset 7 hari, 30 hari, bulan ini, atau custom range). Item yang tidak muncul di filter tidak ditampilkan di legenda.

### Domain yang Relevan

```
DailyLogEntry {
  String itemName      // ← nama item (kunci untuk warna)
  String progress      // 'selesai' | 'sementara' | lainnya
  String itemType
  ...
}

colorFromItemName(String name) → Color  // deterministik dari hash
```

### User Stories

1. Sebagai pengguna, saya ingin melihat legenda warna di bawah bar chart, sehingga saya tahu item mana yang diwakili warna tertentu.
2. Sebagai pengguna, saya ingin legenda berubah mengikuti filter tanggal yang aktif, sehingga hanya item yang relevan yang tampil.
3. Sebagai pengguna, saya ingin bisa scroll legenda bila item banyak, sehingga tidak memakan terlalu banyak ruang layar.

### Keputusan Implementasi

- **Lokasi**: Di dalam `DailyTrackerHistoryScreen`, setelah widget `HistoryBarChart` dan sebelum list riwayat.
- **Data sumber**: Iterasi semua `DailyLogEntry` pada `filteredKeys` → kumpulkan `itemName` unik dari entri yang `progress == 'selesai'` → urutkan alfabetis.
- **Widget legenda**: `Wrap` dengan item `Chip`-like (kotak warna + teks) atau `ListView` dengan `maxHeight` terbatas (mis. 100dp) agar tidak mendominasi layar.
- **Warna**: Gunakan `colorFromItemName(entry.itemName)` yang sudah ada — tidak perlu mapping tambahan.
- Judul section: `"Keterangan Warna"` dengan icon `Icons.palette_outlined`.

### Out of Scope

- Tooltip bar chart sudah menampilkan persentase dan jumlah selesai — tidak perlu mengubah tooltip.
- Kemampuan untuk mengubah warna item secara manual.

---

## Fitur 3 — Edit Nilai Hitungan Harian di Task Master New

### Latar Belakang

Di `CategoryDetailScreen`, setiap tugas (`Task`) ditampilkan oleh `TaskTile`. Ketika pengguna menekan menu titik 3 (⋮) → **Ubah**, dialog `TaskFormDialog` terbuka. Dialog saat ini memiliki field:

- Nama tugas
- Jenis tugas (Habit / Counter / Progress)
- Target Harian
- Target Total (hanya untuk Progress)
- Tampil di Hari Ini (visibilitas)
- Status aktif

**Masalah**: Tidak ada cara untuk **mengubah nilai hitungan** (`count`) yang sudah tercatat pada tugas. Contoh: Tugas A tercatat `320` hari ini, pengguna ingin mengoreksi ke `20` atau `0`. Saat ini satu-satunya cara adalah increment satu per satu.

### Solusi

Tambahkan field **"Hitungan Hari Ini"** (edit hitungan harian `countOn(todayKey)`) di `TaskFormDialog` ketika dialog dibuka dalam mode **edit** (bukan tambah baru). Field ini memungkinkan pengguna mengedit nilai hitungan hari ini secara langsung.

Selain itu, field yang sudah ada (nama, target harian, target total, dll) tetap ada.

### Domain yang Relevan

```dart
Task {
  Map<String, DailyProgress> history  // key: 'YYYY-MM-DD'
  int countOn(String date)             // → history[date]?.count ?? 0
  int totalCount                       // akumulasi semua hitungan
}

DailyProgress {
  String date
  int count
  DateTime updatedAt
}
```

Mengubah `count` hari ini harus juga mengupdate `totalCount` di `Task` secara konsisten (delta = newCount - oldCount diterapkan ke totalCount).

### User Stories

1. Sebagai pengguna, saya ingin membuka dialog Ubah Tugas dan melihat hitungan hari ini di sana, sehingga saya bisa mengoreksi nilai yang salah.
2. Sebagai pengguna, saya ingin mengubah hitungan hari ini dari 320 menjadi 20 atau 0, sehingga data saya akurat.
3. Sebagai pengguna, saya ingin perubahan hitungan harian otomatis menyesuaikan total akumulasi tugas, sehingga data tidak inkonsisten.
4. Sebagai pengguna, saya ingin field hitungan hanya muncul saat mode edit (bukan mode tambah baru), karena saat tambah baru tidak ada hitungan yang perlu diedit.

### Keputusan Implementasi

- **Field baru di `TaskFormDialog`**: `TextEditingController _countTodayController` dengan nilai awal `task.countOn(todayKey)`. Field hanya tampil bila `_isEditing == true`.
- **Label field**: `"Hitungan Hari Ini"` dengan `helperText: 'Nilai saat ini: ${task.countOn(todayKey)}'`.
- **Validasi**: Harus bilangan bulat ≥ 0.
- **Callback `onSave`**: Tambah parameter opsional `int? countToday` ke signature `onSave`. Bila berubah, controller memanggil operasi untuk mengupdate `DailyProgress` di `history[todayKey]` dan menyesuaikan `totalCount`.
- **Delta totalCount**: `newTotalCount = task.totalCount - oldCount + newCount`.
- **todayKey** diteruskan ke dialog oleh `CategoryDetailScreen` via konstruktor.

### Perubahan Interface `onSave`

```dart
// SEBELUM
final Future<bool> Function({
  required String name,
  required TaskKind kind,
  required int targetDaily,
  required int targetTotal,
  required bool isActive,
  required TodayVisibility todayVisibility,
}) onSave;

// SESUDAH
final Future<bool> Function({
  required String name,
  required TaskKind kind,
  required int targetDaily,
  required int targetTotal,
  required bool isActive,
  required TodayVisibility todayVisibility,
  int? countToday,       // ← BARU; null = tidak ada perubahan hitungan
  String? countDate,     // ← BARU; todayKey saat edit
}) onSave;
```

### Out of Scope

- Edit hitungan pada tanggal lain (bukan hari ini) — ini fitur terpisah.
- Edit hitungan via swipe gesture pada baris tugas.
- History screen Task Master (edit sudah tersedia via `TaskHistoryScreen`).

---

## Glosarium Domain

| Term | Definisi |
|------|----------|
| `ChecklistSection` | Pengelompok `DailySubject` card dalam satu grup checklist. Memiliki `sectionName`, `items`, `isHidden`, `isCollapsed`. |
| `DailySubject` | Card checklist individual dengan daftar sub-materi (checklist items). |
| `ChecklistGroup` | Container file JSON yang berisi beberapa `ChecklistSection`. |
| `DailyLogEntry` | Satu entri snapshot riwayat harian untuk checklist, berisi `itemName` dan `progress`. |
| `colorFromItemName` | Fungsi deterministik djb2 hash → HSL untuk menghasilkan warna unik per nama item. |
| `Task` | Entitas tugas di Task Master New. Memiliki `history` sparse, `totalCount`, `targetDaily`, `targetTotal`. |
| `DailyProgress` | Satu entri riwayat harian tugas dengan `date`, `count`, `updatedAt`. |
| `TaskFormDialog` | Dialog tambah/edit tugas di Task Master New. |
| `todayKey` | String format `YYYY-MM-DD` untuk hari ini, digunakan sebagai kunci di `Task.history`. |
