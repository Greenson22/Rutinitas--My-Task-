# 17: Visibilitas Hari Ini per tugas

**What to build:** Setiap tugas memiliki pengaturan **Tampil di Hari Ini** bertipe tri-state (`auto`, `always`, `never`). Daftar Hari Ini menghormati pengaturan ini tanpa mengubah perilaku default pengguna lama. Pengaturan dapat diubah dari form tugas, menu baris, dan aksi massal.

**Blocked by:** Tidak ada. Mengacu pada `docs/tasks_master/today-visibility-experimental/PRD.md` dan `ADR-0001-tri-state-today-visibility.md`.

**Status:** ready-for-agent

- [ ] `TodayVisibility` enum dengan `auto` sebagai default dan parser yang aman untuk nilai tidak dikenal.
- [ ] `Task.todayVisibility` ditambahkan, termasuk `copyWith` dan kesetaraan entity.
- [ ] Mapper membaca `todayVisibility`, fallback ke `showInToday` (`true` → `always`, `false` → `never`), lalu `auto`.
- [ ] Mapper menulis `todayVisibility` dan cermin `showInToday` untuk `always`/`never`; `auto` tidak menulis cermin.
- [ ] `collectTodayTasks` menerapkan aturan: `never` selalu dilewati, `always` selalu disertakan (selama aktif dan kategori tidak tersembunyi), `auto` memakai aturan lama.
- [ ] Tugas nonaktif dan kategori tersembunyi tetap dikecualikan pada semua nilai.
- [ ] Ringkasan dashboard tidak berubah karena perubahan visibilitas.
- [ ] Form tugas memiliki kontrol tiga opsi “Tampil di Hari Ini”.
- [ ] Menu baris di daftar Hari Ini dan detail kategori memiliki aksi tiga opsi.
- [ ] Aksi massal “Visibilitas Hari Ini” menerapkan nilai yang dipilih ke semua tugas terpilih.
- [ ] Perubahan visibilitas langsung terlihat tanpa reload file.
- [ ] Empty state Hari Ini menjelaskan cara memunculkan tugas.
- [ ] Unit test matriks visibilitas × target/aktivitas × aktif/nonaktif × kategori tersembunyi.
- [ ] Widget test form, menu baris, dan aksi massal.
- [ ] Visibilitas bertahan setelah restart dan export/import Data Center.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
