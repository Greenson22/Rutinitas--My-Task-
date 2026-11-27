# PRD: Perbaikan Reorder Hari Ini, Folder Bertingkat My Documents, Tautan Berkas Checklist & Pembaruan Tentang

> **Status:** Draft — siap implementasi
> **Tanggal:** 2026-11-27
> **Fitur Target:** Task Master New · My Documents · My Checklist · Tentang Aplikasi
> **Referensi Existing:** `task_master_screen.dart`, `task_master_mapper.dart`, `document_detail_screen.dart`, `documents_controller.dart`, `edit_item_relations_dialog.dart`, `checklist_tree_view.dart`, `about_page.dart`

---

## 1. Problem Statement

Ada lima masalah/perubahan yang diminta:

1. **Urutan manual "Hari Ini" tidak tersimpan.** Di Task Master New, user bisa masuk mode urut lalu menggeser tugas, tetapi urutan itu hanya hidup di `setState` (`task_master_screen.dart:439-451`). Tidak ada pemanggilan repository/JSON, dan `_todaySortMode` selalu kembali ke `defaultOrder` saat layar dibangun ulang. Setiap keluar-masuk layar atau restart aplikasi, urutan hilang.

2. **My Documents hanya dua level.** Struktur saat ini: Seksi → Group → file. Semua file group berada langsung di `my_documents/<groupId>/`, dan `DocumentDetailScreen` mengabaikan direktori (`_loadPhysicalFiles` hanya `whereType<File>()`). User tidak bisa membuat folder, apalagi folder di dalam folder. Selain itu nama file sama di folder berbeda belum punya konsep folder; export juga memakai basename sehingga berpotensi menimpa file lain.

3. **Ikon folder/group terbatas free-text emoji.** Ikon group disimpan sebagai string emoji bebas (`DocumentGroup.icon`, default `📁`) dan diketik manual, rawan salah ketik dan tidak konsisten.

4. **My Documents masih punya aksi Ekspor.** Menu per-file dan massal masih memakai `FilePicker.getDirectoryPath()` + copy. User ingin aksi Ekspor dihapus dan digantikan "Bagikan Berkas"; folder juga harus bisa dibagikan sekaligus.

5. **Checklist item tidak bisa dikaitkan ke berkas dokumen.** `SubSubjectItem` hanya punya relasi ke card/item checklist lain (`linkedSubjectId`, `accumulatorItemId`, `linkedExternalItemId`). Tidak ada field/UI untuk menautkan satu berkas dari My Documents, membukanya, dan melepas kaitannya.

6. **Card DailyTracker terlalu ramai.** Card menampilkan tombol "Simpan Hari Ini" + "Reset Hari Baru" berdampingan, lalu "Lihat History" full-width jauh di bawahnya. Tombol Reset di card dianggap duplikat karena reset sudah tersedia di dalam dialog checklist ("Reset Progress" / "Reset Total Checklist"). Yang diminta: hapus Reset Hari Baru dari card, dan letakkan Lihat History tepat di bawah Simpan Hari Ini dengan jarak rapat.

7. **Halaman Tentang sudah usang.** Email kontak masih `frendydev1@gmail.com`. Daftar "Fitur Aplikasi" tidak mencerminkan fitur baru (folder bertingkat, tautan berkas, collapse/hide seksi, color wheel, stacked history, visibilitas Hari Ini, dll.).

---

## 2. Solution

Lima workstream yang saling independen secara teknis:

### WS1 — Persistensi Urutan Manual Hari Ini
- Pindahkan sumber kebenaran urutan custom dari state widget ke **`TaskMasterData` schema v3** (`todaySortMode` + `todayOrder`).
- Urutan Hari Ini **independen** dari `Task.sortOrder` (urutan di Category Detail).
- Tugas baru otomatis masuk ke akhir urutan; ID yang sudah tidak ada dibersihkan saat load.
- Mode sort terakhir juga ikut tersimpan, sehingga setelah restart tampilan kembali seperti terakhir diatur.

### WS2 — Folder Bertingkat di My Documents
- Group tetap akar; di dalam group ada **folder bersarang tanpa batas** yang dipetakan ke subdirektori fisik.
- Navigasi **drill-down** dengan breadcrumb; folder selalu di atas file.
- Nama file bentrok di folder yang sama **auto-rename** `nama (1).ext`, `nama (2).ext`, dst. (berlaku saat impor dan saat ubah nama).
- Ikon group dan folder memakai **picker emoji terkurasi** (bukan free-text).
- Aksi **Ekspor dihapus** dari My Documents; **Bagikan Berkas** dipertahankan. Folder bisa dibagikan sebagai **ZIP seluruh subtree** dengan struktur terjaga.
- File lama tetap di root group (layar group) tanpa migrasi. Pemindahan file bisa lintas group + folder.

### WS3 — Tautan Berkas Dokumen pada Item Checklist
- `SubSubjectItem` mendapat tiga field tautan dokumen (groupId, relative path, nama tampilan).
- Penautan & pelepasan dilakukan di dialog **"Ubah Item & Hubungan Lintas Data"**.
- Entri **"Buka Berkas"** muncul di menu titik tiga item (saat edit mode), hanya jika item punya tautan.
- Item yang tertaut menampilkan indikator **📎**.
- Rename/move dari dalam aplikasi memperbarui tautan otomatis; hapus dari dalam aplikasi melepas tautan otomatis. Berkas hilang karena sebab eksternal ditandai "Berkas tidak ditemukan".

