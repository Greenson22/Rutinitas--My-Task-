# SPEC: CardChecklist — Section Features & Markdown Bug Fix

**Status:** Ready for Agent  
**Triage Label:** `ready-for-agent`  
**PRD:** [PRD.md](./PRD.md)  
**Feature Area:** `checklist` — `ChecklistDetailScreen`, `ChecklistSection`, `DailyChecklistDialog`

---

## Problem Statement

Pengguna mengalami tiga masalah saat menggunakan **CardChecklist**:

1. **Bug:** Ketika pengguna mengaktifkan mode Markdown pada catatan sebuah card, pengaturan tersebut tidak tersimpan. Saat dialog ditutup dan dibuka kembali, catatan kembali ke mode teks biasa — seolah-olah perubahan tidak pernah terjadi.

2. **Kurangnya kontrol visibilitas seksi:** Pengguna tidak bisa menyembunyikan sebuah seksi beserta seluruh isinya tanpa harus menghapusnya. Ini menghambat pengguna yang ingin menyingkirkan seksi sementara tanpa kehilangan data.

3. **Kurangnya kontrol lipatan seksi:** Halaman detail checklist dengan banyak seksi terasa penuh dan tidak terorganisir. Pengguna tidak bisa melipat (*collapse*) isi sebuah seksi untuk merapikan tampilan, dan tidak ada pengaturan global untuk perilaku default-nya.

4. **Tidak ada perlindungan saat hapus seksi berisi:** Pengguna bisa tidak sengaja menghapus seksi yang masih memiliki item (termasuk yang tersembunyi) tanpa ada peringatan apa pun.

---

## Solution

1. **Fix Markdown:** Ketika pengguna men-toggle mode Markdown pada catatan card, perubahan tersebut langsung disimpan ke model data dan dipersistensikan ke file — sehingga status Markdown tetap terjaga meski dialog ditutup dan dibuka kembali.

2. **Sembunyikan Seksi:** Pengguna dapat menyembunyikan sebuah seksi beserta seluruh isinya dengan mengetuk ikon di header seksi. Seksi yang tersembunyi tidak tampil, namun datanya tetap aman. Pengguna dapat menampilkan kembali seksi tersembunyi kapan saja.

3. **Collapse Seksi:** Pengguna dapat melipat isi sebuah seksi dengan mengetuk header-nya atau ikon chevron di kirinya. Terdapat pengaturan global untuk menentukan apakah seksi dimulai dalam kondisi terlipat, serta apakah status lipatan per-seksi diingat antar sesi. Dua fitur ini — *sembunyikan* dan *collapse* — adalah dua hal yang berbeda.

4. **Peringatan Hapus Seksi:** Ketika pengguna mencoba menghapus seksi yang masih memiliki item (termasuk item yang tersembunyi), muncul dialog konfirmasi yang menampilkan nama seksi dan jumlah item yang akan ikut terhapus.

---

## User Stories

