# PRD — Sinkronisasi Persentase, Unique ID Kaitan, dan Tampilan Akumulasi Checklist

| Field | Value |
|---|---|
| Produk | Rutinitasku — Checklist |
| Nama pekerjaan | `checklist-persen-uid-akumulasi` |
| Versi dokumen | 1.0 |
| Tanggal | 24 November 2026 |
| Status | Menunggu persetujuan |

---

## 1. Ringkasan

Tiga perbaikan dan satu enhancement yang saling berkaitan pada modul Checklist:

1. **Sinkronisasi persentase History ↔ Card** — grafik bar di halaman History harus menampilkan persentase yang identik dengan progress bar di card grid Checklist.
2. **Item nonaktif diabaikan dari kalkulasi History** — item yang di-disable tidak boleh ikut dihitung di persentase bar graph maupun di card grid.
3. **Unique ID untuk kaitan akumulasi lintas card** — setiap item checklist mendapat ID unik, menggantikan identifikasi berbasis nama yang rawan duplikat.
4. **Tampilan jumlah akumulasi di item kecil** — item yang terkait ke item di card lain menampilkan status terkini dari item target (mis. `(45/100)`) di sebelah namanya.

---

## 2. Latar Belakang

### 2.1 Kondisi saat ini (terverifikasi dari kode)

| Fakta | Lokasi |
|---|---|
| Card grid menghitung persentase menggunakan kalkulasi `double` leaf-only, skip `isDisabled`, proporsional untuk `progress`/`countdown` | `checklist_detail_screen.dart:589-638` |
| History screen menghitung persentase menggunakan `int` flat counting (semua item + children, tanpa skip disabled) | `daily_tracker_history_screen.dart:33-55` |
| `DailyLogEntry` tidak menyimpan field `isDisabled` | `daily_model.dart:380-453` |
| Kaitan lintas card menggunakan `subjectName` (string teks) untuk identifikasi | `daily_model.dart:264-269`, `edit_item_relations_dialog.dart` |
| Item kecil dengan kaitan eksternal menampilkan ikon ⚡ saja, tanpa angka akumulasi | `checklist_tree_view.dart:346-361` |
| `HistoryBarChart` menerima `int Function(List<DailyLogEntry>)` sebagai callback | `history_bar_chart.dart:9-10` |

### 2.2 Masalah

| Masalah | Dampak |
|---|---|
| Persentase History berbeda dari Card grid | Pengguna bingung melihat angka yang berbeda untuk data yang sama |
| Item disabled ikut terhitung di History | Persentase History lebih rendah dari kenyataan (item yang sengaja di-skip tetap menambah denominator) |
| Dua item dengan nama identik di card berbeda → kaitan salah sasaran | Akumulasi nilai terakumulasi ke item yang salah |
| Tidak ada indikasi visual jumlah akumulasi di item kecil | Pengguna harus membuka card target secara manual untuk melihat totalnya |

---

## 3. Goals dan Non-Goals

### 3.1 Goals

| ID | Goal | Ukuran keberhasilan |
|---|---|---|
| G-01 | Persentase bar graph History = persentase card grid untuk data snapshot yang sama | Kalkulasi identik pada semua skenario |
| G-02 | Item disabled tidak terhitung di persentase (card maupun history) | Persentase naik saat item di-disable |
| G-03 | Setiap `SubSubjectItem` memiliki ID unik yang stabil | UUID auto-generate, persist di JSON, immutable |
| G-04 | Kaitan lintas card menggunakan ID unik | Dua item bernama sama tidak salah sasaran |
| G-05 | Data JSON lama (tanpa `id`) tetap kompatibel | Auto-assign ID saat parsing, kaitan via name sebagai fallback |
| G-06 | Item kecil menampilkan jumlah akumulasi item target | Teks `(currentValue/targetValue)` tampil di sebelah nama |

### 3.2 Non-Goals