### WS4 — Layout Tombol DailyTracker
- Hapus tombol **"Reset Hari Baru"** dari card (fungsinya sudah ada di dialog checklist).
- **"Simpan Hari Ini"** full-width di atas, **"Lihat History"** full-width tepat di bawahnya, jarak 6px.

### WS5 — Pembaruan Halaman Tentang
- Ganti email kontak menjadi `frendyrikalgerung@gmail.com`.
- Tulis ulang daftar Fitur Aplikasi secara komprehensif, hanya fitur final yang terlihat user.

---

## 3. User Stories

1. Sebagai pengguna Task Master, saya ingin urutan manual di Hari Ini tetap sama setelah saya keluar-masuk layar atau menutup aplikasi.
2. Sebagai pengguna Task Master, saya ingin tugas yang baru ditambahkan muncul di akhir urutan manual saya, bukan mengacak urutan yang sudah saya atur.
3. Sebagai pengguna Task Master, saya ingin mode sort terakhir yang saya pilih tetap aktif saat aplikasi dibuka kembali.
4. Sebagai pengguna My Documents, saya ingin membuat folder di dalam group, dan folder lagi di dalam folder tanpa batas kedalaman.
5. Sebagai pengguna My Documents, saya ingin melihat breadcrumb `Group / Folder / Subfolder` dan kembali dengan tombol back.
6. Sebagai pengguna My Documents, saya ingin menyimpan dua file dengan nama sama di folder berbeda tanpa saling menimpa.
7. Sebagai pengguna My Documents, saya ingin file dengan nama bentrok di folder yang sama otomatis diberi akhiran `(1)` tanpa dialog tambahan.
8. Sebagai pengguna My Documents, saya ingin mengganti ikon group/folder lewat picker emoji sehingga tampilan konsisten.
9. Sebagai pengguna My Documents, saya ingin memindahkan file ke folder lain, termasuk ke group lain.
10. Sebagai pengguna My Documents, saya ingin membagikan berkas lewat menu Bagikan, dan tidak lagi melihat menu Ekspor.
11. Sebagai pengguna My Documents, saya ingin membagikan satu folder beserta seluruh subfolder dan isinya sebagai ZIP.
12. Sebagai pengguna My Checklist, saya ingin menautkan satu berkas dari My Documents ke sebuah item lewat dialog Ubah Item & Hubungan Lintas Data.
13. Sebagai pengguna My Checklist, saya ingin membuka berkas tertaut langsung dari titik tiga item.
14. Sebagai pengguna My Checklist, saya ingin melepas kaitan berkas lewat dialog yang sama, dengan konfirmasi.
15. Sebagai pengguna My Checklist, saya ingin item yang punya tautan menampilkan ikon 📎 agar mudah dikenali.
16. Sebagai pengguna My Checklist, saya ingin tautan tetap benar ketika saya mengganti nama atau memindahkan berkas dari dalam aplikasi.
17. Sebagai pengguna My Checklist, saya ingin diberi tahu bila berkas tertaut sudah tidak ditemukan, dan bisa melepas kaitannya.
18. Sebagai pengguna card DailyTracker, saya ingin tombol Lihat History berada tepat di bawah Simpan Hari Ini agar mudah dijangkau.
19. Sebagai pengguna, saya ingin halaman Tentang menampilkan email kontak yang benar dan daftar fitur yang sesuai kondisi aplikasi sekarang.

---

## 4. Domain Model

### 4.1 Glosarium

| Istilah | Definisi |
|---|---|
| **Urutan Hari Ini (Today Order)** | Urutan tampil tugas pada seksi "Hari Ini" di dashboard Task Master. Berbeda dari `Task.sortOrder` yang mengatur urutan di dalam kategori. |
| **Custom Order** | Daftar ID tugas terurut yang disimpan permanen ketika user menggeser tugas di Hari Ini. |
| **Sort Mode** | Mode pengurutan Hari Ini: `defaultOrder`, `nameAsc`, `nameDesc`, `incompleteFirst`, `completedFirst`, `categoryAsc`, `custom`. |
| **Task Invisible** | Tugas yang sedang tidak lolos aturan `todayVisibility` pada tanggal berjalan. ID-nya tetap disimpan di custom order agar posisinya tidak hilang saat muncul kembali. |
| **Group (Documents)** | Kartu akar di My Documents; satu group = satu file JSON + satu direktori fisik `my_documents/<groupId>/`. Tidak bisa bersarang. |
| **Folder (Documents)** | Direktori fisik di dalam group. Boleh bersarang tanpa batas. Memiliki metadata `id`, `name`, `icon`, `parentId`, `orderIndex`. |
| **Root Folder** | Level tertinggi di dalam group = layar group itu sendiri (`relativePath == ''`). File lama otomatis berada di sini. |
| **Relative Path** | Path file relatif terhadap direktori group, memakai `/` sebagai pemisah, mis. `Kuliah/2026/laporan.pdf`. Ini adalah identitas stabil sebuah file. |
| **Auto-rename** | Penamaan ulang otomatis saat bentrok: `nama (1).ext`, `nama (2).ext`, dst., di folder yang sama. |
| **Folder Breadcrumb** | Jejak navigasi `Group / Folder / Subfolder` di layar folder. |
| **Tautan Berkas** | Referensi dari satu `SubSubjectItem` ke satu file dokumen, disimpan sebagai `groupId` + `relativePath` + nama tampilan. |
| **Dangling Link** | Tautan yang file-nya sudah tidak ada (dihapus/dipindah dari luar aplikasi). Item tetap menyimpan tautan sampai user melepasnya. |
| **Auto-unlink** | Pelepasan tautan otomatis ketika file dihapus dari dalam aplikasi. |
| **Emoji Picker** | Grid emoji terkurasi untuk ikon group/folder, menggantikan input teks bebas. |