1. Sebagai pengguna ChecklistApp, saya ingin mode Markdown pada catatan card tersimpan secara permanen setelah saya mengaktifkannya, agar saya tidak perlu mengaktifkannya kembali setiap kali membuka dialog.
2. Sebagai pengguna ChecklistApp, saya ingin melihat status Markdown (aktif/nonaktif) tercermin dengan benar di tampilan catatan saat dialog dibuka, agar saya tahu sedang berada di mode apa.
3. Sebagai pengguna ChecklistApp, saya ingin pratinjau Markdown langsung ditampilkan saat dialog dibuka jika mode Markdown sudah aktif sebelumnya, agar saya tidak perlu mengganti mode secara manual.
4. Sebagai pengguna ChecklistApp, saya ingin menyembunyikan sebuah seksi dari tampilan checklist tanpa menghapusnya, agar saya bisa menyingkirkan seksi yang sementara tidak relevan.
5. Sebagai pengguna ChecklistApp, saya ingin menyembunyikan seksi langsung dari ikon di header seksi, agar aksinya terasa cepat dan intuitif.
6. Sebagai pengguna ChecklistApp, saya ingin seksi yang disembunyikan tidak tampil di daftar utama, agar tampilan lebih bersih.
7. Sebagai pengguna ChecklistApp, saya ingin ada cara untuk menampilkan kembali seksi yang tersembunyi, agar saya tidak kehilangan akses ke data saya.
8. Sebagai pengguna ChecklistApp, saya ingin seksi yang disembunyikan tetap memiliki data itemnya secara utuh saat ditampilkan kembali, agar tidak ada data yang hilang.
9. Sebagai pengguna ChecklistApp, saya ingin status tersembunyi sebuah seksi tersimpan ke file JSON, agar status tetap terjaga saat app ditutup dan dibuka kembali.
10. Sebagai pengguna ChecklistApp, saya ingin melipat (*collapse*) isi sebuah seksi dengan mengetuk header-nya, agar saya bisa merapikan tampilan tanpa kehilangan akses ke seksi lainnya.
11. Sebagai pengguna ChecklistApp, saya ingin melihat ikon chevron di kiri nama seksi yang menunjukkan apakah isi seksi sedang terlipat atau terbuka, agar saya langsung tahu kondisi tiap seksi.
12. Sebagai pengguna ChecklistApp, saya ingin animasi halus saat melipat atau membuka isi seksi, agar transisi tampilan terasa nyaman.
13. Sebagai pengguna ChecklistApp, saya ingin menetapkan apakah semua seksi dimulai dalam kondisi terlipat secara default, melalui halaman pengaturan app, agar tampilan checklist rapi sejak awal dibuka.
14. Sebagai pengguna ChecklistApp, saya ingin menetapkan apakah status lipatan per-seksi diingat antar sesi, melalui halaman pengaturan app, agar saya bisa memilih antara konsistensi dan kenyamanan.
15. Sebagai pengguna ChecklistApp, jika "ingat status lipatan" diaktifkan, saya ingin status terlipat/terbuka tiap seksi tersimpan ke model, agar setiap seksi tetap dalam kondisi yang saya tinggalkan.
16. Sebagai pengguna ChecklistApp, jika "ingat status lipatan" dinonaktifkan, saya ingin setiap seksi selalu dimulai dari pengaturan default global, agar tampilan selalu konsisten dan dapat diprediksi.
17. Sebagai pengguna ChecklistApp, saya ingin perbedaan antara "sembunyikan" dan "collapse" jelas — sembunyikan menghilangkan seksi dari daftar, collapse hanya melipat isinya sementara header tetap ada, agar saya tidak bingung tentang apa yang terjadi dengan data saya.
18. Sebagai pengguna ChecklistApp, saya ingin mendapat dialog peringatan sebelum menghapus seksi yang masih berisi item, agar saya tidak tidak sengaja menghapus data penting.
19. Sebagai pengguna ChecklistApp, saya ingin dialog peringatan hapus seksi menampilkan nama seksi dan jumlah total item (termasuk yang tersembunyi), agar saya tahu persis apa yang akan terhapus.
20. Sebagai pengguna ChecklistApp, saya ingin menghapus seksi yang kosong langsung tanpa dialog konfirmasi, agar aksi terasa efisien saat seksi memang benar-benar kosong.
21. Sebagai pengguna ChecklistApp, saya ingin menekan "Batal" di dialog peringatan hapus seksi untuk membatalkan penghapusan, agar saya aman dari kesalahan klik.
22. Sebagai pengguna ChecklistApp, saya ingin menekan "Hapus Semua" di dialog peringatan untuk melanjutkan penghapusan seksi beserta seluruh isinya, agar saya tetap bisa menghapus jika memang sudah yakin.
23. Sebagai pengguna ChecklistApp, saya ingin seksi yang tersembunyi (isHidden) tetap dihitung sebagai "berisi" saat cek peringatan hapus, agar item yang tersembunyi tidak luput dari perlindungan.

---

## Implementation Decisions

### 1. Perbaikan Bug: Markdown Mode Persist

Saat pengguna men-toggle Markdown melalui menu opsi catatan, controller dialog harus segera menyinkronkan nilai boolean status Markdown ke objek `DailySubject` yang bersangkutan dan memanggil callback `onDataChanged` supaya perubahan dipropagasikan ke pemanggil (halaman detail) dan akhirnya ke disk. Tanpa dua langkah ini, state hanya hidup dalam widget tree lokal.

### 2. Skema Data: `ChecklistSection`

`ChecklistSection` diperluas dengan dua field boolean baru:

- `isHidden` — menandai seksi disembunyikan dari tampilan utama (default: `false`)
- `isCollapsed` — menandai seksi terlipat (default: `false`)

Kedua field ini harus disertakan dalam serialisasi JSON (`toJson`) dan deserialisasi (`fromJson`) dengan nilai fallback `false` jika tidak ada di file lama, sehingga data lama tetap valid tanpa migrasi eksplisit.

### 3. Sembunyikan Seksi (Section Hide)

