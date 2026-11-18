# 18: Visibilitas Hari Ini per tugas

**What to build:** Setiap tugas memiliki pengaturan **Tampil di Hari Ini** bertipe tri-state (`auto`, `always`, `never`). Daftar Hari Ini menghormati pengaturan ini tanpa mengubah perilaku default pengguna lama. Pengaturan dapat diubah dari form tugas, menu baris, dan aksi massal, lalu bertahan setelah restart dan export/import.

**Blocked by:** 17 — Passthrough field tak dikenal di model legacy (field baru harus aman saat file ditulis modul lama).

**Status:** ready-for-agent

- [ ] `TodayVisibility` enum dengan `auto` sebagai default dan parser aman untuk nilai tidak dikenal; nilai rusak menjadi `auto` dan dicatat lewat debug, bukan error.
- [ ] `Task.todayVisibility` ditambahkan, termasuk `copyWith` dan kesetaraan entity.
- [ ] Mapper membaca `todayVisibility`, fallback ke `showInToday` (`true` → `always`, `false` → `never`), lalu `auto`.
- [ ] Mapper menulis `todayVisibility` dan cermin `showInToday` hanya untuk `always` dan `never`; `auto` tidak menulis cermin.
- [ ] `collectTodayTasks` menerapkan aturan: `never` selalu dilewati, `always` selalu disertakan selama tugas aktif dan kategori tidak tersembunyi, `auto` memakai aturan lama (target harian, target total untuk progress, atau ada hitungan hari ini).
- [ ] Tugas nonaktif dan kategori tersembunyi tetap dikecualikan pada semua nilai.
- [ ] Ringkasan dashboard tidak berubah karena perubahan visibilitas; tugas `always` tanpa target menyumbang nol pada hitungan target tercapai.
- [ ] Urutan hasil tetap mengikuti `sortOrder` kategori lalu tugas.
- [ ] Form tugas memiliki kontrol tiga opsi “Tampil di Hari Ini” dengan teks bantuan per opsi dan default `Otomatis` untuk tugas baru.
- [ ] Menu baris di daftar Hari Ini dan detail kategori memiliki submenu tiga opsi dengan tanda centang pada nilai aktif.
- [ ] Aksi massal “Visibilitas Hari Ini” menerapkan nilai terpilih ke semua tugas terpilih tanpa menyentuh status aktif.
- [ ] Perubahan visibilitas langsung terlihat tanpa reload file; jumlah tugas di header Hari Ini ikut berubah.
- [ ] Tugas `always` tanpa target tetap menampilkan status “Tanpa target” dan tombol increment.
- [ ] Empty state Hari Ini menjelaskan cara memunculkan tugas lewat pengaturan ini.
- [ ] Visibilitas bertahan setelah restart dan setelah export/import Data Center.
- [ ] Unit test matriks: 3 visibilitas × (target harian, tanpa target, ada aktivitas, progress dengan target total) × aktif/nonaktif × kategori terlihat/tersembunyi.
- [ ] Widget test: form menyimpan tiga opsi, menu baris mengubah dan daftar langsung bereaksi, aksi massal, ringkasan tetap sama, empty state menampilkan bantuan.
- [ ] Gate performa: dashboard 1.000 tugas tetap di bawah ambang 500 ms.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