### 4.2 TaskMasterData schema v3

`lib/features/task_master_new/domain/entities/task_master_data.dart`

```dart
class TaskMasterData {
  static const int currentSchemaVersion = 3;

  final int schemaVersion;
  final List<Category> categories;
  final String todaySortMode;      // nama enum TodayTaskSortMode
  final List<String> todayOrder;   // daftar Task.id
}
```

JSON:

```json
{
  "schemaVersion": 3,
  "categories": [ ... ],
  "todaySortMode": "custom",
  "todayOrder": ["task_a", "task_b", "task_c"]
}
```

Aturan:
- `todaySortMode` default `"defaultOrder"` bila tidak ada / tidak dikenal.
- `todayOrder` default `[]`.
- Migrasi v1/v2 → v3 hanya menambah dua field di atas; tidak mengubah categories/tasks.
- `todayOrder` boleh memuat ID tugas yang sedang invisible; ID yang benar-benar sudah tidak ada di data di-prune.
- Tugas baru yang belum ada di `todayOrder` dianggap berada di akhir (`index = 999999` pada `sortTodayTasks`).

### 4.3 DocumentFolder

`lib/features/documents/data/models/document_model.dart`

```dart
class DocumentFolder {
  String id;          // millisecondsSinceEpoch + suffix anti-tabrakan
  String name;        // nama direktori fisik
  String icon;        // emoji, default '📁'
  String? parentId;   // null = root (langsung di dalam group)
  int orderIndex;     // urutan antar-saudara
}
```

`DocumentGroup` mendapat:

```dart
List<DocumentFolder> folders; // default []
```

JSON `folders` disimpan di dalam file group `<groupId>.json`, sehingga backup/sync Data Center otomatis membawanya (tidak ada file metadata terpisah).

Struktur fisik:

```
my_documents/
  <groupId>.json          // DocumentGroup + folders metadata
  <groupId>/
    file_root.pdf         // root folder
    Kuliah/               // folder
      file_a.pdf
      2026/               // subfolder
        laporan.pdf
```

Aturan:
- `name` folder wajib unik (case-insensitive) di antara saudara dalam parent yang sama. Jika bentrok, form menampilkan error "Nama folder sudah dipakai".
- Nama folder disanitasi dari karakter path terlarang (`/ \ : * ? " < > |`).
- Rename folder = rename direktori fisik + update metadata + update tautan checklist yang berada di bawahnya.
- Hapus folder = hapus direktori rekursif + hapus metadata + auto-unlink tautan checklist di bawahnya.
- Pindah folder (fase ini) hanya di dalam group yang sama; pindah folder lintas group di luar scope.

### 4.4 Tautan berkas pada SubSubjectItem

`lib/features/checklist/data/models/daily_model.dart`

```dart
class SubSubjectItem {
  // ... field lama ...
  String? linkedDocumentGroupId;
  String? linkedDocumentRelativePath; // mis. 'Kuliah/2026/laporan.pdf'
  String? linkedDocumentName;         // nama tampilan, mis. 'laporan.pdf'
}
```

JSON key mengikuti gaya camelCase yang sudah dipakai model ini (`isDisabled`, `linkedSubjectId`, dst.):

```json
{
  "linkedDocumentGroupId": "1712345678901",
  "linkedDocumentRelativePath": "Kuliah/2026/laporan.pdf",
  "linkedDocumentName": "laporan.pdf"
}
```

- `fromJson` memberi default `null` untuk data lama (backward compatible).
- `toJson` menulis ketiga field (null aman).
- Relasi ini **tidak** memakai `allList`/`DocumentSection` legacy; sumber kebenaran file adalah filesystem.

### 4.5 Diagram relasi baru

```
TaskMasterData (v3)
  ├── categories[]
  │     └── tasks[] (sortOrder = urutan kategori)
  ├── todaySortMode
  └── todayOrder[]  ── referensi Task.id (urutan Hari Ini)

DocumentGroup
  ├── folders[]  (id, name, icon, parentId, orderIndex)
  └── direktori fisik my_documents/<groupId>/<relativePath>

SubSubjectItem
  └── linkedDocumentGroupId + linkedDocumentRelativePath
        └── menunjuk ke file di my_documents/<groupId>/<relativePath>
```

---

## 5. Detailed Requirements

### 5.1 WS1 — Persistensi Urutan Manual Hari Ini