- **Render logic:** Seksi dengan `isHidden = true` difilter sebelum daftar dirender di `ChecklistDetailScreen`. Seksi tersembunyi tidak muncul sama sekali kecuali ada mode "tampilkan tersembunyi" aktif.
- **Aksi:** Tersedia aksi toggle visibilitas seksi yang dipanggil dari header seksi. Setelah toggle, `saveGroupData()` dipanggil untuk mempersistensikan perubahan.
- **Unhide:** Ada satu titik akses global di halaman detail (mis. tombol di AppBar atau area bawah layar) yang, ketika diaktifkan, menampilkan kembali semua seksi tersembunyi dengan indikator visual berbeda (opacity redup / badge "tersembunyi") sehingga pengguna bisa men-toggle kembali ke tampil.

### 4. Collapse Seksi

- **Render logic:** Seksi dirender selalu (tidak difilter), namun konten/item di bawah header tidak dirender saat `isCollapsed = true`. Implementasi menggunakan `AnimatedContainer` atau memanfaatkan `ExpansionTile` Material standar untuk menghindari boilerplate animasi manual.
- **Trigger collapse:** Ketuk pada header seksi atau ikon chevron di kiri nama seksi. Ini memicu toggle `isCollapsed` pada model, kemudian memutuskan apakah menyimpan ke model (jika "remember state" aktif) atau hanya ke state sesi (jika tidak aktif).
- **Inisialisasi state:** Saat `ChecklistDetailScreen` dimuat, setiap seksi dievaluasi:
  - Jika `remember_section_collapse_state` = `true` → gunakan nilai `section.isCollapsed` dari model (file JSON).
  - Jika `remember_section_collapse_state` = `false` → gunakan nilai `section_default_collapsed` dari `SharedPreferences`, abaikan nilai model.

### 5. Settings Global

Dua entri baru ditambahkan ke `SharedPreferences`:

| Key | Tipe | Default |
|---|---|---|
| `section_default_collapsed` | `bool` | `false` |
| `section_remember_collapse_state` | `bool` | `true` |

UI untuk kedua setting ini ditambahkan di halaman pengaturan app yang sudah ada, dalam kelompok / sub-seksi "Tampilan Checklist".

### 6. Guard Hapus Seksi

- **Kondisi:** Periksa `section.items.isNotEmpty` — item tersembunyi (`isHidden = true`) tetap dihitung.
- **Dialog:** `AlertDialog` standar Material dengan icon peringatan, judul, deskripsi yang menyebut nama seksi + jumlah total item + jumlah item tersembunyi (jika ada), serta dua tombol: Batal dan Hapus Semua.
- **Alur hapus kosong:** Jika `section.items.isEmpty`, hapus langsung tanpa dialog.
- **Penghapusan:** Setelah konfirmasi, seksi dilepas dari `currentGroup.allList` dan `saveGroupData()` dipanggil.

### 7. Modul yang Dimodifikasi

- **Model `ChecklistSection`** — Tambah field `isHidden`, `isCollapsed` beserta serialisasi/deserialisasi.
- **Controller dialog (`ChecklistDialogController`)** — Fix bug markdown persist: sync ke model + panggil `onDataChanged`.
- **Controller halaman detail (`ChecklistDetailController`)** — Tambah method: `toggleSectionHidden()`, `toggleSectionCollapsed()`, update `deleteSection()` dengan guard peringatan.
- **Halaman detail (`ChecklistDetailScreen`)** — Update render logic: filter seksi tersembunyi, collapse engine tiap seksi, inisialisasi state collapse dari settings.
- **Widget header seksi** — Tambah parameter callback dan ikon (chevron kiri, visibility kanan).
- **Halaman pengaturan app** — Tambah dua toggle setting untuk `section_default_collapsed` dan `section_remember_collapse_state`.

---

## Testing Decisions

### Apa yang membuat tes baik

Tes hanya menguji **perilaku yang terlihat dari luar** (visible widget, perubahan state pada model, pemanggilan `saveGroupData`), **bukan** detail implementasi internal seperti nama method private atau struktur widget internal. Tes tidak melakukan mock pada `setState` atau memodifikasi controller secara langsung — melainkan berinteraksi seperti pengguna: pump widget, lakukan gestur, assert hasilnya.

### Seam Pengujian

**Satu seam utama:** `ChecklistDetailScreen` via `testWidgets` — mengikuti pola yang sudah baku di `checklist_card_ticket_04_test.dart` dan `checklist_card_ticket_05_test.dart`. Ini merupakan seam tertinggi yang bisa diuji tanpa perlu setup infrastruktur tambahan (tidak butuh mock SharedPreferences karena test menyuplai `ChecklistGroup` langsung).

Untuk **Markdown bug fix**, seam adalah `DailyChecklistDialog` yang dibuka dari dalam `ChecklistDetailScreen` — interaksi via `tester.tap` pada ikon popup menu.

Untuk **model serialisasi**, seam adalah unit test murni pada `ChecklistSection.fromJson()` dan `toJson()` tanpa widget — tidak memerlukan `testWidgets`.

