# 08: Dashboard “Hari Ini” dan ringkasan

**What to build:** Pengguna melihat dashboard yang langsung menjawab apa yang perlu dikerjakan hari ini: empat kartu ringkasan, daftar tugas yang punya target atau aktivitas hari ini, dan daftar kategori. Pengguna dapat melakukan increment langsung dari dashboard. Empty state mengarahkan pengguna baru untuk membuat kategori pertama.

**Blocked by:** 04 — Kelola tugas, jenis tugas, dan target; 05 — Increment satu klik dan undo lokal; 06 — Integrasi Jurnal saat increment dan undo; 07 — Riwayat harian dan streak

**Status:** done

- [x] Dashboard menampilkan jumlah kategori aktif, total tugas aktif, target selesai hari ini, dan durasi Jurnal hari ini.
- [x] Daftar “Hari Ini” menampilkan tugas yang punya target harian atau aktivitas hari ini.
- [x] Setiap baris “Hari Ini” menampilkan nama, kategori, progres harian, tombol increment, dan status target.
- [x] Increment dari dashboard memakai alur yang sama dengan increment di halaman kategori.
- [x] Daftar kategori menampilkan ikon, nama, jumlah tugas aktif, dan ringkasan progres hari ini.
- [x] Kategori tersembunyi tidak tampil kecuali mode “Tampilkan tersembunyi” aktif.
- [x] Empty state “belum ada kategori” dan “belum ada tugas hari ini” tampil sesuai konteks.
- [x] Ringkasan akurat untuk tugas aktif, target tercapai, dan durasi Jurnal.
- [x] Widget test dashboard untuk loading, ready, empty, dan increment lulus.

## Catatan implementasi

**Tanggal:** 15 November 2026

**Durasi build agent:** ±16 menit (16:54–17:10 WITA) untuk implementasi, perbaikan widget test, `flutter analyze`, dan `flutter test` penuh.

### Ringkasan

Dashboard Task Master New sekarang langsung menjawab apa yang perlu dikerjakan hari ini. Empat kartu ringkasan berada di atas, diikuti daftar “Hari Ini” yang memuat tugas aktif dengan target harian atau aktivitas hari ini, lalu daftar kategori ringkas. Increment dari dashboard dan halaman detail kategori memakai satu jalur yang sama, termasuk SnackBar Undo 5 detik.

### Perubahan utama

- **Domain** — `domain/operations/dashboard_summary.dart` menyediakan aturan murni untuk daftar “Hari Ini”, status target, jumlah target tercapai, dan ringkasan per kategori. Kategori tersembunyi dikecualikan kecuali mode tampilkan tersembunyi aktif.
- **Durasi Jurnal** — `JournalLinkState` mendapat `todayMinutes`. `FileJournalGateway` menghitung total `durasi_menit` entri hari ini dari log bulanan, master lama, maupun template + log. Nilai ini juga diperbarui optimistis saat increment/undo berhasil agar kartu ringkasan tetap akurat.
- **Controller/state** — getter `journalTodayMinutes` ditambahkan. `_adjustJournalTodayMinutes` menyesuaikan durasi Jurnal setelah penambahan atau pengurangan berhasil; kegagalan rollback Jurnal tidak mengubah data Task Master.
- **Alur increment bersama** — `presentation/increment_flow.dart` menjadi satu-satunya jalur increment + SnackBar Undo. Dashboard dan halaman detail kategori memanggil fungsi yang sama.
- **Widget dashboard** — `DashboardSummaryCards` (empat kartu), `TodayTaskTile` (nama, kategori, progres harian, status target, badge Jurnal/streak, tombol increment dan riwayat), serta `CategorySummaryCard` (ikon, nama, tugas aktif, progres target hari ini, aksi kelola).
- **Empty state** — `TaskMasterEmptyView` mendapat CTA “Buat kategori pertama”. `EmptyTodayTasksView` tampil saat kategori ada tetapi belum ada tugas hari ini. `HiddenCategoriesView` tampil ketika semua kategori disembunyikan.
- **Mode tersembunyi** — tombol “Tampilkan tersembunyi” di header kategori hanya berlaku di layar dashboard dan tidak mengubah angka ringkasan aktif.
- **Test** — widget test dashboard baru mencakup loading, ready, empty kategori, empty tugas hari ini, mode tersembunyi, dan increment + Undo. Contract test Jurnal menambah verifikasi total durasi hari ini.

### Keputusan penting

- **Ringkasan selalu mengabaikan kategori tersembunyi.** Mode “Tampilkan tersembunyi” hanya memengaruhi daftar yang ditampilkan, bukan definisi kategori/tugas aktif.
- **Target tercapai dihitung dari tugas yang punya target.** Tugas dengan target harian mengikuti target harian; tugas `Progress` tanpa target harian dianggap selesai saat total mencapai target total; `Counter` tanpa target tidak dihitung.
- **Dashboard dan detail kategori berbagi alur increment.** Ekstraksi ke `increment_flow.dart` mencegah pesan, durasi SnackBar, dan perilaku Undo menyimpang.
- **Durasi Jurnal dioptimalkan secara lokal.** Setelah gateway berhasil menambah/mengurangi durasi, state langsung disesuaikan tanpa menunggu muat ulang file.
- **Empty state tetap ringan.** “Belum ada tugas hari ini” adalah kartu kecil di dalam dashboard, bukan halaman kosong, agar dashboard tidak terasa rusak.

### Pengujian

- `dart format lib/features/task_master_new test/features/task_master_new`
- `flutter analyze lib/features/task_master_new test/features/task_master_new` — tidak ada isu.
- `flutter test` — **143 test lulus**.
- Test baru:
  - `presentation/dashboard_test.dart` — loading, ringkasan empat kartu, daftar “Hari Ini”, kategori ringkas, empty kategori, empty tugas hari ini, mode tersembunyi, dan increment + Undo.
  - `data/journal_gateway_contract_test.dart` — total durasi Jurnal hari ini naik setelah increment.
- Test lama yang terdampak struktur dashboard disesuaikan: helper membuka detail kini menggulir ke kartu kategori, dan test sembunyikan kategori memakai mode “Tampilkan tersembunyi”.

### Catatan review

- Increment dashboard tidak memakai dialog konfirmasi dan tetap memakai jendela anti-double-tap dari controller.
- Kategori tersembunyi tidak muncul di daftar maupun ringkasan, tetapi tetap dapat dikelola lewat mode tersembunyi.
- Durasi Jurnal fallback 30 menit dan perilaku rollback best-effort tetap mengikuti tiket 06.
- Tidak ada I/O di dalam `build`; semua pembacaan Jurnal tetap melalui gateway dan state controller.

### Tindak lanjut

- Filter dan pencarian dashboard/kategori dikerjakan pada tiket 09.
- Reorder, pindah kategori, dan aksi massal dikerjakan pada tiket 10.
- Layout adaptif desktop dua panel dan audit aksesibilitas menyeluruh dikerjakan pada tiket 11.