**Perilaku**
1. Saat layar Task Master dibuka, `_todaySortMode` dan `_todayCustomOrder` diisi dari `TaskMasterData`.
2. Menggeser tugas (drag atau tombol naik/turun) langsung menyimpan `todayOrder` ke repository (atomic write JSON).
3. Mengubah mode sort lewat menu menyimpan `todaySortMode`.
4. Mode `custom` dengan `todayOrder` kosong jatuh kembali ke `defaultOrder`.
5. ID tugas yang tidak ada lagi di semua kategori dibuang dari `todayOrder` saat load dan saat save.
6. ID tugas baru yang belum ada di `todayOrder` ditambahkan ke akhir secara implisit (tanpa perlu menulis ulang file sampai user menggeser lagi).
7. Urutan tetap dipertahankan ketika tugas invisible lalu muncul kembali.
8. Reorder Hari Ini **tidak** mengubah `Task.sortOrder`.

**File yang disentuh**
- `lib/features/task_master_new/domain/entities/task_master_data.dart` — field baru + `currentSchemaVersion = 3` + `copyWith`.
- `lib/features/task_master_new/data/mappers/task_master_mapper.dart` — baca/tulis field baru; `detectSchemaVersion` menerima 1/2/3; upgrade v1/v2 → v3.
- `lib/features/task_master_new/domain/repositories/task_repository.dart` + `data/repositories/task_repository_impl.dart` — operasi `saveTodayPreferences({required TodayTaskSortMode mode, required List<String> order})` atau perluasan `_mutateData`.
- `lib/features/task_master_new/presentation/controllers/task_master_controller.dart` + `task_master_state.dart` — expose mode/order dan method persist.
- `lib/features/task_master_new/presentation/screens/task_master_screen.dart` — hapus state lokal sebagai sumber kebenaran; baca dari controller; `_reorderTodayTask` memanggil persist.
- `lib/features/task_master_new/presentation/models/today_task_sort_mode.dart` — tambah helper `fromName`/`name` (atau serializer) untuk persistensi.

**Non-goal:** menyimpan urutan per tanggal; mengubah `sortOrder`.

### 5.2 WS2 — Folder Bertingkat My Documents

**Model & migrasi**
- Tambah `DocumentFolder` + `DocumentGroup.folders` (default `[]`). `fromJson` toleran: field tidak ada → list kosong.
- Tidak ada `schemaVersion` dokumen; tidak perlu migrasi file lama. File lama sudah berada di root group.

**Layar & navigasi**
- `DocumentDetailScreen` menjadi sadar-folder: parameter baru `initialRelativePath` (default `''`).
- Isi layar mengikuti `currentRelativePath`:
  - Breadcrumb horizontal (chip): `Group / Folder / Subfolder`, tiap segmen bisa di-tap untuk naik.
  - Folder dirender lebih dulu, urut A-Z; setelah itu file mengikuti mode sort yang ada (manual/A-Z/Z-A).
  - Tap folder → `Navigator.push` layar yang sama dengan `initialRelativePath` folder tersebut (drill-down, back berfungsi).
  - Tap file → `OpenFile.open` seperti sekarang.
- `_loadPhysicalFiles` diubah menjadi pemuatan entri: `Directory.listSync()` (non-rekursif), pisahkan `Directory` vs `File`, abaikan file `.json` di root group.
- Folder menampilkan ikon emoji + nama + ringkasan isi langsung (mis. "3 file · 1 folder").

**CRUD folder**
- Buat folder: tombol "+" di layar folder menawarkan "Tambah Folder" dan "Impor Berkas".
- Menu titik tiga per folder: `Ubah Nama`, `Ganti Ikon`, `Pindahkan`, `Bagikan (ZIP)`, `Hapus`.
- Ubah nama: validasi unik antar-saudara, sanitasi karakter, rename direktori fisik, update metadata, update tautan checklist di subtree.
- Ganti ikon: buka Emoji Picker.
- Pindahkan: pilih parent folder tujuan di dalam group yang sama; tolak jika tujuan adalah dirinya sendiri/descendant-nya.
- Hapus: konfirmasi destruktif (merah), hapus rekursif, hapus metadata, auto-unlink tautan checklist di subtree.

**File**
- Impor: `FilePicker` → target direktori = folder aktif. Jika nama bentrok → auto-rename `nama (1).ext` (tanpa dialog).
- Ubah nama: jika bentrok → auto-rename. Update tautan checklist.
- Pindahkan: dialog tujuan berupa **Group → Folder** (hierarkis, lintas group diperbolehkan). Jika bentrok → auto-rename. Update tautan checklist.
- Hapus: konfirmasi; hapus file; auto-unlink tautan checklist.
- Multi-select tetap hanya untuk file di folder aktif.

**Hapus Ekspor / ganti Bagikan**
- Hapus entri menu `export`, fungsi `_exportPhysicalFile`, `_exportMassiveFiles`, serta wiring `onExportMassive`.
- Pertahankan `share` (`Share.shareXFiles`) per-file dan massal.
- Di `BaseDetailListScreen`, hapus/hentikan penggunaan callback `onExportMassive` (dan label menu massal terkait) bila tidak dipakai fitur lain. Data Center tidak disentuh.

