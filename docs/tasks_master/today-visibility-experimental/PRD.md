# PRD — Visibilitas Hari Ini & Rollout Eksperimental Task Master New

| Field | Value |
|---|---|
| Produk | Rutinitasku — Task Master |
| Nama pekerjaan | `today-visibility-experimental` |
| Versi dokumen | 1.0 |
| Tanggal | 18 November 2026 |
| Status | Disetujui untuk implementasi |
| Bergantung pada | `docs/tasks_master/PRD.md` v1.0, tiket 15, tiket 16 |
| Menggantikan | Bagian 6.3, 6.5, dan 9.4 `docs/tasks_master/PRD.md` yang bertentangan |

---

## 1. Ringkasan

Tiga perubahan yang saling bergantung:

1. **Visibilitas Hari Ini per tugas** — setiap tugas punya pengaturan sendiri untuk tampil di daftar “Hari Ini”, terlepas dari `isActive`.
2. **Rollout eksperimental** — `task_master_new` tidak lagi menjadi default lewat konstanta compile-time, tetapi lewat saklar runtime di “Fitur Eksperimental”. Default mati berarti modul lama dipakai. Aktif berarti modul baru dipakai.
3. **Konsolidasi Pengaturan** — entri “Pengaturan folder & enkripsi” dihapus dari sheet Advanced `task_master_new`; satu-satunya pintu adalah Settings di sidebar/drawer.

---

## 2. Latar Belakang

### 2.1 Kondisi saat ini (terverifikasi dari kode)

| Fakta | Lokasi |
|---|---|
| `taskMasterUseNewModule = true` (konstanta compile-time) | `lib/core/config/task_master_rollout.dart` |
| Saklar sudah ada di Settings: “Fitur Eksperimental” → “Tampilkan Random Generator” | `lib/core/presentation/widgets/settings_dialog.dart:422` |
| Daftar Hari Ini = tugas aktif yang punya target harian ATAU punya hitungan hari ini | `lib/features/task_master_new/domain/operations/dashboard_summary.dart` |
| Legacy tidak punya daftar Hari Ini (hanya grid kategori + dialog) | `lib/features/task_master/...` |
| `TaskCategory.toJson`/`TaskItem.toJson` legacy membuang field tak dikenal (`history`, `kind`, `sortOrder`) | `lib/features/task_master/data/models/task_model.dart` |
| Sheet Advanced berisi Editor JSON + Pengaturan folder & enkripsi | `lib/features/task_master_new/presentation/widgets/task_master_advanced_sheet.dart` |
| Belum ada test untuk `collectTodayTasks` | `test/features/...` |

### 2.2 Masalah

| Masalah | Dampak |
|---|---|
| Tidak bisa menyembunyikan tugas bertarget dari Hari Ini | Daftar penuh tugas yang tidak relevan hari itu |
| Tidak bisa memunculkan tugas tanpa target ke Hari Ini | Tugas penting baru terlihat setelah increment pertama |
| Switch modul masih compile-time | Tidak bisa diuji pengguna, rollback butuh build ulang |
| Legacy menghapus field baru saat menyimpan | Risiko kehilangan riwayat jika pengguna mematikan saklar |
| Pengaturan tersedia di dua tempat | Dua sumber kebenaran UX, membingungkan |

---

## 3. Goals dan Non-Goals

### 3.1 Goals

| ID | Goal | Ukuran keberhasilan |
|---|---|---|
| G-01 | Visibilitas Hari Ini dapat diatur per tugas dan bertahan setelah restart | 100% round-trip mapper |
| G-02 | Perilaku default tidak berubah untuk pengguna lama | `auto` = aturan lama |
| G-03 | Modul Task Master dapat diganti lewat UI tanpa build ulang | Saklar persist di SharedPreferences |
| G-04 | Pergantian modul tidak menghilangkan riwayat | Field baru lolos round-trip legacy |
| G-05 | Hanya satu modul yang menulis file | Guard runtime `legacyWritesEnabled` |
| G-06 | Pengaturan hanya diakses dari sidebar Settings | Tidak ada jalur kedua di `task_master_new` |

### 3.2 Non-Goals

- Menambah daftar “Hari Ini” ke modul legacy.
- Menghapus modul legacy (tiket 16 ditunda).
- Mengubah `schemaVersion` (tetap 2; field baru aditif dan opsional).
- Sinkronisasi cloud, notifikasi, subtask.
- Menyeragamkan Settings legacy; legacy tetap memakai dialognya sendiri saat menjadi fallback.

---

## 4. Model Domain

### 4.1 `TodayVisibility`

