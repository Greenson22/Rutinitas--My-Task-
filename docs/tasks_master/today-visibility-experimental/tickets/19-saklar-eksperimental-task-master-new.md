# 19: Saklar eksperimental Task Master New dan satu penulis

**What to build:** `task_master_new` diaktifkan lewat saklar runtime di Settings → Fitur Eksperimental, dengan default mati sehingga modul lama dipakai. Saat saklar hidup, modul baru menjadi satu-satunya penulis `my_tasks.json`; saat mati, modul lama yang menulis. Pergantian modul tidak boleh menghilangkan riwayat dan tidak boleh membuat dua modul menulis bersamaan.

**Blocked by:** 18 — Visibilitas Hari Ini per tugas (field baru harus sudah tersimpan sebelum penulis berganti).

**Status:** ready-for-agent

- [ ] `taskMasterUseNewModule` tidak lagi konstanta compile-time; nilainya dibaca dari SharedPreferences `task_master_use_new_module` (default `false`).
- [ ] Status “modul lama boleh menulis” diturunkan dari preferensi yang sama, bukan dari konstanta atau salinan statis.
- [ ] `TaskMasterEntry` membaca preferensi saat dibangun, menampilkan indikator loading ringan, dan meng-cache hasilnya selama proses aplikasi berjalan agar navigasi berulang tidak berkedip.
- [ ] Saat saklar mati: modul lama menjadi penulis; modul baru tidak menulis file.
- [ ] Saat saklar hidup: modul baru menjadi penulis; seluruh jalur tulis modul lama ditolak, termasuk reset file, penyimpanan kategori, increment, penulisan Jurnal, dan editor JSON mentah.
- [ ] Guard berada di lapisan logika dan membaca preferensi pada saat operasi, bukan hanya menyembunyikan tombol.
- [ ] Guard tetap berlaku saat file gagal dibaca; tidak ada modul yang menulis setengah jalan.
- [ ] Settings → Fitur Eksperimental memiliki item **Task Master New** dengan ikon dan warna section yang sama.
- [ ] Mengaktifkan memunculkan dialog konfirmasi berisi ringkasan fitur dan catatan eksperimental.
- [ ] Menonaktifkan memunculkan dialog berbeda yang menyebut: riwayat baru ada di file v2, modul lama dapat membaca tetapi tidak menampilkan, dan detail tertentu bisa tidak sinkron bila diubah dari modul lama.
- [ ] Preferensi ditulis segera saat switch diubah, bukan saat tombol Simpan ditekan.
- [ ] Setelah salah satu alur selesai, muncul pemberitahuan bahwa restart diperlukan; dialog Settings tetap dapat ditutup seperti biasa.
- [ ] File terenkripsi tetap terbaca dan dapat ditulis setelah berganti modul.
- [ ] `docs/tasks_master/ROLLBACK.md` diperbarui: rollback lewat Settings, bukan build ulang, beserta status penulis dan langkah verifikasi.
- [ ] `docs/tasks_master/PARITY_QA.md` mendapat skenario ganti modul.
- [ ] Unit test pembacaan preferensi dan penurunan status penulis.
- [ ] Widget test: fresh install memakai modul lama, saklar hidup memakai modul baru, dialog konfirmasi aktif/nonaktif, preferensi tersimpan, notice restart tampil.
- [ ] Test regresi “satu penulis”: tidak ada dua modul menulis file pada satu waktu, termasuk saat file gagal dibaca.
- [ ] `flutter analyze` tidak memunculkan issue baru dan seluruh test lulus.

---

## Catatan implementasi

_(diisi setelah tiket dikerjakan)_