**Bagikan folder sebagai ZIP**
- Menu folder → `Bagikan (ZIP)`.
- Buat ZIP sementara berisi seluruh subtree folder, entry relatif terhadap folder yang dibagikan (`Sub/file.pdf`), struktur terjaga. Folder kosong tetap menghasilkan ZIP valid.
- Bagikan via `Share.shareXFiles` dengan nama `<nama folder>.zip`.
- File sementara dihapus setelah share (best effort).

**Ikon**
- Widget baru `EmojiIconPicker` (grid, mis. 📁 📂 🗂️ 📄 📝 📚 🎓 💼 🏠 ⭐ ❤️ 🔒 🎵 🖼️ 📊 🧾 ✈️ 🍳 ⚽ 🌱).
- Dipakai di dialog tambah/edit group dan tambah/edit folder.
- Emoji lama tetap ditampilkan; jika tidak ada di daftar, tetap valid sebagai nilai terpilih.

**Dampak Data Center**
- Metadata folder berada di JSON group; file berada di subdirektori.
- `doc_sync_helper.dart` sudah memakai `listSync(recursive: true)` dan relative path, sehingga folder otomatis ikut tersinkron. Verifikasi operasi delete/rename folder tetap konsisten dengan manifest.

### 5.3 WS3 — Tautan Berkas Dokumen pada Item Checklist

**Penautan (dialog)**
- Di `EditItemRelationsDialog` (`edit_item_relations_dialog.dart`), tambahkan section baru di atas tombol aksi, mis. **"📎 Berkas Dokumen Tertaut"**:
  - Menampilkan nama file + path ringkas (`Group / Folder / file`) jika sudah tertaut.
  - Tombol `Pilih Berkas` / `Ganti Berkas` → buka **browser hierarkis** (bottom sheet/dialog): pilih Group → Folder → File, dilengkapi kolom pencarian nama file dan breadcrumb. Hanya file (bukan folder) yang bisa dipilih.
  - Tombol `Hapus Kaitan` → dialog konfirmasi destruktif (merah, "Batal"/"Lepas").
- `onConfirm` diperluas dengan tiga field tautan; `checklist_dialog.dart:330` dan handler-nya meneruskan nilai ke item.

**Titik tiga item**
- Di `checklist_tree_view.dart`, tambah `PopupMenuItem` **"Buka Berkas"** hanya jika item punya `linkedDocumentRelativePath`.
- Aksi membuka file via `OpenFile.open`. Jika file tidak ada → dialog "Berkas tidak ditemukan" dengan opsi `Lepas Kaitan` / `Tutup`.
- Tidak menambah entri "Lepas Kaitan" di titik tiga; pelepasan hanya lewat dialog (sesuai keputusan).
- Indikator **📎** ditampilkan di baris item (dekat nama) saat `linkedDocumentRelativePath != null`; beri warna peringatan bila file tidak ditemukan (pengecekan ringan saat render/build daftar).

**Propagasi otomatis**
- Service baru, mis. `lib/features/checklist/data/services/checklist_document_link_service.dart`:
  - `updateLinkPath({groupId, oldRelativePath, newRelativePath, newName})`
  - `clearLinksFor({groupId, relativePathPrefix})`
  - `clearLinkForItem({groupId, relativePath})`
- Implementasi: muat semua `my_checklist/*.json`, telusuri `ChecklistGroup → ChecklistSection → DailySubject → SubSubjectItem.subMateri` rekursif, cocokkan `linkedDocumentGroupId` + `linkedDocumentRelativePath`, ubah/hapus, simpan atomic.
- Dipanggil dari aksi My Documents: rename file, move file, rename folder, move folder, delete file, delete folder, delete group.
- Hapus dari dalam aplikasi → **auto-unlink** + snackbar info. Berkas hilang dari luar aplikasi → tautan dibiarkan (dangling), item menampilkan status tidak ditemukan.

**Penyimpanan tautan**
- Simpan `groupId` + `relativePath` + nama tampilan. Tidak memakai ID file baru; relative path adalah identitas.
- Nama file sama di folder berbeda aman karena path lengkap berbeda.

### 5.4 WS4 — Layout Tombol DailyTracker

- Hapus seluruh blok tombol **"Reset Hari Baru"** (`checklist_detail_screen.dart:1080-1117`, termasuk key `btn_reset_for_new_day`).
- Hapus `resetForNewDay` dari `checklist_detail_controller.dart:705-750` bila tidak ada pemakai lain (dan bersihkan test yang mereferensikannya).
- Susun ulang:
  - `Simpan Hari Ini` → `SizedBox(width: double.infinity)`.
  - `SizedBox(height: 6)`.
  - `Lihat History` → `SizedBox(width: double.infinity)`.
- Tombol hanya tampil pada kondisi lama: `subject.isDailyTrackerEnabled && subject.type != 'note'`.
- Fungsi reset tetap tersedia lewat dialog checklist: "Reset Progress" dan "Reset Total Checklist" (`checklist_dialog.dart:982-1020`).

### 5.5 WS5 — Halaman Tentang

**Email**
- `about_page.dart:369` → `mailto:frendyrikalgerung@gmail.com`.
- Tidak ada occurrence lain di repo; cukup satu perubahan.