| Nilai | Arti | Perilaku di Daftar Hari Ini |
|---|---|---|
| `auto` (default) | Ikuti aturan lama | Tampil jika `targetDaily > 0`, atau `kind == progress && targetTotal > 0`, atau `countToday > 0` |
| `always` | Selalu tampil | Tampil selama tugas aktif dan kategorinya tidak tersembunyi |
| `never` | Sembunyikan | Tidak pernah tampil, walau punya target/aktivitas |

Aturan tetap:

- `isActive == false` → tidak pernah tampil, apa pun `todayVisibility`-nya.
- Kategori `isHidden` → tetap difilter di luar visibilitas tugas.
- Ringkasan dashboard tidak berubah karena visibilitas tugas. Tugas `always` tanpa target menyumbang 0 pada “Target tercapai”.
- Tugas `always` yang `countToday == 0` tetap menampilkan status “Tanpa target” dan tombol increment.

Alasan tri-state ada di `ADR-0001-tri-state-today-visibility.md`.

### 4.2 `Task` (tambahan)

| Field | Tipe | Default |
|---|---|---|
| `todayVisibility` | `TodayVisibility` | `auto` |

`copyWith` dan kesetaraan entity ikut memperhitungkan field ini.

### 4.3 Glosarium

| Istilah | Makna |
|---|---|
| **Tampil di Hari Ini** | Pengaturan per tugas: Otomatis / Selalu / Sembunyikan |
| **Saklar Eksperimental** | Preferensi runtime yang mengaktifkan fitur belum stabil |
| **Passthrough** | Menyimpan dan menulis kembali field JSON yang tidak dipahami model |
| **Satu penulis** | Hanya satu modul Task Master yang boleh menulis `my_tasks.json` pada satu waktu |

---

## 5. Persistensi dan Kompatibilitas

### 5.1 JSON v2

```json
{
  "name": "Push up",
  "isActive": true,
  "todayVisibility": "always",
  "showInToday": true
}
```

- `todayVisibility` adalah sumber kebenaran.
- `showInToday` adalah cermin legacy, hanya ditulis untuk `always` (`true`) dan `never` (`false`). `auto` tidak menulis field ini.
- Field hilang → `auto`.
- Bila hanya `showInToday` ada: `true` → `always`, `false` → `never`.
- Nilai `todayVisibility` yang tidak dikenal → `auto` + catatan `debugPrint`.
- Tidak ada bump `schemaVersion`.

### 5.2 Legacy passthrough

`TaskCategory` dan `TaskItem` menyimpan `Map<String, dynamic> _unknown` berisi semua key yang tidak mereka kenali, lalu menulisnya kembali pada `toJson()`. Ini melindungi `history`, `kind`, `sortOrder`, `todayVisibility`, dan `showInToday`.

Keterbatasan yang diterima dan wajib disebut di dialog konfirmasi:

- Legacy tetap me-reset `countToday` berbasis string tanggal dan tidak menulis `history` hari ini.
- Mengedit tugas dari legacy dapat membuat `history[today]` tidak sinkron sampai modul baru dibuka lagi dan menghitung ulang dari `countToday`.

### 5.3 Satu penulis

| Saklar | Pembaca | Penulis |
|---|---|---|
| Mati | Legacy (utama), new hanya untuk diagnostik | Legacy |
| Hidup | New | New saja; legacy read-only |

Tidak ada mode dua penulis. Pelanggaran dianggap bug.

---

## 6. Pengalaman Pengguna

### 6.1 Form tugas

Lokasi: `lib/features/task_master_new/presentation/widgets/task_form_dialog.dart`.

Tambahan di bawah “Target harian”:

- Label: **Tampil di Hari Ini**
- Kontrol: `SegmentedButton` atau dropdown dengan tiga opsi:
  - `Otomatis` — “Mengikuti target harian atau aktivitas hari ini.”
  - `Selalu` — “Selalu tampil selama tugas aktif.”
  - `Sembunyikan` — “Tidak pernah tampil di daftar Hari Ini.”
- Default `Otomatis` untuk tugas baru.

### 6.2 Aksi cepat

- Menu baris di `TodayTaskTile` dan tile di `CategoryDetailScreen`: item **Tampil di Hari Ini** dengan tiga pilihan bertanda centang.
- Aksi massal di `CategoryDetailScreen`: **Visibilitas Hari Ini** → submenu Otomatis / Selalu / Sembunyikan.
- Perubahan visibilitas tidak boleh memicu reload file, hanya `setState`/notify pada controller.

### 6.3 Daftar Hari Ini

- `collectTodayTasks` menerapkan aturan 4.1.
- Urutan tetap berdasarkan `sortOrder` kategori lalu tugas.
- Header “Hari Ini — N tugas” menghitung ulang seketika.
- Empty state `EmptyTodayTasksView` ditambah teks: “Atur ‘Tampil di Hari Ini’ pada tugas untuk memunculkannya di sini.”
- Tidak ada badge khusus untuk `always`; label status yang ada tetap dipakai.

