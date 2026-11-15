# 11: Layout adaptif desktop/mobile dan aksesibilitas

**What to build:** Task Master New nyaman dipakai di mobile, tablet, dan desktop. Desktop memakai dua panel dengan daftar kategori di kiri dan detail di kanan; mobile memakai push ke halaman detail. Target sentuh, text scale, label aksesibilitas, dan keyboard shortcut terpenuhi.

**Blocked by:** 08 — Dashboard “Hari Ini” dan ringkasan; 09 — Pencarian dan filter; 10 — Reorder, pindah tugas, dan aksi massal

**Status:** done

- [x] Breakpoint mobile (< 600 dp), tablet (600–1024 dp), dan desktop (> 1024 dp) bekerja.
- [x] Desktop menampilkan dua panel dan tidak melakukan push screen untuk kategori.
- [x] Mobile membuka halaman detail kategori melalui push dan kembali ke dashboard.
- [x] Tablet memilih pola yang sesuai tanpa overflow.
- [x] Target sentuh minimal 48×48 dp.
- [x] Layout tidak overflow pada text scale 1.5.
- [x] Ikon aksi dan progress bar memiliki label aksesibilitas.
- [x] Keyboard shortcut desktop minimal: pencarian, tambah tugas, dan `Esc` menutup dialog.
- [x] Fokus keyboard terlihat dengan jelas.
- [x] Widget test layout mobile dan desktop lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

**Durasi build agent:** ±28 menit (22:02–22:30 WITA) untuk implementasi layout adaptif, shortcut keyboard, audit aksesibilitas dan target sentuh, penulisan widget test baru, `dart format`, `flutter analyze`, serta `flutter test` penuh.

### Ringkasan

Task Master New sekarang menyesuaikan diri pada tiga rentang lebar: mobile (< 600 dp) memakai satu panel dengan push ke detail kategori, tablet (600–1024 dp) memakai satu panel yang dipusatkan dengan lebar maksimum nyaman baca, dan desktop (> 1024 dp) memakai dua panel dengan daftar kategori di kiri serta dashboard/detail di kanan tanpa rute baru. Shortcut `Ctrl/Cmd+F`, `Ctrl/Cmd+N`, dan `Esc` tersedia, target sentuh aksi utama minimal 48 dp, progress bar dan ikon aksi punya label pembaca layar, dan layout diuji pada text scale 1.5.

### Perubahan utama

- **Layout adaptif** — `presentation/layout/task_master_layout.dart` menyediakan `TaskMasterLayout`, `taskMasterLayoutForWidth`, `usesTwoPaneLayout`, dan `usesPushedCategoryDetail`. Batas 600 dan 1024 bersifat inklusif ke pola yang lebih kecil, sehingga 600 masuk tablet dan 1024 masih tablet.
- **Desktop dua panel** — `TaskMasterNewScreen` menampilkan sidebar `desktopCategorySidebar` berisi pintasan `Hari Ini`, daftar kategori terurut, tombol tambah kategori, menu aksi per kategori, dan switch tampilkan tersembunyi. Panel kanan menampilkan dashboard ringkasan atau detail kategori. Memilih kategori hanya mengubah state `_selectedCategoryId`, bukan `Navigator.push`, sehingga sidebar tetap terlihat.
- **Detail kategori yang dapat ditanam** — `CategoryDetailScreen` mendapat `embedded` dan `onClose`. Pada desktop, header kategori, pencarian/filter, daftar tugas, mode seleksi, dan reorder tetap bekerja di panel kanan. Pada mobile/tablet layar tetap dibuka lewat `Navigator.push` dan tombol back mengembalikan ke dashboard.
- **Tablet** — memakai pola satu panel yang sama dengan mobile, tetapi isi dipusatkan dengan lebar maksimum 760 dp. Pola ini menghindari panel ganda yang terlalu sempit dan tetap nyaman pada text scale 1.5.
- **Shortcut keyboard** — `TaskMasterShortcuts` membungkus layar dengan `CallbackShortcuts`. `Ctrl/Cmd+F` membuka pencarian dan memfokuskan kolomnya, `Ctrl/Cmd+N` menambah kategori di dashboard atau tugas di detail kategori, dan `Esc` menutup pencarian, keluar dari mode seleksi/urutkan, atau kembali dari detail desktop. Dialog tetap ditutup oleh `Esc` bawaan rute dialog Flutter.
- **Fokus keyboard terlihat** — theme layar memberi `focusColor` indigo, kolom pencarian memakai `focusedBorder` indigo 2 px, dan `Focus(autofocus: true)` memastikan keyboard langsung aktif. Tooltip pencarian dan tambah kategori/tugas menyebut shortcut agar mudah ditemukan.
- **Target sentuh** — `IconButton` increment, riwayat, menu, panah reorder, tombol reorder, chip filter, tombol tampilkan tersembunyi, dan tombol kelola tugas memakai minimum 48×48 dp dengan `MaterialTapTargetSize.padded`. `visualDensity.compact` yang mengecilkan target dihapus dari aksi tersebut.
- **Aksesibilitas** — tombol increment dan riwayat memakai `Semantics(label: ...)`; drag handle menyebut nama tugas; progress bar tugas dan kategori memakai `Semantics` dengan label dan nilai persen. Tooltip tetap dipertahankan untuk pengguna mouse.
- **Overflow text scale 1.5** — header kategori dibuat responsif dengan `Flexible` dan label dua baris, sehingga tombol “Tampilkan tersembunyi” tidak mendorong judul keluar layar. Daftar satu panel memakai `SingleChildScrollView` agar semua kartu kategori tetap dibangun dan dapat ditemukan widget test.
- **Test** — `presentation/adaptive_layout_test.dart` berisi 11 test baru.