- Mengubah cara `saveTodayLog` bekerja (snapshot tetap full tree).
- Menghapus field `linkedSubjectName` / `accumulatorItemName` / `linkedExternalItemName` (tetap dipertahankan untuk backward compat).
- Menampilkan jumlah akumulasi di card grid luar (hanya di tree view dialog).
- Mengubah logika `updateStatusFromChildren` yang sudah benar.
- Migrasi paksa file JSON lama (migrasi terjadi lazy saat file dibaca dan ditulis kembali).

---

## 4. Model Domain

### 4.1 `SubSubjectItem` (perubahan)

| Field | Tipe | Default | Keterangan |
|---|---|---|---|
| `id` (**baru**) | `String` | Auto-generated UUID | Identitas unik immutable per item |
| `linkedSubjectId` (**baru**) | `String?` | `null` | ID unik item prasyarat (card yang harus selesai) |
| `accumulatorItemId` (**baru**) | `String?` | `null` | ID unik item akumulator lokal |
| `linkedExternalItemId` (**baru**) | `String?` | `null` | ID unik item target di card lain |

Field lama `linkedSubjectName`, `accumulatorItemName`, `linkedExternalItemName` tetap dipertahankan sebagai label tampilan dan fallback lookup.

### 4.2 `DailyLogEntry` (perubahan)

| Field | Tipe | Default | Keterangan |
|---|---|---|---|
| `isDisabled` (**baru**) | `bool` | `false` | Snapshot status nonaktif saat log disimpan |

### 4.3 `ChecklistCalculationHelper` (baru)

Utilitas statis yang menjadi **satu sumber kebenaran** untuk kalkulasi persentase:

| Method | Input | Output | Deskripsi |
|---|---|---|---|
| `countTotalItems` | `List<SubSubjectItem>` | `double` | Total item leaf aktif (skip disabled, telusuri anak) |
| `countFinishedItems` | `List<SubSubjectItem>` | `double` | Item selesai aktif (proporsional untuk progress/countdown) |
| `countTotalFromLog` | `List<DailyLogEntry>` | `double` | Versi log: total item leaf aktif |
| `countFinishedFromLog` | `List<DailyLogEntry>` | `double` | Versi log: item selesai aktif (proporsional) |

### 4.4 Glosarium

| Istilah | Makna |
|---|---|
| **Leaf node** | Item checklist tanpa anak (sub_materi kosong) — satu-satunya yang dihitung dalam persentase |
| **Item disabled** | Item dengan `isDisabled = true` — dikecualikan dari seluruh kalkulasi persentase |
| **Proporsional** | Item `progress` dihitung `currentValue/targetValue` (0.0–1.0) alih-alih 0 atau 1 |
| **Kaitan akumulasi** | Hubungan di mana perubahan nilai item kecil diakumulasikan ke item besar di card lain |
| **UUID** | Identifier unik per item, auto-generated, disimpan di JSON sebagai field `id` |

---

## 5. Persistensi dan Kompatibilitas

### 5.1 JSON SubSubjectItem

```json
{
  "id": "m3x7k-9f2abc",
  "nama_materi": "Baca buku",
  "progress": "belum",
  "itemType": "progress",
  "currentValue": 30,
  "targetValue": 100,
  "isDisabled": false,
  "linkedSubjectName": "Hafalan",
  "linkedSubjectId": "m3x5a-7d1def",
  "accumulatorItemName": "Total Halaman",
  "accumulatorItemId": "m3x6b-8e2ghi",
  "linkedExternalCardName": "Ibadah",
  "linkedExternalItemName": "Jumlah Bacaan",
  "linkedExternalItemId": "m3x9c-0f3jkl",
  "sub_materi": []
}
```

Aturan kompatibilitas:
- **Field `id` hilang** → auto-generate saat `fromJson`, ditulis saat `toJson`.
- **Field `linkedXxxId` hilang** → lookup fallback via `linkedXxxName`.
- **Field `linkedXxxName` tetap ditulis** → backward compat untuk versi lama.
- Tidak ada bump versi skema.

