# SPEC — Sinkronisasi Persentase, Unique ID Kaitan, dan Tampilan Akumulasi Checklist

## Problem Statement

Pengguna Checklist mengalami tiga masalah saat menggunakan fitur DailyTracker dan kaitan akumulasi lintas card:

1. **Angka persentase tidak konsisten.** Saat pengguna menekan "Lihat History", grafik bar menampilkan persentase yang berbeda dari progress bar di card grid. Misalnya, card menunjukkan 63% tetapi bar history menunjukkan 50%. Ini terjadi karena card menghitung secara proporsional (item progress 50/100 = 0.5) dan mengabaikan item nonaktif, sedangkan history menghitung secara flat (1 item = 1, selesai atau tidak) dan tetap menghitung item nonaktif.

2. **Item yang sengaja dinonaktifkan tetap menurunkan persentase di History.** Saat pengguna menonaktifkan sebuah item (tanda ✕), card grid sudah benar mengabaikannya dari kalkulasi. Tetapi ketika "Simpan Hari Ini" dijalankan dan History dibuka, item tersebut masih terhitung sebagai "belum selesai", menurunkan persentase.

3. **Kaitan akumulasi lintas card salah sasaran jika ada nama duplikat.** Sistem mengidentifikasi item berdasarkan nama teks. Jika pengguna memiliki dua item bernama "Latihan" di card berbeda dan mengaitkan akumulasi ke salah satunya, sistem bisa mengakumulasi ke item yang salah.

4. **Tidak ada indikasi jumlah akumulasi di item kecil.** Saat pengguna mengaitkan item kecil ke item besar di card lain, tidak ada cara melihat "sudah berapa jumlah totalnya" tanpa membuka card target secara manual.

---

## Solution

Dari perspektif pengguna:

1. **Persentase konsisten di mana-mana.** Angka di progress bar card grid dan angka di bar chart history selalu sama untuk data yang sama. Jika card menunjukkan 63%, history juga menunjukkan 63%.

2. **Item nonaktif diabaikan secara total.** Baik di card grid maupun di history, item yang dinonaktifkan tidak memengaruhi persentase sama sekali. Menonaktifkan item menyebabkan persentase naik (karena denominator berkurang).

3. **Kaitan akumulasi tepat sasaran.** Setiap item checklist memiliki identitas unik di balik layar. Dua item bernama sama di card berbeda tidak akan tertukar saat dikaitkan. Pengguna tidak perlu melakukan apa pun — ID dibuat otomatis.

4. **Jumlah akumulasi terlihat langsung.** Saat membuka dialog checklist, item kecil yang terkait ke item besar di card lain menampilkan angka terkini di sebelah namanya, misalnya ⚡ `(45/100)`.

---

## User Stories

1. As a checklist user, I want the history bar chart percentage to match the card grid percentage, so that I can trust the numbers I see are accurate.

2. As a checklist user, I want disabled items to be excluded from the history percentage calculation, so that my intentionally skipped items don't drag down my completion rate.

3. As a checklist user, I want disabled items to be excluded from the card grid percentage calculation, so that the progress bar accurately reflects only active work.

4. As a checklist user, I want progress-type items in history to be calculated proportionally (e.g., 50/100 = 50%), so that partial progress is reflected instead of only 0% or 100%.

5. As a checklist user, I want countdown-type items in history to be calculated proportionally (remaining/target), so that my countdown progress is accurately represented.

6. As a checklist user, I want only leaf nodes (items without children) to count in the percentage, so that parent items don't double-count their children.

7. As a checklist user, I want the history bar tooltip to show the correct percentage matching the card, so that the detailed view is consistent with the overview.

8. As a checklist user, I want each checklist item to have a unique identity, so that items with the same name in different cards don't get confused.

9. As a checklist user, I want the unique ID to be generated automatically when I create an item, so that I don't have to do anything extra.

10. As a checklist user, I want my existing data (without IDs) to be automatically migrated when opened, so that I don't lose any checklists or have to recreate them.

11. As a checklist user, I want cross-card accumulation links to use the unique ID instead of the item name, so that linking to "Latihan" in Card A doesn't accidentally link to "Latihan" in Card B.

12. As a checklist user, I want name-based linking to still work as a fallback for old data, so that my existing links don't break after the update.

13. As a checklist user, I want to see the current accumulated value of the target item next to my linked item's name (e.g., ⚡ `(45/100)`), so that I can track the total without opening the other card.

14. As a checklist user, I want the accumulation display to update in real-time when I change values, so that I always see the latest total.

15. As a checklist user, I want the accumulation display to only appear inside the checklist dialog (not on the card grid), so that the grid cards stay clean and uncluttered.

16. As a checklist user, I want the history list entries to show the finished/total ratio using the same calculation as the card, so that the numbers in the list match the bar chart above it.

