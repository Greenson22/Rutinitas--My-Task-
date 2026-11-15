# 10: Reorder, pindah tugas, dan aksi massal

**What to build:** Pengguna dapat mengubah urutan kategori dan tugas, memindahkan tugas ke kategori lain tanpa kehilangan `id`, serta melakukan aksi massal untuk mengaktifkan, menonaktifkan, atau menghapus banyak tugas sekaligus. Semua perubahan bertahan setelah reload.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target

**Status:** done

- [x] Kategori dapat diurutkan ulang dan urutan tersimpan setelah reload.
- [x] Tugas dapat diurutkan ulang di dalam kategori dan urutan tersimpan setelah reload.
- [x] Reorder memakai drag handle; tombol panah tetap tersedia sebagai fallback aksesibilitas.
- [x] Tugas dapat dipindahkan ke kategori lain dan tetap mempertahankan `id`.
- [x] Long press masuk ke mode seleksi tugas.
- [x] Aksi massal aktif, nonaktif, dan hapus tersedia dengan konfirmasi untuk aksi destruktif.
- [x] Mode seleksi keluar dengan jelas setelah aksi selesai.
- [x] Widget test reorder, pindah kategori, dan aksi massal lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

**Durasi build agent:** ±35 menit (18:28–19:03 WITA) untuk implementasi domain/data/presentasi, penulisan widget dan contract test baru, `dart format`, `flutter analyze`, dan `flutter test` penuh.

### Ringkasan

Pengguna sekarang dapat mengurutkan kategori dari dashboard dan tugas dari halaman detail kategori. Reorder memakai drag handle, dengan tombol panah sebagai fallback aksesibilitas dan keyboard. Tugas dapat dipindahkan ke kategori lain tanpa kehilangan `id`, total, atau riwayat. Long press pada tugas membuka mode seleksi dengan aksi massal aktif, nonaktif, dan hapus; hapus massal selalu meminta konfirmasi. Semua perubahan langsung disimpan dan bertahan setelah reload.

### Perubahan utama

- **Domain** — `reorderCategoryIn`, `reorderTaskIn`, `moveTaskToCategoryIn`, `setTasksActiveIn`, dan `deleteTasksFrom` ditambahkan. Semua operasi menormalkan `sortOrder` berurutan agar urutan stabil setelah reload. Memindahkan tugas memperbarui `categoryId` dan `updatedAt` tanpa menyentuh `id`, `totalCount`, atau `history`. Memindahkan ke kategori yang sama ditolak secara eksplisit.
- **Kontrak repository** — `TaskRepository` mendapat `reorderCategory`, `reorderTask`, `moveTask`, `setTasksActive`, dan `deleteTasks`. Implementasi file dan fake test memakai operasi domain yang sama, sehingga perilaku keduanya tidak menyimpang.
- **Controller** — lima method baru membungkus operasi repository lewat `_runDataAction`, termasuk banner retry saat penyimpanan gagal. Mode seleksi dan mode urutkan tetap berada di layar, bukan di controller, karena keduanya state UI sementara.
- **Reorder kategori** — tombol `Urutkan kategori` di AppBar dashboard membuka `CategoryReorderSheet`. Lembar ini menampilkan seluruh kategori (termasuk yang tersembunyi), drag handle, dan tombol naik/turun. Urutan disimpan lewat `reorderCategory` dan langsung tercermin di dashboard.
- **Reorder tugas** — halaman detail kategori mendapat tombol `Urutkan tugas` yang mengaktifkan `ReorderableListView` di dalam daftar tugas. Setiap baris menampilkan drag handle dan tombol panah; tombol panah di ujung daftar nonaktif secara visual. Mode urutkan menonaktifkan increment, menu, pencarian/filter sementara agar hasil drag tidak ambigu.
- **Pindah kategori** — menu tugas mendapat aksi `Pindahkan` yang membuka `MoveTaskDialog`. Kategori saat ini tidak ditawarkan sebagai tujuan. Setelah berhasil, SnackBar menyebutkan kategori tujuan.
- **Mode seleksi dan aksi massal** — long press pada baris tugas mengaktifkan mode seleksi. AppBar berubah menjadi jumlah tugas terpilih, tombol tutup, aktifkan, nonaktifkan, dan hapus. Ketukan pada tugas menambah/menghapus pilihan. Aksi massal yang berhasil mengosongkan pilihan dan menutup mode seleksi; kegagalan tetap menampilkan banner retry dan mempertahankan pilihan.
- **Konfirmasi destruktif** — `BulkDeleteTasksDialog` menyebut jumlah tugas dan memperingatkan bahwa hitungan serta riwayat ikut terhapus. Penghapusan baru berjalan setelah konfirmasi.
- **Test** — widget test baru, contract test repository baru, dan fake repository diperluas untuk lima operasi baru.