### 5.2 JSON DailyLogEntry

```json
{
  "itemName": "Baca buku",
  "progress": "belum",
  "itemType": "progress",
  "currentValue": 30,
  "targetValue": 100,
  "isDisabled": false,
  "children": []
}
```

- **Field `isDisabled` hilang** → default `false` (backward compat).

---

## 6. Pengalaman Pengguna

### 6.1 Card Grid — Progress Bar

Tidak ada perubahan visual. Logika kalkulasi dipindahkan ke helper terpusat, hasilnya identik.

### 6.2 History Screen — Bar Chart

Persentase setiap bar kini **identik** dengan persentase card checklist untuk data yang sama. Item disabled di-skip. Item progress/countdown dihitung proporsional.

Tooltip tetap menampilkan: tanggal, persen, dan rasio selesai/total.

### 6.3 History Screen — List Entry

Tampilan `finished / total Selesai` kini menggunakan kalkulasi double. Jika bilangan bulat, tampil tanpa desimal. Jika pecahan, tampil 1 desimal.

### 6.4 Checklist Tree View — Tampilan Akumulasi

Di sebelah ikon ⚡ pada item yang terkait ke card lain, muncul teks angka akumulasi:

```
⚡ (45/100)    ← item target saat ini 45 dari target 100
```

Teks ini hanya muncul jika:
- Item memiliki kaitan eksternal aktif (`linkedExternalCardName` + `linkedExternalItemName`)
- Item target berhasil ditemukan
- Hanya di dalam dialog checklist (bukan di card grid luar)

### 6.5 Edit Item Relations Dialog

Dropdown kaitan kini menampilkan dan menyimpan ID di samping nama. UI tidak berubah secara visual — ID disimpan secara transparan di belakang layar.

---

## 7. Functional Requirements

| ID | Requirement | Prioritas | Acceptance |
|---|---|---|---|
| FR-01 | Satu fungsi kalkulasi (`ChecklistCalculationHelper`) dipakai di card grid, history, dan dialog controller | Must | Semua 3 tempat memanggil helper yang sama |
| FR-02 | `SubSubjectItem` memiliki field `id` unik auto-generated | Must | UUID valid, persist di JSON |
| FR-03 | `DailyLogEntry` memiliki field `isDisabled` | Must | Snapshot menyimpan status disabled |
| FR-04 | Item disabled tidak terhitung di persentase history bar | Must | Bar persen naik saat item di-disable |
| FR-05 | Persentase bar history = persentase card grid | Must | Test side-by-side identik |
| FR-06 | Kaitan lintas card menggunakan ID unik | Must | 2 item nama sama, kaitan tepat sasaran |
| FR-07 | Fallback ke name-based lookup jika ID null | Must | JSON lama tetap bekerja |
| FR-08 | Item kecil menampilkan jumlah akumulasi target | Should | `(currentValue/targetValue)` tampil di tree view |
| FR-09 | `HistoryBarChart` menerima `double Function(...)` | Must | Compile sukses |
| FR-10 | `fromJson` tanpa field `id` → auto-generate | Must | Migrasi otomatis tanpa crash |

---

## 8. Rencana Teknis

### 8.1 File terdampak