17. As a checklist user, I want the "Simpan Hari Ini" snapshot to capture whether each item is disabled, so that the history accurately reflects which items were active on that day.

18. As a checklist user, I want historical data saved before this update (without `isDisabled` in the log) to still display correctly, so that my old history entries aren't corrupted.

19. As a checklist user, I want the edit relations dialog to store both the ID and name of linked items, so that the link is robust (ID) but also human-readable (name).

20. As a checklist user, I want the internal accumulator linking (within the same card) to also use unique IDs, so that same-name items within one card don't conflict.

21. As a checklist user, I want the prerequisite card linking (linkedSubjectName) to also use unique IDs, so that prerequisite resolution is unambiguous.

22. As a checklist user, I want JSON export/import to include the new `id` fields, so that moving data between devices preserves all links.

23. As a checklist user, I want the "Edit Raw JSON" dialog to show the `id` field, so that advanced users can inspect and verify item identities.

---

## Implementation Decisions

### Kalkulasi Persentase Terpusat

- Satu kelas utilitas statis (`ChecklistCalculationHelper`) menjadi satu-satunya sumber kebenaran untuk semua kalkulasi persentase di seluruh aplikasi.
- Kelas ini menyediakan empat method statis: dua untuk `SubSubjectItem` (dipakai card grid dan dialog controller) dan dua untuk `DailyLogEntry` (dipakai history screen).
- Logika kalkulasi: hanya leaf nodes (item tanpa anak) yang dihitung. Item disabled diskip. Item `progress` dihitung proporsional (`currentValue / targetValue`, clamped 0–1). Item `countdown` dihitung proporsional (`(targetValue - currentValue) / targetValue`, clamped 0–1). Item `normal` dihitung 0 atau 1.
- Semua fungsi kalkulasi inline yang tersebar di card grid screen, dialog controller, dan history screen diganti dengan pemanggilan ke helper ini.

### Unique ID per Item

- Setiap `SubSubjectItem` mendapat field `id` bertipe `String`, auto-generated saat konstruktor dipanggil jika tidak disuplai.
- UUID dibuat tanpa package eksternal: format `microsecondEpoch_base36 + identityHash_base36`. Cukup unik untuk konteks lokal offline.
- `fromJson`: jika field `id` tidak ada di JSON → constructor auto-generates. `toJson`: selalu menulis `id`. `clone`: mempertahankan `id` yang sama.

### Field ID Kaitan Baru

- Tiga field ID baru ditambahkan ke `SubSubjectItem`: `linkedSubjectId`, `accumulatorItemId`, `linkedExternalItemId`.
- Field name lama (`linkedSubjectName`, `accumulatorItemName`, `linkedExternalItemName`) dipertahankan untuk backward compat dan sebagai label tampilan.
- Semua lookup kaitan menggunakan strategi **ID-first, name-fallback**: cari by `id` terlebih dahulu; jika null, fallback ke pencarian by `name`.
- `toJson` selalu menulis kedua field (id dan name).
- Edit relations dialog menyimpan dan mengirim ID bersamaan saat pengguna memilih target.

### `isDisabled` di DailyLogEntry

- Field `isDisabled` bertipe `bool` (default `false`) ditambahkan ke `DailyLogEntry`.
- `fromSubSubjectItem` menyalin `isDisabled` dari `SubSubjectItem`.
- `fromJson`: field hilang → `false` (backward compat).
- `toJson`: selalu menulis `isDisabled`.

### Callback Tipe di HistoryBarChart

- Signature callback berubah dari `int Function(List<DailyLogEntry>)` ke `double Function(List<DailyLogEntry>)`.
- Satu-satunya pemanggil (`DailyTrackerHistoryScreen`) diupdate bersamaan.

### Tampilan Akumulasi di Tree View

- `ChecklistTreeView` menerima parameter callback opsional baru: `resolveExternalAccumulationText` bertipe `String? Function(SubSubjectItem)?`.
- Callback ini diprovide oleh `DailyChecklistDialog`, yang melakukan lookup ke `allAvailableSubjects` untuk menemukan item target dan mengembalikan teks format `(currentValue/targetValue)`.
- Teks ditampilkan di sebelah ikon ⚡ (bolt) yang sudah ada, hanya di mode non-edit, hanya jika item memiliki kaitan eksternal aktif dan target ditemukan.

### Tidak ada Migrasi Paksa

- Tidak ada skrip migrasi atau bump versi skema.
- Migrasi terjadi secara lazy: saat file JSON lama dibaca, item tanpa `id` mendapat ID auto-generated; saat ditulis kembali, `id` tersimpan.
- Kaitan lama yang hanya punya `name` tanpa `id` tetap bekerja via fallback lookup.