### 6.4 Settings — Fitur Eksperimental

Tambahan item di section yang sudah ada (`Icons.science_outlined`, deep purple):

**Task Master New** — “Gunakan modul Task Master baru yang sedang diuji. Perubahan berlaku setelah aplikasi dimulai ulang.”

Alur aktifkan:

1. Dialog konfirmasi berisi ringkasan fitur baru dan peringatan bahwa ini eksperimental.
2. Set `task_master_use_new_module = true`.
3. SnackBar: “Task Master New akan aktif setelah aplikasi dimulai ulang.”

Alur matikan:

1. Dialog konfirmasi dengan peringatan: riwayat baru tersimpan di file v2; modul lama dapat membacanya tetapi tidak menampilkannya; detail tertentu bisa tidak sinkron bila diubah dari modul lama.
2. Set key `false`.
3. SnackBar restart.

### 6.5 Promo sekali-jalan

Dialog muncul saat Task Master dibuka bila semua benar:

- `task_master_use_new_module == false`
- `<baseDir>/mytask/my_tasks.json` memiliki `schemaVersion: 2`
- `seen_task_master_new_promo != true`

Isi: “Anda pernah memakai Task Master New. Aktifkan kembali?” Aksi: **Aktifkan Sekarang**, **Nanti**. Keduanya menulis `seen_task_master_new_promo = true`.

### 6.6 Advanced

- `TaskMasterAdvancedSheet` hanya berisi “Editor JSON mentah”.
- `_AdvancedAction` tinggal `rawJson`.
- `_openSettings()` dan dependensi `StorageService` pada `TaskMasterNewScreen` dihapus bila tidak dipakai jalur lain.
- Settings tetap dapat dibuka dari `DrawerMenu`.

---

## 7. Functional Requirements

| ID | Requirement | Prioritas | Acceptance |
|---|---|---|---|
| FR-01 | `Task.todayVisibility` dengan default `auto` | Must | Field hilang → auto |
| FR-02 | Mapper menulis `todayVisibility` + `showInToday` | Must | Round-trip v2 identik |
| FR-03 | `collectTodayTasks` menghormati tri-state | Must | Matriks visibilitas × target/aktivitas lulus |
| FR-04 | Tugas nonaktif dan kategori tersembunyi tetap dikecualikan | Must | Test regresi |
| FR-05 | Form tugas memiliki kontrol tri-state | Must | Tersimpan dan tampil kembali |
| FR-06 | Aksi cepat per baris | Must | Perubahan langsung terlihat |
| FR-07 | Aksi massal visibilitas | Should | Semua tugas terpilih berubah |
| FR-08 | Ringkasan dashboard tidak terpengaruh | Must | Angka sama sebelum/sesudah toggle |
| FR-09 | Saklar runtime `task_master_use_new_module` default `false` | Must | Fresh install → legacy |
| FR-10 | `TaskMasterEntry` membaca saklar saat dibangun | Must | Ganti saklar + restart → layar berganti |
| FR-11 | `legacyWritesEnabled` diturunkan dari saklar runtime | Must | Tidak ada dua penulis |
| FR-12 | UI saklar di Fitur Eksperimental | Must | Muncul, persist, ada konfirmasi |
| FR-13 | Legacy passthrough field tak dikenal | Must | Simpan dari legacy → `history` utuh |
| FR-14 | Dialog promo sekali-jalan | Should | Muncul sekali, preferensi tersimpan |
| FR-15 | Tile Pengaturan dihapus dari Advanced | Must | Sheet hanya satu item |
| FR-16 | Tidak ada jalur Settings kedua di `task_master_new` | Must | Grep dan widget test |
| FR-17 | `docs/tasks_master/ROLLBACK.md` diperbarui | Must | Prosedur via saklar, bukan build |

---

## 8. Rencana Teknis

### 8.1 File terdampak

| Area | File |
|---|---|
| Domain | `task_master_new/domain/entities/today_visibility.dart` (baru), `task.dart` |
| Operasi | `task_master_new/domain/operations/dashboard_summary.dart` |
| Data | `task_master_new/data/mappers/task_master_mapper.dart` |
| Legacy | `features/task_master/data/models/task_model.dart` |
| Presentasi new | `task_form_dialog.dart`, `today_task_tile.dart`, `category_detail_screen.dart`, `task_master_screen.dart`, `task_master_advanced_sheet.dart` |
| Rollout | `core/config/task_master_rollout.dart` menjadi pembaca preferensi; `core/presentation/widgets/task_master_entry.dart` |
| Settings | `core/presentation/widgets/settings_dialog.dart` |
| Guard legacy | `features/task_master/presentation/controllers/task_master_controller.dart`, `features/task_master/presentation/screens/task_master_screen.dart` |
| Dokumen | `docs/tasks_master/ROLLBACK.md`, `docs/tasks_master/PARITY_QA.md` |

