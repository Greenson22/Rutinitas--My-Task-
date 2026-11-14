# 03: Kelola kategori dengan identitas stabil

**What to build:** Pengguna dapat menambah, mengedit, menyembunyikan, dan menghapus kategori. Rename kategori tidak memutus tugas di dalamnya karena kategori memakai `id` stabil. Daftar kategori dan tampilan dashboard langsung mencerminkan perubahan.

**Blocked by:** 02 — Fondasi Task Master New dengan migrasi dan tampilan baca-saja

**Status:** done

- [x] Pengguna dapat menambah kategori dengan nama dan ikon emoji.
- [x] Pengguna dapat mengedit nama dan ikon tanpa mengubah `id` kategori.
- [x] Rename kategori tidak memutus atau menghilangkan tugas di dalamnya.
- [x] Nama kategori duplikat ditolak atau meminta konfirmasi yang jelas.
- [x] Pengguna dapat menyembunyikan dan menampilkan kembali kategori.
- [x] Penghapusan kategori meminta konfirmasi dan memberi peringatan jika masih memiliki tugas.
- [x] Semua perubahan bertahan setelah aplikasi ditutup dan dibuka kembali.
- [x] Widget test untuk tambah, edit, rename, sembunyikan, dan hapus kategori lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

### Ringkasan

Pengelolaan kategori penuh sudah tersedia di `task_master_new` tanpa menambah dependency. Kategori tetap memakai `id` stabil; rename hanya mengubah `name`/`icon` sehingga seluruh tugas dan riwayatnya tetap utuh.

### Perubahan utama

- **Domain** — `domain/operations/category_operations.dart` berisi operasi murni tambah/edit/sembunyi/hapus, validasi nama (wajib, maksimal 60 karakter, duplikat case-insensitive), serta `defaultCategoryIcon`. Tidak ada dependensi Flutter, JSON, atau file system di lapisan ini.
- **Repository** — kontrak `TaskRepository` diperluas dengan `addCategory`, `updateCategory`, `setCategoryHidden`, dan `deleteCategory`. `TaskRepositoryImpl` memakai satu helper `_mutateCategories` (load → transform → save) sehingga semua jalur tulis tetap memakai atomic write dan enkripsi yang sudah ada.
- **Controller** — `TaskMasterNewController` menangani aksi kategori, status `isSaving`, pesan aksi, dan retry aksi terakhir yang gagal. Pesan error internal tidak lagi ditampilkan ke pengguna.
- **Presentasi** — kartu kategori dengan menu Ubah/Sembunyikan/Tampilkan/Hapus, FAB tambah kategori, dialog form dengan validasi nama + ikon dan preset emoji, dialog konfirmasi hapus yang memperingatkan jumlah tugas, serta banner "Coba Lagi" saat penyimpanan gagal. Empty state tidak lagi menyebut tampilan baca-saja.

### Keputusan penting

- Duplikat nama **ditolak** (bukan sekadar konfirmasi), sesuai opsi pertama pada tiket dan validasi spesifikasi.
- Menghapus kategori juga menghapus tugas di dalamnya; dialog menjelaskan dampak ini secara eksplisit bila jumlah tugas > 0.
- Kategori tersembunyi tetap tampil di layar pengelolaan (dengan badge) agar bisa ditampilkan kembali; penyaringan dari dashboard dikerjakan pada tiket dashboard.
- Cache data di repository tidak dipakai; setiap operasi membaca file terbaru agar tidak menimpa perubahan dari fitur lain (mis. Data Center).
- ID kategori baru dibuat oleh repository (injectable untuk test), bukan oleh widget.

### Pengujian

- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test test/features/task_master_new` — **48 test lulus**.
- Test baru:
  - `domain/category_operations_test.dart` — validasi nama, tambah, rename mempertahankan `id` + tugas, sembunyikan/tampilkan, hapus.
  - `data/task_repository_category_contract_test.dart` — CRUD bertahan setelah repository dibuat ulang, duplikat tidak menulis file, dan round-trip pada file nyata di direktori sementara.
  - `presentation/category_management_test.dart` — widget test tambah, edit/rename, rename tidak memutus tugas, duplikat, sembunyikan/tampilkan, hapus dengan peringatan, persistensi setelah layar dibuka ulang, serta banner retry saat penyimpanan gagal.

### Catatan review

Review dua sumbu (standards + spec) dilakukan. Temuan yang sudah ditindaklanjuti:

- Menambahkan opsi **Coba Lagi** pada banner kegagalan simpan dan menghapus kebocoran detail error ke UI.
- Menambahkan test jalur error penyimpanan dan test round-trip file nyata.
- Menghapus duplikasi repository/fake melalui helper mutasi dan menyatukan helper penggantian kategori.
- Menghapus CTA tambah kategori dari empty state karena termasuk cakupan tiket dashboard; FAB tetap tersedia saat data sudah dimuat.
- FAB disembunyikan saat loading/error agar tidak menambah data sebelum data termuat.

### Tindak lanjut (di luar tiket ini)

- Reorder kategori (tiket 10) belum tersedia.
- Pencarian/filter kategori dan dashboard "Hari Ini" dikerjakan pada tiket 08–09.
- CRUD tugas dan pemindahan tugas antar kategori dikerjakan pada tiket 04 dan 10.