**Daftar Fitur Aplikasi**
- Tulis ulang `_buildFeaturesTab` secara komprehensif; pertahankan pola `_AnimatedFeatureListItem` (`icon`, `title`, `subtitle`).
- Hanya fitur final yang terlihat user; tanpa saklar eksperimental, iklan, atau detail protokol internal.
- Usulan entri (boleh digabung/dirapikan saat implementasi, minimal mencakup):
  1. **Task Master & Target Harian** — kategori, target harian/total, hitungan berkala, visibilitas Hari Ini, riwayat & streak.
  2. **Tipe Tugas Fleksibel** — tugas biasa, progress bar, hitung mundur.
  3. **My Checklist Hubs** — multi-hub, seksi, sub-materi bersarang, tipe item normal/progress/hitung mundur, item nonaktif.
  4. **Kontrol Tampilan Checklist** — lipat & sembunyikan seksi, color wheel, warna teks adaptif.
  5. **Tautan Berkas Checklist** — kaitkan item ke berkas My Documents, buka langsung dari titik tiga, penanda 📎.
  6. **My Documents** — group, folder bersarang tanpa batas, ikon kustom, bagikan berkas & folder ZIP.
  7. **My Notes** — catatan terstruktur, tabel data, halaman catatan, Markdown.
  8. **Manajemen Prompt** — template prompt AI, grup, item detail.
  9. **Jurnal Aktivitas** — pencatatan durasi produktif otomatis dari increment Task Master, kaitan tugas.
  10. **Statistik & Analitik** — stacked bar chart riwayat, filter rentang waktu.
  11. **DailyTracker & Riwayat** — simpan snapshot harian, edit/hapus entri riwayat.
  12. **Data Center** — backup/restore ZIP, impor/ekspor per fitur, local sharing WiFi/LAN.
  13. **Penyimpanan Offline & Direktori Kustom** — data lokal 100%, base directory dapat dipindah, dukungan Android/Linux.

---

## 6. Implementation Decisions

| # | Keputusan | Alasan |
|---|---|---|
| D1 | Urutan Hari Ini global permanen, bukan per tanggal | Menghindari data per-hari yang membengkak dan tidak konsisten saat tugas muncul/hilang. |
| D2 | Urutan Hari Ini independen dari `Task.sortOrder` | Menggeser dashboard tidak boleh mengacak urutan kategori/detail. |
| D3 | Disimpan di `TaskMasterData` v3, bukan SharedPreferences | Ikut backup/sync Data Center dan portabel antar perangkat. |
| D4 | Tugas baru = akhir urutan; ID hilang di-prune | Tidak mengganggu urutan yang sudah diatur; data tetap bersih. |
| D5 | Group tetap akar, folder bersarang tanpa batas | Menjaga kompatibilitas dengan `sectionCategory` + direktori per group yang dipakai Data Center. |
| D6 | Folder = subdirektori fisik; relative path = identitas file | Nama sama di folder berbeda aman; sync/backup sudah berbasis relative path. |
| D7 | Auto-rename `nama (1).ext` saat bentrok (impor & rename) | Konsisten dengan pola impor yang sudah ada (`document_detail_screen.dart:337-363`), tanpa dialog berulang. |
| D8 | Nama folder unik per parent (case-insensitive), ditolak dengan validasi | Nama folder adalah nama direktori fisik; duplikat akan bertabrakan. |
| D9 | Folder metadata di dalam JSON group | Satu sumber, otomatis ikut backup/sync; tidak perlu file baru. |
| D10 | Ikon via Emoji Picker terkurasi | Konsisten dan bebas salah ketik; emoji lama tetap valid. |
| D11 | Ekspor dihapus hanya di My Documents | Data Center tetap punya backup/restore; tidak ada kehilangan kemampuan backup. |
| D12 | Share folder = ZIP seluruh subtree, struktur terjaga | Memenuhi kebutuhan "keduanya sekarang"; struktur folder tidak hilang. |
| D13 | Multi-select hanya file | Folder dibagikan/dipindah lewat menunya sendiri; menghindari semantik campuran. |
| D14 | Link disimpan sebagai `groupId` + relative path | Stabil terhadap nama sama di folder berbeda; auto-update saat rename/move. |
| D15 | Penautan/pelepasan hanya di dialog Ubah Item; Buka Berkas di titik tiga | Satu tempat untuk mengubah relasi; titik tiga untuk akses cepat. |
| D16 | Hapus internal = auto-unlink; hilang eksternal = dangling | Menghindari tautan mati setelah aksi yang diketahui; tetap aman untuk perubahan di luar app. |
| D17 | Reset Hari Baru dihapus dari card | Reset sudah tersedia di dialog checklist; card jadi lebih ringkas. |
| D18 | Lihat History tepat di bawah Simpan Hari Ini, gap 6px | Sesuai permintaan; keduanya full-width agar mudah dijangkau. |
| D19 | Fitur Aplikasi ditulis ulang, hanya fitur final | Halaman Tentang harus akurat dan tidak membocorkan fitur internal/eksperimental. |

---

## 7. Edge Cases & Migration

