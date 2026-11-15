# 09: Pencarian dan filter

**What to build:** Pengguna dapat mencari kategori dan tugas dari satu kolom, melihat hasil yang dikelompokkan per kategori, dan memfilter tugas berdasarkan status aktif, nonaktif, atau punya target hari ini. Pencarian merespons cepat dengan debounce dan menampilkan empty state yang jelas saat tidak ada hasil.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target

**Status:** done

- [x] Pencarian mencakup nama kategori dan nama tugas.
- [x] Hasil pencarian dikelompokkan per kategori dan menampilkan konteks kategori.
- [x] Pencarian memakai debounce 250 ms.
- [x] Filter minimal tersedia: semua, aktif, nonaktif, dan punya target hari ini.
- [x] Filter dan pencarian dapat dipakai bersamaan.
- [x] Tugas nonaktif yang muncul tetap memiliki badge nonaktif.
- [x] Empty state “tidak ada hasil” menyediakan aksi menghapus pencarian/filter.
- [x] Widget test pencarian, filter, dan empty state lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

**Durasi build agent:** ±20 menit (18:20–18:40 WITA) untuk implementasi, penyesuaian tata letak tes lama, `flutter analyze`, dan `flutter test` penuh.

### Ringkasan

Pencarian dan filter tersedia dari satu kolom di dashboard dan halaman detail kategori. Dashboard membuka kolom pencarian lewat ikon di AppBar agar ringkasan dan daftar kategori tetap ringkas saat tidak dipakai. Hasil pencarian dikelompokkan per kategori, filter bisa digabung dengan query, dan empty state menyediakan satu aksi untuk menghapus keduanya sekaligus.

### Perubahan utama

- **Domain** — `domain/operations/task_search.dart` menyediakan `TaskFilter`, `filterTasksInCategory`, dan `searchTaskGroups`. Pencarian tidak peka huruf besar/kecil, mencocokkan nama kategori maupun nama tugas, dan mempertahankan urutan `sortOrder`.
- **Debounce** — `taskSearchDebounce` bernilai 250 ms. Penundaan dilakukan di `TaskSearchToolbar`, sehingga setiap karakter tidak langsung menyaring seluruh daftar.
- **Controller/state** — `TaskMasterNewState` menyimpan `searchQuery` dan `taskFilter`. Controller menyediakan `setSearchQuery`, `setTaskFilter`, `clearSearchAndFilter`, `searchGroups`, dan `filteredTasksIn`. State pencarian dipertahankan saat aksi data lain berhasil.
- **Dashboard** — ikon `openSearchButton` membuka/menutup kolom pencarian. Saat query atau filter aktif, ringkasan diganti hasil pencarian yang dikelompokkan per kategori; header kategori dapat diketuk untuk membuka detail.
- **Detail kategori** — toolbar pencarian/filter selalu tampil selama kategori memiliki tugas. Subjudul AppBar menampilkan jumlah hasil terhadap total tugas.
- **Filter** — pilihan `Semua`, `Tugas aktif`, `Tugas nonaktif`, dan `Punya target hari ini`. Filter target tidak menyiratkan status aktif, sehingga tugas nonaktif bertarget tetap muncul dengan badge `Nonaktif`.
- **Empty state** — `SearchEmptyView` menampilkan “Tidak ada hasil” dengan tombol `Hapus pencarian dan filter`. Aksi ini mengosongkan query, mengembalikan filter ke `Semua`, dan menutup kolom pencarian di dashboard.
- **Kategori tersembunyi** — hasil pencarian mengikuti mode “Tampilkan tersembunyi”; kategori tersembunyi tidak muncul secara default.

### Keputusan penting

- **Satu sumber hasil pencarian.** Dashboard dan detail kategori memakai fungsi domain yang sama, sehingga aturan pencocokan dan filter tidak menyimpang.
- **Debounce berada di widget, bukan controller.** Controller tetap menjadi sumber kebenaran query yang sudah diterapkan, sementara widget mengelola isi kolom teks dan timer. Ini mencegah ketikan hilang saat rebuild karena increment atau penyimpanan.
- **Detail kategori selalu dibuka tanpa filter.** Membuka kategori dari hasil pencarian membersihkan query/filter terlebih dahulu agar seluruh tugas kategori terlihat.
- **Empty state menghapus keduanya.** Pengguna tidak perlu menebak apakah yang kosong disebabkan query atau filter.
- **Label filter tidak bertabrakan dengan badge tugas.** Chip memakai “Tugas aktif”/“Tugas nonaktif”, sedangkan badge baris tetap “Aktif”/“Nonaktif”.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **153 test lulus**.
- Test baru `presentation/search_filter_test.dart` (10 widget test):
  - pencarian tugas lintas kategori dan pengelompokan per kategori;
  - pencarian nama kategori dengan huruf kecil dan badge nonaktif;
  - hasil baru muncul setelah debounce 250 ms;
  - filter aktif, nonaktif, dan punya target hari ini;
  - kombinasi pencarian + filter;
  - empty state beserta aksi hapus pencarian/filter;
  - tombol hapus di kolom pencarian;
  - pencarian, filter, dan empty state di halaman detail kategori.
- Test lama yang terdampak tata letak dashboard tetap lulus setelah kolom pencarian dibuat dapat dibuka/tutup.

### Catatan review

- Tidak ada I/O di dalam `build`; pencarian dan filter hanya bekerja pada data yang sudah dimuat di state.
- Pencarian tetap memakai data in-memory sehingga tidak menambah pembacaan file.
- Increment dari hasil pencarian memakai alur SnackBar Undo yang sama dengan dashboard dan detail kategori.
- Shortcut keyboard desktop untuk membuka pencarian tetap menjadi cakupan tiket 11.

### Tindak lanjut

- Reorder, pindah kategori, dan aksi massal dikerjakan pada tiket 10.
- Shortcut keyboard, layout dua panel desktop, dan audit aksesibilitas menyeluruh dikerjakan pada tiket 11.