### Modul yang Diuji

| Modul | Jenis Tes | Pola Prior Art |
|---|---|---|
| `ChecklistSection` model | Unit test | Pola `fromJson`/`toJson` yang ada di `daily_model.dart` tests |
| `ChecklistDialogController` (via `DailyChecklistDialog`) | Widget test via `ChecklistDetailScreen` | `checklist_card_ticket_04_test.dart` |
| `ChecklistDetailController` — toggle, collapse, delete guard | Widget test via `ChecklistDetailScreen` | `checklist_card_ticket_05_test.dart`, `checklist_detail_controller_edit_delete_test.dart` |
| Settings collapse di `SharedPreferences` | Widget test dengan mock SharedPreferences | Pola baru, menggunakan `shared_preferences` fake/mock |

### Kasus Uji Utama

**Markdown Bug Fix:**
- Toggle Markdown ON → model `subject.isMarkdownEnabled` bernilai `true` setelah aksi.
- Buka kembali dialog setelah toggle ON → pratinjau Markdown ditampilkan, bukan teks biasa.
- Toggle Markdown OFF → model kembali ke `false`.

**Sembunyikan Seksi:**
- Seksi dengan `isHidden = true` tidak ada di widget tree saat dirender.
- Toggle sembunyikan → `section.isHidden` bernilai `true` + `saveGroupData` dipanggil.
- Aktifkan mode "tampilkan tersembunyi" → seksi kembali terlihat di widget tree.
- Data item seksi yang disembunyikan utuh saat ditampilkan kembali.

**Collapse Seksi:**
- Seksi dengan `isCollapsed = true` → konten item tidak ada di widget tree, header tetap ada.
- Ketuk header → konten muncul, ikon chevron berubah arah.
- Ketuk kembali → konten hilang.
- Jika "remember state" ON → `section.isCollapsed` tersimpan ke model setelah toggle.
- Jika "remember state" OFF → state collapse tidak disimpan ke model.
- Setting `section_default_collapsed = true` → semua seksi yang tidak memiliki state tersimpan dimulai terlipat.

**Guard Hapus Seksi:**
- Hapus seksi dengan items → dialog konfirmasi muncul.
- Dialog menampilkan nama seksi dan jumlah item (termasuk yang hidden).
- Tekan Batal → seksi tidak terhapus, jumlah seksi tetap sama.
- Tekan Hapus Semua → seksi dihapus dari `currentGroup.allList`.
- Hapus seksi kosong → tidak ada dialog, seksi langsung hilang.
- Seksi dengan item yang `isHidden = true` → tetap memunculkan dialog (dihitung sebagai berisi).

---

## Out of Scope

- **Reorder seksi via drag:** Urutan seksi tidak berubah sebagai bagian dari fitur ini.
- **Bulk hide/show semua seksi sekaligus:** Hanya per-seksi individual.
- **Collapse/hide per-item (DailySubject):** Fitur ini hanya untuk level **seksi** (`ChecklistSection`), bukan card individual.
- **Migrasi data lama:** Karena field baru menggunakan nilai default fallback di `fromJson`, file JSON lama tetap valid tanpa skrip migrasi.
- **Sinkronisasi settings collapse antar perangkat:** `SharedPreferences` bersifat lokal per perangkat.
- **Undo/redo untuk hapus seksi:** Hanya dialog konfirmasi, tidak ada mekanisme undo.
- **Animasi collapse yang sangat kustom:** Cukup menggunakan widget Material standar (`ExpansionTile` atau `AnimatedContainer`).

---

## Further Notes

- **Perbedaan kritis sembunyikan vs collapse** harus tercermin jelas di UI: *sembunyikan* = seksi hilang dari daftar (tidak ada trace visual), *collapse* = header tetap ada dengan indikator chevron.
- **Field `isHidden` di `ChecklistSection` vs `DailySubject`** adalah dua hal berbeda: `DailySubject.isHidden` sudah ada untuk menyembunyikan card individual, sedangkan `ChecklistSection.isHidden` yang baru ini menyembunyikan seluruh seksi. Implementasi harus memastikan keduanya tidak tertukar.
- **Interaksi remember state dengan default:** Jika pengguna pertama kali menggunakan fitur ini (tidak ada nilai `isCollapsed` di model lama), sistem harus jatuh ke nilai default global. Ini ditangani secara otomatis karena `fromJson` memberi nilai `false` untuk field yang tidak ada.
- Tes yang melibatkan `SharedPreferences` perlu menggunakan `SharedPreferences.setMockInitialValues({})` atau package `shared_preferences_mock` agar tidak bergantung pada state mesin lokal saat CI berjalan.