### WS1
- JSON v1/v2 tanpa `todaySortMode`/`todayOrder` → default, data tidak berubah.
- `todaySortMode` berisi nilai tak dikenal → fallback `defaultOrder`.
- Custom order kosong → `defaultOrder` (tidak menampilkan urutan acak).
- Tugas dihapus → ID dibersihkan; tugas ditambahkan → otomatis di akhir.
- Tugas invisible → ID tetap disimpan.
- Reorder saat mode sort bukan `custom` → pindah ke `custom` dan simpan.

### WS2
- Folder kosong → tetap tampil; ZIP valid meski kosong.
- Folder dengan nama sama di parent berbeda → diizinkan.
- Rename folder menjadi nama saudara yang sudah ada → ditolak dengan pesan validasi.
- Pindah folder ke dalam dirinya sendiri/descendant → ditolak.
- File/folder dengan nama karakter terlarang → disanitasi saat pembuatan/rename.
- File `.json` di root group tetap disembunyikan dari daftar (perilaku lama).
- Impor ke folder dalam → target path memakai `currentRelativePath`.
- Bagikan folder saat ada file besar → tetap memakai ZIP sementara; bersihkan setelah share.
- Data Center: restore ZIP lama (tanpa subfolder) tetap valid; restore ZIP baru memulihkan struktur folder.
- Folder move lintas group: **tidak didukung** fase ini; menu Pindahkan folder hanya menampilkan parent di group yang sama.

### WS3
- Item lama tanpa field tautan → `null`, tidak ada perubahan UI.
- Link ke file yang lalu di-rename dari dalam app → path diperbarui, nama tampilan diperbarui.
- Link ke file yang dihapus dari dalam app → tautan dilepas, snackbar info.
- Link ke file yang hilang dari luar app → 📎 tetap tampil dengan status tidak ditemukan; buka → dialog opsi lepas.
- Group dokumen dihapus → semua tautan ke group itu dilepas.
- Link ke file dengan nama sama di folder berbeda → tetap benar karena relative path.
- Penautan dari dialog lalu "Batal" → tidak ada perubahan (state lokal dialog dibuang).
- File yang dipilih tidak lagi ada saat dialog disimpan → tolak dengan pesan "Berkas tidak ditemukan".
- Enkripsi checklist/data: propagasi memakai jalur baca/tulis yang sama dengan penyimpanan checklist agar tetap menghormati konfigurasi enkripsi.

### WS4
- Card `note` / DailyTracker nonaktif → tombol tetap tidak tampil (tidak berubah).
- Test lama yang mencari `btn_reset_for_new_day` harus dihapus/diperbarui.
- `resetForNewDay` dihapus; pastikan tidak ada pemanggil tersisa (grep).

### WS5
- Emoji/ikon fitur harus valid `IconData` (tidak memakai emoji di properti `icon`).
- Panjang subtitle wajar agar tidak overflow pada layar kecil.

---

## 8. Testing Decisions

Prinsip: uji perilaku yang terlihat user dan kontrak persistensi, bukan detail widget internal.

### WS1
1. `task_master_mapper` v2 → v3: file tanpa field baru terbaca dengan default; setelah save, `schemaVersion == 3` dan field tertulis.
2. Repository: `saveTodayPreferences` lalu reload → mode & order sama.
3. Widget test: buka layar, aktifkan reorder, geser tugas, tutup/buka ulang layar (reopen) → urutan tetap. Perluas `test/features/task_master_new/presentation/today_task_sorting_test.dart:152-188` yang sekarang hanya menguji sesi yang sama.
4. Unit test prune: order berisi ID yang tidak ada → dibuang; tugas baru → di akhir.
5. Unit test: mode `custom` dengan order kosong → hasil `defaultOrder`.

### WS2
1. Model: `DocumentGroup.fromJson` tanpa `folders` → list kosong; round-trip `DocumentFolder`.
2. Controller/screen: buat folder → direktori fisik ada; buat subfolder → path bersarang benar.
3. Drill-down: tap folder → breadcrumb bertambah; back → kembali.
4. Auto-rename: impor dua file bernama sama di folder sama → `nama (1).ext`; di folder berbeda → nama asli.
5. Rename file/folder bentrok → auto-rename / validasi (folder).
6. Pindah file lintas group + folder → file ada di tujuan; link checklist ikut berubah.
7. Hapus folder → isi terhapus; link checklist dilepas.
8. Share folder ZIP → entri ZIP memuat subtree dengan struktur benar (unit test dengan `archive`).
9. Regresi: menu Ekspor tidak ada lagi; Bagikan tetap ada; Data Center tidak berubah.
10. Emoji picker: memilih emoji menyimpan nilai ke group/folder.

### WS3
1. Model: `SubSubjectItem` round-trip tiga field tautan; JSON lama → null.
2. Dialog: pilih berkas → simpan → field terisi; buka lagi → nilai tampil.
3. Hapus kaitan → konfirmasi → field null.
4. Titik tiga: item tertaut menampilkan "Buka Berkas"; item tanpa tautan tidak.
5. Indikator 📎 muncul/hilang sesuai tautan.
6. Propagasi: rename file → `relativePath` item berubah; delete file → tautan null; rename folder → prefix path item berubah.
7. Dangling: path tidak ada → dialog "Berkas tidak ditemukan" + aksi lepas.
8. Regresi: relasi checklist lama (linkedSubject/accumulator/external) tetap berfungsi.