### 8.2 Kunci preferensi

| Key | Tipe | Default |
|---|---|---|
| `task_master_use_new_module` | bool | `false` |
| `seen_task_master_new_promo` | bool | `false` |

### 8.3 Urutan implementasi

1. `TodayVisibility` + mapper + test. Data aman lebih dulu.
2. Legacy passthrough + test round-trip.
3. Filter Hari Ini + UI form/aksi + test widget.
4. Rollout runtime + entry + guard tulis legacy.
5. Settings switch + dialog promo.
6. Hapus jalur Settings dari Advanced.
7. Perbarui `ROLLBACK.md` dan `PARITY_QA.md`, lalu QA manual.

### 8.4 Dampak ke tiket lama

| Tiket | Dampak |
|---|---|
| 15 — Parity QA dan switch | Digantikan; switch menjadi runtime dan default mati |
| 16 — Hapus modul lama | Ditunda; legacy dipertahankan sebagai fallback |

---

## 9. Acceptance Criteria

1. Tugas `never` tidak muncul di Hari Ini walau punya target dan hitungan.
2. Tugas `always` tanpa target dan tanpa hitungan muncul di Hari Ini.
3. Tugas `auto` berperilaku persis seperti sebelum perubahan.
4. Tugas nonaktif tidak muncul apa pun visibilitasnya.
5. Ringkasan dashboard identik sebelum dan sesudah mengubah visibilitas.
6. Visibilitas bertahan setelah restart dan setelah export/import Data Center.
7. Fresh install tanpa preferensi memakai legacy.
8. Mengaktifkan saklar lalu restart memakai modul baru; mematikan lalu restart memakai legacy.
9. Saat legacy aktif, modul baru tidak menulis file; saat baru aktif, legacy tidak menulis.
10. Menyimpan dari legacy tidak menghapus `history`, `kind`, `sortOrder`, atau `todayVisibility`.
11. Sheet Advanced hanya berisi “Editor JSON mentah”; Settings hanya dari drawer.
12. Dialog promo muncul maksimal sekali.
13. `flutter analyze` bersih untuk file yang diubah; seluruh unit dan widget test baru lulus.

---

## 10. Rencana Pengujian

### 10.1 Unit

- Mapper: `todayVisibility` valid, tidak valid, dan hilang; migrasi dari `showInToday` saja; round-trip termasuk field tak dikenal.
- Legacy: `toJson` mempertahankan `history`, `kind`, `sortOrder`, `todayVisibility`, dan field acak.
- `collectTodayTasks`: matriks 3 visibilitas × (target, tanpa target, ada aktivitas) × aktif/nonaktif × kategori tersembunyi.
- `legacyWritesEnabled` mengikuti preferensi dengan fake `SharedPreferences`.

### 10.2 Widget

- Form tugas menyimpan tri-state.
- Menu baris dan aksi massal mengubah visibilitas.
- Daftar Hari Ini bereaksi tanpa reload.
- Settings: toggle eksperimental menulis preferensi dan menampilkan notice restart.
- Advanced sheet hanya memiliki satu tile.
- Dialog promo muncul sekali.

### 10.3 Manual

- Android dan Linux: ganti modul, restart, buka Hari Ini, edit dari legacy, kembali ke new.
- Enkripsi aktif saat berganti modul.
- Export → aktifkan legacy → import → kembali ke new.

---

## 11. Risiko

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Legacy tetap merusak `history[today]` | Riwayat tidak akurat sementara | Passthrough + peringatan + hitung ulang saat new dibuka |
| Pengguna bingung kembali ke UI lama | Kehilangan konteks | Dialog promo sekali-jalan |
| `TaskMasterEntry` menjadi async | Kedipan loading | Loader ringan, cache preferensi saat startup |
| Preferensi tidak terbaca di test | Gagal acak | Injeksi fake `SharedPreferences` |
| Duplikasi Settings | Dua sumber kebenaran | Hapus jalur Advanced, test regresi |

---

## 12. Open Questions

Tidak ada yang memblokir. Dua detail diputuskan saat implementasi:

1. Mekanisme “Muat Ulang Sekarang” (restart proses) atau hanya instruksi manual.
2. Apakah `showInToday` ditulis juga untuk `auto` demi pembaca pihak ketiga — default: tidak.

---

## 13. Dokumen Terkait

- `ADR-0001-tri-state-today-visibility.md` — alasan tri-state alih-alih boolean.
- `tickets/17-visibilitas-hari-ini.md`
- `tickets/18-saklar-eksperimental-task-master-new.md`
- `tickets/19-konsolidasi-pengaturan-advanced.md`
- `docs/tasks_master/ROLLBACK.md` wajib diperbarui pada tiket 18.