| Area | File |
|---|---|
| Model | `lib/features/checklist/data/models/daily_model.dart` |
| Helper (baru) | `lib/features/checklist/data/utils/checklist_calculation_helper.dart` |
| Card Grid | `lib/features/checklist/presentation/checklist_detail_screen/checklist_detail_screen.dart` |
| Dialog Controller | `lib/features/checklist/presentation/checklist_detail_screen/controllers/checklist_dialog_controller.dart` |
| History Screen | `lib/features/checklist/presentation/daily_tracker_history_screen/daily_tracker_history_screen.dart` |
| Bar Chart | `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/history_bar_chart.dart` |
| Edit Relations | `lib/features/checklist/presentation/checklist_detail_screen/widgets/edit_item_relations_dialog.dart` |
| Tree View | `lib/features/checklist/presentation/checklist_detail_screen/widgets/checklist_tree_view.dart` |
| Checklist Dialog | `lib/features/checklist/presentation/checklist_detail_screen/widgets/checklist_dialog.dart` |
| Edit History | `lib/features/checklist/presentation/daily_tracker_history_screen/widgets/edit_history_entry_sheet.dart` |

### 8.2 Urutan implementasi

1. **Model data** — Tambah `id` ke `SubSubjectItem`, `isDisabled` ke `DailyLogEntry`, dan field ID kaitan baru. Ini fondasi yang dibutuhkan semua komponen lain.
2. **Helper kalkulasi** — Buat `ChecklistCalculationHelper` sebagai utilitas terpusat.
3. **History screen + bar chart** — Ganti kalkulasi int → pakai helper double.
4. **Card grid + dialog controller** — Ganti inline functions → pakai helper.
5. **Edit relations dialog** — Update untuk menyimpan dan mengirim ID.
6. **Tree view + checklist dialog** — Tambah tampilan akumulasi.
7. **Verifikasi** — Jalankan `flutter analyze` dan tes manual.

---

## 9. Acceptance Criteria

1. Card dengan item disabled: persentase di card grid = persentase di bar history.
2. Card dengan item progress 50/100: bar history menunjukkan 50%, bukan 0% atau 100%.
3. Dua item bernama identik di card berbeda: kaitan akumulasi tepat sasaran via ID.
4. File JSON lama tanpa field `id`: item mendapat ID otomatis saat dibaca, tersimpan saat ditulis.
5. Item kecil yang terkait ke item besar: menampilkan `(currentValue/targetValue)` di tree view.
6. `flutter analyze` bersih untuk semua file yang diubah.
7. Kalkulasi persentase konsisten di 3 lokasi (card, history, dialog controller).

---

## 10. Rencana Pengujian

### 10.1 Manual

- Buat card dengan campuran: 3 item normal, 1 progress (50/100), 1 countdown (30 sisa dari 100), 1 disabled.
- Simpan Hari Ini → Lihat History → Verifikasi bar persen = card persen.
- Nonaktifkan 1 item lagi → Simpan Hari Ini → Verifikasi persentase naik.
- Buat 2 item bernama "Latihan" di 2 card berbeda → kaitkan akumulasi → verifikasi sasaran tepat.
- Buka file JSON mentah → verifikasi field `id` ada di setiap item.
- Buka dialog checklist → lihat teks akumulasi di sebelah ikon ⚡.

### 10.2 Regresi

- Buka card checklist yang sudah ada → semua item harus tampil normal.
- Progress bar harus menunjukkan angka yang sama seperti sebelum perubahan.
- History yang sudah tersimpan (tanpa `isDisabled` di log) tetap tampil normal (default false).

---

## 11. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| UUID collision | Dua item mendapat ID sama | Microsecond epoch + hash → collision probability negligible untuk penggunaan offline lokal |
| Breaking change `HistoryBarChart` callback | Pemanggil lain gagal compile | Hanya `DailyTrackerHistoryScreen` yang memanggilnya (terverifikasi dari codebase) |
| File JSON membengkak | Field `id` dan field ID kaitan baru | Tambahan ~50 byte per item, negligible |
| Data log lama tanpa `isDisabled` | Kalkulasi history lama sedikit berbeda | Acceptable: data lama menggunakan default `false`, perilaku sama seperti sebelumnya |

---

## 12. Open Questions

Tidak ada yang memblokir implementasi.

---

## 13. Dokumen Terkait

- Implementation plan: lihat artifact `implementation-plan.md`