---

## Testing Decisions

### Apa yang Membuat Test Bagus

Test harus memverifikasi **perilaku eksternal** (input → output), bukan detail implementasi internal. Untuk fitur ini, test yang baik:
- Mengonstruksi data model (`SubSubjectItem`, `DailyLogEntry`) dengan skenario spesifik
- Memanggil fungsi publik (helper kalkulasi, `fromJson`, `toJson`)
- Assert hasil output tanpa mengintip state internal

### Seam Uji

#### Seam 1: `ChecklistCalculationHelper` (Seam Utama)

Seam tertinggi dan terbersih. Pure static functions tanpa dependency. Skenario test:

- Semua item normal selesai → 100%
- Campuran normal selesai dan belum → persentase tepat
- Item `progress` 50/100 → kontribusi 0.5, bukan 0 atau 1
- Item `countdown` sisa 30 dari target 100 → kontribusi 0.7
- Item `isDisabled` → diskip dari total dan finished
- Item dengan anak (nested) → hanya leaf yang dihitung
- Item disabled di level parent → anak-anak juga diskip
- Semua varian di atas diuji untuk **kedua** versi: `SubSubjectItem` dan `DailyLogEntry`
- **Kunci acceptance**: hasil `countTotalItems`/`countFinishedItems` pada `SubSubjectItem` harus **identik** dengan `countTotalFromLog`/`countFinishedFromLog` pada `DailyLogEntry` yang di-snapshot dari `SubSubjectItem` yang sama

#### Seam 2: `SubSubjectItem.fromJson` / `toJson` Round-Trip

- JSON tanpa field `id` → `fromJson` auto-generates ID, `toJson` menulis ID
- JSON dengan field `id` → ID dipertahankan
- JSON dengan `linkedSubjectName` tapi tanpa `linkedSubjectId` → backward compat
- JSON dengan kedua field → kedua field tersimpan
- `clone()` mempertahankan ID yang sama

#### Seam 3: `DailyLogEntry.fromSubSubjectItem`

- Item dengan `isDisabled = true` → snapshot memiliki `isDisabled = true`
- Item dengan `isDisabled = false` → snapshot memiliki `isDisabled = false`
- Children disabled → children snapshot juga disabled

#### Seam 4: `DailyLogEntry.fromJson` / `toJson` Round-Trip

- JSON tanpa `isDisabled` → default `false`
- JSON dengan `isDisabled: true` → `true`
- Round-trip: `fromJson(toJson(entry))` identik

### Prior Art

Proyek ini belum memiliki test coverage yang signifikan untuk modul checklist. Test baru akan menjadi fondasi. Pola test mengikuti Flutter standard: file di `test/features/checklist/...`, menggunakan `flutter_test`.

---

## Out of Scope

- **Mengubah cara `saveTodayLog` bekerja.** Snapshot tetap full tree; filtering terjadi saat kalkulasi, bukan saat penyimpanan.
- **Menghapus field name lama** (`linkedSubjectName`, `accumulatorItemName`, `linkedExternalItemName`). Field ini dipertahankan indefinitely untuk backward compat.
- **Menampilkan jumlah akumulasi di card grid luar.** Hanya di tree view dalam dialog — card grid tetap bersih.
- **Widget test untuk UI.** Perubahan UI bersifat render-only dari data yang sudah diuji di seam kalkulasi.
- **Migrasi paksa file JSON lama.** Migrasi terjadi lazy saat file dibaca dan ditulis kembali.
- **Mengubah logika `updateStatusFromChildren`.** Fungsi ini sudah benar dan tidak terdampak.
- **Sinkronisasi cloud, notifikasi, atau subtask.**
- **Bump versi skema JSON.**
- **Menambah package `uuid` external.** UUID dibuat secara mandiri.

---

## Further Notes

- **Backward compatibility adalah prioritas tertinggi.** Tidak ada data pengguna yang boleh rusak atau hilang. Setiap field baru memiliki default yang aman.
- **Perubahan breaking pada `HistoryBarChart`** (callback `int` → `double`) aman karena widget ini hanya dipanggil dari satu lokasi (`DailyTrackerHistoryScreen`), terverifikasi dari codebase.
- **UUID collision risk** negligible untuk penggunaan offline lokal. Format microsecond-epoch + identity-hash menghasilkan kombinasi unik yang cukup untuk ribuan item.
- **Urutan implementasi yang disarankan**: Model data → Helper kalkulasi → History screen → Card grid → Dialog controller → Edit relations → Tree view. Ini mengikuti dependency graph: model paling dasar, lalu helper, lalu consumer.
- Dokumen PRD lengkap tersedia di `docs/checklist-persen-uid-akumulasi/PRD.md` dalam folder yang sama.