### WS4
1. Widget test: `btn_save_today_log` dan `btn_view_history` ada; `btn_reset_for_new_day` tidak ada.
2. Verifikasi posisi vertikal: History berada di bawah Save dan keduanya full-width (cek `RenderBox`/`tester.getTopLeft`).
3. Reset tetap bisa diakses lewat dialog checklist.

### WS5
1. Widget test: teks `frendyrikalgerung@gmail.com` ada; `frendydev1@gmail.com` tidak ada.
2. Widget test: entri fitur kunci (My Documents folder, tautan berkas) tampil.

### Catatan test lama
- `test/features/documents/presentation/documents_section_collapse_test.dart` dan `documents_section_hide_test.dart` memakai `tempDir/documents`, sedangkan produksi memakai `<baseDir>/my_documents`. Perbaiki path agar tidak stale saat menambah test baru.

---

## 9. Acceptance Criteria

### WS1
- [ ] Menggeser tugas di Hari Ini lalu menutup dan membuka kembali aplikasi → urutan sama.
- [ ] Mode sort terakhir tersimpan dan dipulihkan.
- [ ] Menggeser di Hari Ini tidak mengubah urutan di Category Detail.
- [ ] Tugas baru muncul di akhir; tugas terhapus tidak menyisakan ID di JSON.
- [ ] File JSON tetap `schemaVersion: 3` dan dapat dibaca versi lama tanpa crash (upgrade path).

### WS2
- [ ] Bisa membuat folder di dalam group dan folder di dalam folder tanpa batas.
- [ ] Breadcrumb tampil dan navigasi back berfungsi.
- [ ] Dua file bernama sama di folder berbeda tidak saling menimpa.
- [ ] File bentrok di folder sama otomatis menjadi `nama (1).ext`.
- [ ] Ikon group/folder bisa diganti lewat picker emoji.
- [ ] Menu Ekspor hilang; Bagikan Berkas tetap berfungsi.
- [ ] Folder bisa dibagikan sebagai ZIP berisi seluruh subtree.
- [ ] Data Center backup/restore tetap memuat struktur folder.
- [ ] File lama tetap terlihat di layar group tanpa migrasi.

### WS3
- [ ] Item checklist bisa ditautkan ke satu berkas lewat dialog Ubah Item & Hubungan Lintas Data.
- [ ] Titik tiga menampilkan "Buka Berkas" hanya untuk item tertaut dan membuka file.
- [ ] Pelepasan tautan lewat dialog dengan konfirmasi.
- [ ] 📎 tampil pada item tertaut.
- [ ] Rename/move internal memperbarui tautan; delete internal melepas tautan.
- [ ] Berkas hilang eksternal menampilkan status tidak ditemukan + opsi lepas.

### WS4
- [ ] Tidak ada tombol "Reset Hari Baru" di card.
- [ ] "Simpan Hari Ini" lalu "Lihat History" tersusun vertikal, gap ±6px, keduanya full-width.
- [ ] Reset masih tersedia di dialog checklist.

### WS5
- [ ] Email Tentang = `frendyrikalgerung@gmail.com`.
- [ ] Daftar Fitur Aplikasi memuat fitur terbaru dan tidak memuat fitur eksperimental/internal.

---

## 10. Out of Scope

- Urutan Hari Ini per tanggal / per hari.
- Sinkronisasi cloud; hanya local sharing & backup yang sudah ada.
- Pindah folder lintas group (folder move hanya dalam group yang sama).
- Share folder digabung dengan multi-select file dalam satu aksi.
- Mengubah format backup/data center di luar konsekuensi otomatis folder.
- File versioning / riwayat perubahan dokumen.
- Tautan checklist ke lebih dari satu berkas per item.
- Menampilkan fitur eksperimental/iklan di halaman Tentang.
- Redesign visual menyeluruh di luar tombol DailyTracker.

---

## 11. Further Notes

- **Lokasi PRD:** dokumen ini ditulis di `~/.opencode/plan/perbaikan-reorder-dokumen-checklist/PRD.md` karena sesi masih di Plan mode. Setelah pindah ke agent implementasi, salin ke `docs/problems/perbaikan-reorder-dokumen-checklist/PRD.md`.
- **GLOSSARY/ADR:** istilah baru ada di §4.1. ADR layak dibuat untuk D3 (order di data tugas, bukan SharedPreferences) dan D6 (folder fisik + relative path sebagai identitas), karena keduanya sulit dibalik dan memengaruhi backup/sync.
- **Risiko propagasi tautan:** rename/move/delete di My Documents kini menulis ke file checklist. Pastikan operasi ini atomik dan tidak berjalan bersamaan dengan penyimpanan checklist (gunakan pola serialisasi yang sudah dipakai repository Task Master bila perlu).
- **Risiko path test Documents:** path test lama tidak konsisten (`documents` vs `my_documents`); perbaiki sebelum menambah test.
- **Urutan implementasi disarankan:** WS1 → WS2 → WS3 → WS4 → WS5, karena WS3 bergantung pada identitas file dari WS2.