### Keputusan penting

- **`sortOrder` selalu dinormalkan.** Setelah reorder, seluruh item di kategori/daftar kategori dinomori `0..n-1`, bukan hanya item yang dipindah. Ini mencegah celah dan duplikat `sortOrder` yang dapat membuat urutan berubah setelah reload.
- **Drag handle eksplisit.** `buildDefaultDragHandles: false` dipakai agar handle tidak bertabrakan dengan tombol increment, riwayat, dan menu. Tombol panah tetap tampil sebagai jalur alternatif yang dapat dijangkau pembaca layar dan keyboard.
- **Mode urutkan adalah mode terpisah.** Pencarian/filter dibersihkan saat masuk mode urutkan karena mengurutkan subset hasil filter akan membingungkan. Mode seleksi dan mode urutkan saling eksklusif.
- **Kategori tersembunyi tetap bisa diurutkan.** Sheet urutkan menampilkan semua kategori, bukan hanya yang terlihat, sehingga pengguna dapat mengatur posisi kategori tersembunyi sebelum menampilkannya kembali.
- **Seleksi membersihkan id yang hilang.** Bila tugas terpilih dihapus atau dipindahkan, id tersebut dibuang dari pilihan pada build berikutnya agar mode seleksi tidak menunjuk data yang sudah tidak ada.
- **Aksi massal memakai satu penyimpanan.** Aktif/nonaktif dan hapus massal dijalankan sebagai satu transformasi data, bukan loop aksi per tugas, sehingga hanya ada satu penulisan file dan tidak ada keadaan setengah jadi.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **168 test lulus**.
- Test baru:
  - `presentation/reorder_bulk_actions_test.dart` (11 widget test): reorder tugas lewat tombol panah dan drag handle, keluar mode urutkan, pindah kategori dengan `id`/total/riwayat tetap utuh dan bertahan setelah reload, kategori saat ini tidak menjadi tujuan, long press + nonaktif massal, aktif massal, hapus massal dengan konfirmasi, keluar seleksi lewat tombol tutup, reorder kategori lewat tombol panah dan drag handle, serta urutan kategori yang bertahan setelah reload.
  - `data/task_repository_reorder_contract_test.dart` (4 contract test): urutan kategori, urutan tugas dan `sortOrder`, pindah kategori dengan data utuh, serta aktif/hapus massal bertahan setelah repository dibuka ulang.
- Test lama tetap lulus setelah `TaskTile` mendapat wrapper `Material`/`InkWell`, mode seleksi, drag handle, dan tombol panah.

### Catatan review

- Tidak ada I/O di dalam `build`; reorder dan aksi massal tetap melalui controller/repository.
- Aksi massal tidak memakai dialog konfirmasi untuk aktif/nonaktif karena tidak destruktif; hanya hapus massal yang dikonfirmasi.
- Urutan yang disimpan adalah data domain (`sortOrder`), bukan posisi widget, sehingga konsisten antara dashboard, halaman detail, pencarian, dan setelah reload.
- Kategori yang sedang difilter atau dicari tidak dapat masuk mode urutkan sampai pencarian dibersihkan, sesuai keputusan mode terpisah.
- Penghapusan massal dan pemindahan tugas tidak mengubah relasi Jurnal karena relasi tetap dimiliki Jurnal lewat `linkedTaskIds`.

### Tindak lanjut

- Layout adaptif dua panel desktop, shortcut keyboard lanjutan, dan audit aksesibilitas menyeluruh dikerjakan pada tiket 11.
- Recovery file korup, editor JSON Advanced, dan pengaturan enkripsi dikerjakan pada tiket 12.
- Kompatibilitas ekspor/impor Data Center dikerjakan pada tiket 13.