### Keputusan penting

- **Desktop bukan rute baru.** Memilih kategori di desktop hanya mengganti panel kanan. Ini menjaga konteks sidebar, menghindari animasi push yang tidak perlu, dan memenuhi syarat “tidak melakukan push screen untuk kategori”. `Navigator.canPop()` diuji tetap `false`.
- **Tablet mengikuti pola satu panel.** Tablet mendapat lebar maksimum baca, bukan dua panel sempit. Dua panel baru menguntungkan ketika lebar melewati 1024 dp; di bawah itu daftar tugas akan terlalu sempit pada text scale besar.
- **Shortcut global diteruskan ke panel detail.** Pada desktop, `Ctrl/Cmd+F` dan `Ctrl/Cmd+N` harus mengenai panel kanan, bukan dashboard yang sedang tersembunyi. `GlobalKey<CategoryDetailScreenState>` mengekspos `focusSearch()` dan `openTaskForm()` sehingga shortcut global tetap satu sumber.
- **Satu panel memakai scroll view eksplisit.** `SingleChildScrollView` + `Column` dipilih agar seluruh kartu kategori tetap berada di pohon widget untuk pengujian dan pencarian warga, sementara jumlah kategori dashboard tetap wajar. Daftar tugas yang panjang tetap memakai `ReorderableListView` di halaman detail.
- **Target sentuh dinaikkan tanpa mengubah ikon.** Ukuran ikon tetap kecil secara visual, tetapi area tekan menjadi 48 dp melalui padding dan `minimumSize`, sehingga tampilan tidak terasa lebih besar.
- **Label aksesibilitas tidak menggandakan aksi.** `Semantics` ditempatkan sebagai pembungkus tombol, bukan pengganti tombol, sehingga aksi tap tetap dapat dijalankan pembaca layar.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **179 test lulus**.
- Test baru `presentation/adaptive_layout_test.dart` (11 test):
  - batas breakpoint mobile/tablet/desktop;
  - mobile membuka detail lewat push dan kembali ke dashboard;
  - desktop menampilkan sidebar, dashboard, dan detail tanpa push (`Navigator.canPop()` false);
  - tablet memakai satu panel tanpa overflow;
  - mobile dan desktop tidak overflow pada text scale 1.5, termasuk saat detail dibuka;
  - target sentuh aksi utama minimal 48×48 dp, termasuk chip filter dan menu tugas;
  - label semantik untuk tombol increment dan progress bar;
  - `Ctrl+F` membuka pencarian dan memfokuskan kolom;
  - `Ctrl+N` menambah tugas di desktop dan `Esc` menutup dialog;
  - `Esc` mengembalikan panel detail ke dashboard.
- Test lama tetap lulus setelah dashboard memakai `SingleChildScrollView`, detail kategori dapat ditanam, dan tombol aksi diperbesar.

### Catatan review

- Tidak ada I/O di dalam `build`; layout hanya membaca lebar dari `MediaQuery`.
- Tidak ada dependency baru dan tidak ada perubahan pada domain/data, sehingga integrasi Jurnal, Checklist, dan Data Center tidak tersentuh.
- Shortcut hanya mengubah state presentasi; aksi tulis tetap melalui controller dan repository yang sama.
- `Esc` pada dialog tetap ditangani rute dialog; handler layar hanya aktif ketika fokus berada di layar.
- Sidebar desktop menampilkan kategori tersembunyi sesuai switch yang sama dengan dashboard, sehingga ringkasan tetap mengabaikan kategori tersembunyi.
- Pemilihan kategori desktop direset ketika kategori yang dipilih dihapus, agar panel kanan tidak menunjuk data yang sudah tidak ada.

### Tindak lanjut

- Recovery file korup, editor JSON Advanced, dan pengaturan enkripsi dikerjakan pada tiket 12.
- Kompatibilitas ekspor/impor Data Center dikerjakan pada tiket 13.
- Hardening performa untuk 1.000 tugas dan audit manual Android/Linux desktop dikerjakan pada tiket 14 dan 15.

